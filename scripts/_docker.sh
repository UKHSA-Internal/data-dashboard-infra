#!/bin/bash

function _docker_help() {
    echo
    echo "uhd docker <command> [options]"
    echo
    echo "commands:"
    echo "  help                   - this help screen"
    echo
    echo "  build [repo]           - build a docker image for the specified repo"
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

    docker buildx build --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-${ecr_repo_name}:latest-graviton --push .
    
    if [[ "$repo" == "api" ]]; then
        echo "building docker image for ingestion lambda"
        docker buildx build -f Dockerfile-ingestion --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion:latest --push .
    fi

    cd $root
}

function _docker_pull() {
    src_account_id=$(_get_tools_account_id)
    
    src=("${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/api:latest-graviton"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/ingestion:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/front-end:latest-graviton")

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
    
    src=("${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/api:latest-graviton"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/ingestion:latest"
         "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/data-dashboard/front-end:latest-graviton")

    dest=("${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-api:latest-graviton"
          "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion:latest"
          "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-front-end:latest-graviton")

    for ((i=1; i<=${#src[@]}; ++i)); do
        docker tag "${src[i]}" "${dest[i]}"
    done

    _docker_ecr_login "dev"

    echo $dest | xargs -P10 -n1 docker push
}

function _docker_ecr_login() {
    local account=${1:-tools}

    echo "Logging into ECR in account $account"

    if [[ $account = "tools" ]]; then
      account_id=$(_get_tools_account_id)
    else
      account_id=$(_get_target_aws_account_id $account)
    fi

    aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.eu-west-2.amazonaws.com"
}

function _docker_get_most_recent_front_end_image_tag() {
    src_account_id=$(_get_tools_account_id)
    echo $(_docker_get_most_recent_image_tag_from_repo ukhsa-data-dashboard/front-end ${src_account_id})
}

function _docker_get_most_recent_back_end_image_tag() {
    src_account_id=$(_get_tools_account_id)
    echo $(_docker_get_most_recent_image_tag_from_repo ukhsa-data-dashboard/back-end ${src_account_id})
}

function _docker_get_most_recent_ingestion_image_tag() {
    src_account_id=$(_get_tools_account_id)
    echo $(_docker_get_most_recent_image_tag_from_repo ukhsa-data-dashboard/ingestion ${src_account_id})
}

function _docker_get_most_recent_image_tag_from_repo() {
    local ecr_repo_name=$1
    local account_id=$2

    if [[ -z ${ecr_repo_name} ]]; then
      echo "ECR repo name is required" >&2
      return 1
    fi

    if [[ -z ${account_id} ]]; then
      echo "Account ID is required" >&2
      return 1
    fi

    echo $(
      aws ecr describe-images \
        --repository-name ${ecr_repo_name} \
        --registry-id ${account_id} \
        --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
        --output text
      )
}
