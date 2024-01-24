#!/bin/bash

function _cache_help() {
    echo
    echo "uhd cache <command> [options]"
    echo
    echo "commands:"
    echo "  help                 - this help screen"
    echo 
    echo "  flush-redis      - flush and re-fill the redis (private api) cache"
    echo "  flush-front-end  - flush the front end (cloud front) cache"
    echo "  flush-public-api - flush the public api (cloud front) cache"
    echo
    echo "  fill-front-end   - fill the front end (cloud front) cache"
    echo "  fill-public-api  - fill the public api (cloud front) cache"
    echo
    echo "  flush            - flush and refill all the caches"

    return 0
}

function _cache() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "flush-redis") _cache_flush_redis $args ;;
        "flush-front-end") _cache_flush_front_end $args ;;
        "flush-public-api") _cache_flush_public_api $args ;;
        "fill-front-end") _cache_fill_front_end $args ;;
        "fill-public-api") _cache_fill_public_api $args ;;
        "flush") _cache_flush $args ;;
        
        *) _cache_help ;;
    esac
}

function _cache_flush() {
    echo "Flushing the redis cache..."
    uhd cache flush-redis --wait

    echo "Flushing the front end cloud front cache..." 
    uhd cache flush-front-end

    echo "Flushing the public api cloud front cache..." 
    uhd cache flush-public-api
    
    echo "Filling the front end cloud front cache..." 
    uhd cache fill-front-end --wait

    echo "Filling the public api cloud front cache..." 
    uhd cache fill-public-api --wait
}

function _cache_flush_redis() {
    local cluster_name=$(_get_ecs_cluster_name)
    local waitArg=$1

    echo Starting job....
    local taskArn=$(aws ecs run-task --cli-input-json "file://terraform/20-app/ecs-jobs/hydrate-private-api-cache.json" | jq -r ".tasks[0].taskArn")

    if [[ $waitArg = "--wait" ]]; then
        echo "Waiting for task $taskArn to finish..."
        aws ecs wait tasks-stopped --cluster $cluster_name --tasks $taskArn
    else
        echo "Waiting for task $taskArn to start..."
        aws ecs wait tasks-running --cluster $cluster_name --tasks $taskArn

        local env=$(_get_env_name)
        local taskId=${taskArn##*/}

        aws logs tail "/aws/ecs/uhd-${env}-utility-worker/api" --follow --log-stream-names "ecs/api/$taskId"
    fi
}

function _cache_fill_front_end() {
    local cluster_name=$(_get_ecs_cluster_name)
    local waitArg=$1

    echo Starting job....
    local taskArn=$(aws ecs run-task --cli-input-json "file://terraform/20-app/ecs-jobs/hydrate-frontend-cache.json" | jq -r ".tasks[0].taskArn")

    if [[ $waitArg = "--wait" ]]; then
        echo "Waiting for task $taskArn to finish..."
        aws ecs wait tasks-stopped --cluster $cluster_name --tasks $taskArn
    else
        echo "Waiting for task $taskArn to start..."
        aws ecs wait tasks-running --cluster $cluster_name --tasks $taskArn

        local env=$(_get_env_name)
        local taskId=${taskArn##*/}

        aws logs tail "/aws/ecs/uhd-${env}-private-api/api" --follow --log-stream-names "ecs/api/$taskId"
    fi
}

function _cache_fill_public_api() {
    local cluster_name=$(_get_ecs_cluster_name)
    local waitArg=$1

    echo Starting job....
    local taskArn=$(aws ecs run-task --cli-input-json "file://terraform/20-app/ecs-jobs/hydrate-public-api-cache.json" | jq -r ".tasks[0].taskArn")

    if [[ $waitArg = "--wait" ]]; then
        echo "Waiting for task $taskArn to finish..."
        aws ecs wait tasks-stopped --cluster $cluster_name --tasks $taskArn
    else
        echo "Waiting for task $taskArn to start..."
        aws ecs wait tasks-running --cluster $cluster_name --tasks $taskArn

        local env=$(_get_env_name)
        local taskId=${taskArn##*/}

        aws logs tail "/aws/ecs/uhd-${env}-public-api/api" --follow --log-stream-names "ecs/api/$taskId"
    fi
}

function _cache_flush_public_api() {
    _flush_cloud_front "public_api"
}

function _cache_flush_front_end() {
    _flush_cloud_front "front_end"
}

function _flush_cloud_front() {
    local distribution=$1
    local distribution_id=$(_get_distribution_id $distribution)
    
    echo Creating invalidation....
    local result=$(aws cloudfront create-invalidation --distribution-id $distribution_id --paths "/*")
    local invalidation_id=$(echo "$result" | jq -r '.Invalidation.Id')
    
    echo "Waiting for cloud front cache to flush..."
    aws cloudfront wait invalidation-completed --distribution-id $distribution_id --id $invalidation_id
}

function _get_ecs_cluster_name() {
    local terraform_output_file=terraform/20-app/output.json
    local cluster_name=$(jq -r '.ecs.value.cluster_name'  $terraform_output_file)

    echo $cluster_name
}

function _get_env_name() {
    local terraform_output_file=terraform/20-app/output.json
    local env_name=$(jq -r '.environment.value'  $terraform_output_file)

    echo $env_name
}

function _get_distribution_id() {
    local distribution=$1
    local terraform_output_file=terraform/20-app/output.json
    local distribution_id=$(jq -r --arg distribution "$distribution" '.cloud_front.value[$distribution]' $terraform_output_file)

    echo $distribution_id
}
