#!/bin/bash

function _lambda_help() {
    echo
    echo "uhd lambda <command> [options]"
    echo
    echo "commands:"
    echo "  help                      - this help screen"
    echo 
    echo "  redeploy-functions        - redeploy all the lambda functions"
    echo "  logs <env> <lambda name>  - tail logs for the specified lambda"

    return 0
}

function _lambda() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "redeploy-functions") _lambda_redeploy_functions $args ;;
        "logs") _lambda_logs $args ;;

        *) _lambda_help ;;
    esac
}

function _lambda_logs() {
    local env=$1
    local lambda_name=$2

    if [[ -z ${env} ]]; then
        echo "Env is required" >&2
        return 1
    fi

    if [[ -z ${lambda_name} ]]; then
        echo "Lambda name is required" >&2
        return 1
    fi

   aws logs tail "/aws/lambda/uhd-${env}-${lambda_name}" --follow
}

function _lambda_redeploy_functions() {
    local ingestion_image_uri=$(_get_ingestion_image_uri)
    local ingestion_lambda_arn=$(_get_ingestion_lambda_arn)

    echo "Deploying latest image to ingestion lambda..."
    aws lambda update-function-code \
        --function-name $ingestion_lambda_arn \
        --image-uri $ingestion_image_uri \
        --no-cli-pager \
        --no-cli-auto-prompt \
        > /dev/null

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
