#!/bin/bash

function _ecs_help() {
    echo
    echo "uhd ecs <command> [options]"
    echo
    echo "commands:"
    echo "  help                 - this help screen"
    echo 
    echo "  restart-services     - restart all the ecs services"
    echo "  run <job name>       - run the specified job"
    echo "  logs <env> <task id> - tail logs for the specified task"

    return 0
}

function _ecs() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "run") _ecs_run $args ;;
        "restart-services") _ecs_restart_services $args ;;
        "logs") _ecs_logs $args ;;

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

    local front_end_service_name=$(jq -r '.ecs.value.service_names.front_end'  $terraform_output_file)

    echo "Restarting services..."

    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $cms_admin_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $private_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $public_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $feedback_api_service_name
    aws ecs update-service --force-new-deployment --query service.serviceName --cluster $cluster_name --service $front_end_service_name

    echo "Waiting for services to reach a steady state..."
    aws ecs wait services-stable \
        --cluster $cluster_name \
        --services \
         $cms_admin_service_name \
         $private_api_service_name \
         $public_api_service_name \
         $feedback_api_service_name \
         $front_end_service_name

    _deploy_latest_ingestion_image_to_lambda
}

function _deploy_latest_ingestion_image_to_lambda() {
    local ingestion_image_uri=$(_get_ingestion_image_uri)
    local ingestion_lambda_arn=$(_get_ingestion_lambda_arn)

    echo "Deploying latest image to ingestion lambda..."
    aws lambda update-function-code \
        --function-name $ingestion_lambda_arn \
        --image-uri $ingestion_image_uri \
        --no-cli-pager

    echo "Waiting for lambda to update..."
    aws lambda wait function-updated-v2 --function-name $ingestion_lambda_arn
}

function _get_ingestion_image_uri() {
    local terraform_output_file=terraform/20-app/output.json
    local ingestion_image_uri=$(jq -r '.ecr.value.ingestion_image_uri'  $terraform_output_file)
    echo $ingestion_image_uri
}

function _get_ingestion_lambda_arn() {
    local terraform_output_file=terraform/20-app/output.json
    local ingestion_lambda_arn=$(jq -r '.lambda.value.ingestion_lambda_arn'  $terraform_output_file)
    echo $ingestion_lambda_arn
}
