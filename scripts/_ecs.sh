#!/bin/bash

function _ecs_help() {
    echo
    echo "uhd ecs <command> [options]"
    echo
    echo "commands:"
    echo "  help                           - this help screen"
    echo 
    echo "  restart-services               - restart all the ecs services"
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
