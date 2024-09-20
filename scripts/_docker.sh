#!/bin/bash

function _docker_help() {
    echo
    echo "uhd docker <command> [options]"
    echo
    echo "commands:"
    echo "  help                                 - this help screen"
    echo
    echo "  build [repo]                         - build a docker image for the specified repo"
    echo
    echo "  pull                                 - *DEPRECATED pull the latest source images from the tools account"
    echo "  push                                 - *DEPRECATED push images to your dev ECR"
    echo "  push <account> <env>                 - *DEPRECATED tag and push images"
    echo
    echo "  update <account> <env>               - pull the latest source images and push to the specified environment"
    echo
    echo "  get-recent-tag <ecr-repo> <!account> - Gets the latest image tag from the given repo in the current account"
    echo
    echo "  ecr:login                            - login to ECR in the tools account"
    echo "  ecr:login <account>                  - login to ECR in the specified account"
    echo

    return 0
}

function _docker() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "build") _docker_build_with_custom_tag $args ;;
        "update") _docker_update $args ;;
        "pull") _docker_pull $args ;;
        "push") _docker_push $args ;;
        "get-recent-tag") _docker_get_most_recent_image_tag_from_repo $args ;;
        "ecr:login") _docker_ecr_login $args ;;

        *) _docker_help ;;
    esac
}

function _docker_build_with_custom_tag() {
    local repo=$1

    if [[ -z ${repo} ]]; then
        echo "Repo is required" >&2
        return 1
    fi

    local dev_account_id=$(_get_target_aws_account_id "dev")
    local env=$(_get_env_name)

    if [[ ${repo} == "ingestion" ]]; then
      cd $root/../data-dashboard-api
      echo "building docker image for ingestion lambda"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build -f Dockerfile-ingestion --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion-lambda:custom-${commit_hash} --push .
    fi

    if [[ ${repo} == "api" || ${repo} == "back-end" || ${repo} == "backend" ]]; then
      cd $root/../data-dashboard-api
      echo "building docker image for back end"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-back-end-ecs:custom-${commit_hash} --push .
    fi

    if [[ ${repo} == "front-end" || ${repo} == "frontend" ]]; then
      cd $root/../data-dashboard-frontend
      echo "building docker image for front end"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-front-end-ecs:custom-${commit_hash} --push .
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

function _docker_update() {
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

    uhd docker ecr:login tools
    latest_back_end_image_tag=$(_docker_get_most_recent_back_end_image_tag)
    latest_ingestion_image_tag=$(_docker_get_most_recent_ingestion_image_tag)
    latest_front_end_image_tag=$(_docker_get_most_recent_front_end_image_tag)

    src_account_id=$(_get_tools_account_id)
    dest_account_id=$(_get_target_aws_account_id $account)

    # Pull images from central ECRs
    src=(
      "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/ukhsa-data-dashboard/back-end:${latest_back_end_image_tag}"
      "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/ukhsa-data-dashboard/ingestion:${latest_ingestion_image_tag}"
      "${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/ukhsa-data-dashboard/front-end:${latest_front_end_image_tag}"
    )

    echo $src | xargs -P10 -n1 docker pull

    # Push images to deployment ECRs
    uhd docker ecr:login $account
    dest=(
      "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-back-end-ecs:${latest_back_end_image_tag}"
      "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion-lambda:${latest_ingestion_image_tag}"
      "${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-front-end-ecs:${latest_front_end_image_tag}"
    )

    for ((i=1; i<=${#src[@]}; ++i)); do
        docker tag "${src[i]}" "${dest[i]}"
    done

    _docker_ecr_login "tools"

    echo $dest | xargs -P10 -n1 docker push
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
      echo $(_get_latest_image_in_default_account ${ecr_repo_name})
    else
      echo $(_get_latest_image_in_target_account ${ecr_repo_name} ${account_id})
    fi
}

function _get_latest_image_in_default_account() {
  local ecr_repo_name=$1

  echo $(
      aws ecr describe-images \
        --repository-name ${ecr_repo_name} \
        --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
        --output text
  )
}

function _get_latest_image_in_target_account() {
  local ecr_repo_name=$1
  local account_id=$2

  echo $(
    aws ecr describe-images \
      --repository-name ${ecr_repo_name} \
      --registry-id ${account_id} \
      --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
      --output text
  )
}