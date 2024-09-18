#!/bin/bash

function _ecs_help() {
    echo
    echo "uhd ecs <command> [options]"
    echo
    echo "commands:"
    echo "  help                           - this help screen"
    echo 
    echo "  restart-services               - *DEPRECATED restart all the ecs services"
    echo "  restart-services-v2            - restarts all the ecs services after deploying the most recent images"
    echo "  run <job name>                 - run the specified job"
    echo "  logs <env> <task id>           - tail logs for the specified task"
    echo "  ssh <task id> <container name> - ssh into a container"
    echo

    return 0
}

function _ecs() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "run") _ecs_run $args ;;
        "restart-services") _ecs_restart_services $args ;;
        "restart-services-v2") _ecs_restart_services_v2 $args ;;
        "logs") _ecs_logs $args ;;
        "ssh") _ecs_ssh $args ;;

        *) _ecs_help ;;
    esac
}

function _ecs_run() {
    local job=$1

    if [[ -z ${job} ]]; then
        echo "Job is required" >&2
        return 1
    fi

    echo Starting job....

    aws ecs run-task --cli-input-json "file://terraform/20-app/ecs-jobs/${job}.json" | jq ".tasks[0].taskArn"
}

function _ecs_logs() {
    local env=$1
    local task_id=$2

    if [[ -z ${env} ]]; then
        echo "Env is required" >&2
        return 1
    fi

    if [[ -z ${task_id} ]]; then
        echo "Task id is required" >&2
        return 1
    fi

   aws logs tail "/aws/ecs/uhd-${env}-api/api" --follow --log-stream-names "ecs/api/$task_id"
}

function _ecs_restart_services() {
    local terraform_output_file=terraform/20-app/output.json

    local cluster_name=$(jq -r '.ecs.value.cluster_name'  $terraform_output_file)
    local cms_admin_service_name=$(jq -r '.ecs.value.service_names.cms_admin'  $terraform_output_file)
    local private_api_service_name=$(jq -r '.ecs.value.service_names.private_api'  $terraform_output_file)
    local public_api_service_name=$(jq -r '.ecs.value.service_names.public_api'  $terraform_output_file)
    local feedback_api_service_name=$(jq -r '.ecs.value.service_names.feedback_api'  $terraform_output_file)
    local feature_flags_service_name=$(jq -r '.ecs.value.service_names.feature_flags'  $terraform_output_file)

    local front_end_service_name=$(jq -r '.ecs.value.service_names.front_end'  $terraform_output_file)

    echo "Restarting services..."

    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $cms_admin_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $private_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $public_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $feedback_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $feature_flags_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $front_end_service_name

    echo "Waiting for services to reach a steady state..."
    aws ecs wait services-stable \
        --cluster $cluster_name \
        --services \
         $cms_admin_service_name \
         $private_api_service_name \
         $public_api_service_name \
         $feedback_api_service_name \
         $feature_flags_service_name \
         $front_end_service_name
}

function _get_most_recent_back_end_image() {
    local back_end_ecr_url=$(jq -r '.ecr.value.repo_urls.back_end'  $terraform_output_file)
    echo "back_end_ecr_url"
    echo ${back_end_ecr_url}

    local back_end_ecr_name=$(jq -r '.ecr.value.repo_names.back_end'  $terraform_output_file)
    echo "back_end_ecr_name"
    echo ${back_end_ecr_name}
    echo

    most_recent_back_end_image_tag=$(uhd docker get-recent-tag $back_end_ecr_name)
    echo "${back_end_ecr_url}:${most_recent_back_end_image_tag}"
}

function _get_most_recent_front_end_image() {
    local front_end_ecr_url=$(jq -r '.ecr.value.repo_urls.front_end'  $terraform_output_file)
    echo "front_end_ecr_url"
    echo ${front_end_ecr_url}

    local front_end_ecr_name=$(jq -r '.ecr.value.repo_names.front_end'  $terraform_output_file)
    echo "front_end_ecr_name"
    echo ${front_end_ecr_name}
    echo

    most_recent_front_end_image_tag=$(uhd docker get-recent-tag $front_end_ecr_name)
    echo "${front_end_ecr_url}:${most_recent_front_end_image_tag}"
}

function _ecs_restart_services_v2() {
    local terraform_output_file=terraform/20-app/output.json
    local cluster_name=$(jq -r '.ecs.value.cluster_name'  $terraform_output_file)

    local cms_admin_service_name=$(jq -r '.ecs.value.service_names.cms_admin'  $terraform_output_file)
    local private_api_service_name=$(jq -r '.ecs.value.service_names.private_api'  $terraform_output_file)
    local public_api_service_name=$(jq -r '.ecs.value.service_names.public_api'  $terraform_output_file)
    local feedback_api_service_name=$(jq -r '.ecs.value.service_names.feedback_api'  $terraform_output_file)
    local front_end_service_name=$(jq -r '.ecs.value.service_names.front_end'  $terraform_output_file)
    local feature_flags_service_name=$(jq -r '.ecs.value.service_names.feature_flags'  $terraform_output_file)

    local cms_admin_task_definition_arn=$(jq -r '.ecs.value.task_definitions.cms_admin'  $terraform_output_file)
    local private_api_task_definition_arn=$(jq -r '.ecs.value.task_definitions.private_api'  $terraform_output_file)
    local public_api_task_definition_arn=$(jq -r '.ecs.value.task_definitions.public_api'  $terraform_output_file)
    local feedback_api_task_definition_arn=$(jq -r '.ecs.value.task_definitions.feedback_api'  $terraform_output_file)
    local front_end_task_definition_arn=$(jq -r '.ecs.value.task_definitions.front_end'  $terraform_output_file)

    back_end_image=$(_get_most_recent_back_end_image)
    echo "back_end_image = ${back_end_image}"
    echo "--"

    front_end_image=$(_get_most_recent_front_end_image)
    echo "front_end_image = ${front_end_image}"
    echo "--"

    echo "Updating services..."
    _ecs_register_new_image_for_service ${cms_admin_service_name} ${cms_admin_task_definition_arn} ${back_end_image}
    _ecs_register_new_image_for_service ${private_api_service_name} ${private_api_task_definition_arn} ${back_end_image}
    _ecs_register_new_image_for_service ${public_api_service_name} ${public_api_task_definition_arn} ${back_end_image}
    _ecs_register_new_image_for_service ${feedback_api_service_name} ${feedback_api_task_definition_arn} ${back_end_image}
    _ecs_register_new_image_for_service ${front_end_service_name} ${front_end_task_definition_arn} ${front_end_image}
    _ecs_force_new_deployment_for_service ${cluster_name} ${feature_flags_service_name}

    echo "Waiting for services to reach a steady state..."
    aws ecs wait services-stable \
      --cluster $cluster_name \
      --services \
        $cms_admin_service_name \
        $private_api_service_name \
        $public_api_service_name \
        $feedback_api_service_name \
        $front_end_service_name \
        $feature_flags_service_name
}

function _ecs_force_new_deployment_for_service() {
  local cluster_name=$1
  local service_name=$2

  aws ecs update-service \
    --force-new-deployment \
    --query service.serviceName \
    --cluster $cluster_name \
    --service $service_name
}

function _ecs_register_new_image_for_service() {
  local service_name=$1
  local task_definition_arn=$2
  local new_image_tag=$3
  echo "-------"
  echo "Updating service: ${service_name} for task definition arn: ${task_definition_arn} with image tag of: ${new_image_tag}"
  echo
  local cluster_name=$(jq -r '.ecs.value.cluster_name'  $terraform_output_file)

  original_task_definition=$(aws ecs describe-task-definition --task-definition ${task_definition_arn} --region eu-west-2)
  new_task_definition=$(echo ${original_task_definition} | jq --arg IMAGE ${new_image_tag} '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) |  del(.registeredAt)  | del(.registeredBy)')

  new_task_info=$(aws ecs register-task-definition --region eu-west-2 --cli-input-json ${new_task_definition})
  new_revision=$(echo ${new_task_info} | jq '.taskDefinition.revision')
  echo "new revision:"
  echo ${new_revision}

  new_task_definition_arn="${task_definition_arn}:${new_revision}"
  echo "new_task_definition_arn:"
  echo ${new_task_definition_arn}

  aws ecs update-service \
    --cluster ${cluster_name} \
    --service ${service_name} \
    --task-definition ${new_task_definition_arn} > /dev/null

  echo "${service_name}"
}

function _ecs_ssh() {
    local task_id=$1
    local container_name=$2

    if [[ -z ${task_id} ]]; then
        echo "Task id is required" >&2
        return 1
    fi

    if [[ -z ${container_name} ]]; then
        echo "Container name is required" >&2
        return 1
    fi

    local terraform_output_file=terraform/20-app/output.json

    local cluster_name=$(jq -r '.ecs.value.cluster_name'  $terraform_output_file)
    
    aws ecs execute-command \
    --cluster $cluster_name \
    --task $task_id \
    --container $container_name \
    --interactive \
    --command "/bin/sh"
}
