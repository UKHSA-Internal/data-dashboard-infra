#!/bin/bash

function _data_help() {
    echo
    echo "uhd data <command> [options]"
    echo
    echo "commands:"
    echo "  help           - this help screen"
    echo 
    echo "  upload [folder] - upload files to the ingest s3 bucket"
    echo "  ingest          - ingest files from s3"
    echo

    return 0
}

function _data() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "upload") _data_upload $args ;;
        "ingest") _data_ingest  $args ;;

        *) _data_help ;;
    esac
}

function _data_upload() {
    local folder=$1

    if [[ -z ${folder} ]]; then
        echo "Folder is required" >&2
        return 1
    fi

    local bucket_id=$(_get_ingest_bucket_id)

    aws s3 cp $folder s3://$bucket_id/in/ --recursive
}

function _data_ingest() {
    local cluster_name=$(_get_ecs_cluster_name)

    echo Starting job....
    local taskArn=$(aws ecs run-task --cli-input-json "file://terraform/20-app/ecs-jobs/upload-files-from-s3.json" | jq -r ".tasks[0].taskArn")

    echo "Waiting for task $taskArn to start..."
    aws ecs wait tasks-running --cluster $cluster_name --tasks $taskArn

    local env=$(_get_env_name)
    local taskId=${taskArn##*/}

    aws logs tail "/aws/ecs/uhd-${env}-ingestion/api" --follow --log-stream-names "ecs/api/$taskId"
}

function _get_ingest_bucket_id() {
    local terraform_output_file=terraform/20-app/output.json

    local bucket_id=$(jq -r '.s3.value.ingest_bucket_id'  $terraform_output_file)

    echo $bucket_id
}