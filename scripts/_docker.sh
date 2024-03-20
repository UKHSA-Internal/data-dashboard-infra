#!/bin/bash

function _docker_help() {
    echo
    echo "uhd docker <command> [options]"
    echo
    echo "commands:"
    echo "  help                 - this help screen"
    echo
    echo "  build [repo]         - build a docker image for the specified repo"
    echo
    echo "  pull                 - pull the latest source images from the dev account"
    echo "  push                 - push images to your dev ECR"
    echo "  push <account> <env> - tag and push images"
    echo
    echo "  ecr:login            - login to ECR in the dev account"
    echo "  ecr:login <account>  - login to ECR in the specified account"
    echo

    return 0
}

function _docker() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "build") _docker_build $args ;;
        "pull") _docker_pull $args ;;
        "push") _docker_push $args ;;
        "ecr:login") _docker_ecr_login $args ;;

        *) _docker_help ;;
    esac
}

function _docker_build() {
    local repo=$1

    if [[ -z ${repo} ]]; then
        echo "Repo is required" >&2
        return 1
    fi

    local dev_account_id=$(_get_target_aws_account_id "dev")
    local env=$(_get_env_name)

    cd $root/../data-dashboard-$repo

    local ecr_repo_name=$repo
    [[ "$repo" == "frontend" ]] && ecr_repo_name=("front-end")

    echo "Building docker image for $repo"

    docker buildx build --platform linux/amd64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-${ecr_repo_name}:latest --push .
    
    cd $root
}

function _docker_pull() {
    src_account_id=$(_get_tools_account_id)
    
    src=("${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/api:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/ingestion:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/front-end:latest")

    echo $src | xargs -P10 -n1 docker pull
}

function _docker_push() {
    local account=$1
    local env=$2

    if [[ -z ${account} ]]; then
        echo "Account is required" >&2
        return 1
    fi

    if [[ -z ${env} ]]; then
        echo "Env is required" >&2
        return 1
    fi

    src_account_id=$(_get_tools_account_id)
    dest_account_id=$(_get_target_aws_account_id $account)
    
    src=("${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/api:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/ingestion:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/front-end:latest")

    dest=("${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-api:latest"
          "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion:latest"
          "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-front-end:latest")

    for ((i=1; i<=${#src[@]}; ++i)); do
        docker tag "${src[i]}" "${dest[i]}"
    done

    echo $dest | xargs -P10 -n1 docker push
}

function _docker_ecr_login() {
    local account=${1:-tools}

    echo "Logging into ECR in account $account"

    account_id=$(_get_tools_account_id)

    aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.eu-west-2.amazonaws.com"
}
