#!/bin/bash

function _docker_help() {
    echo
    echo "uhd docker <command> [options]"
    echo
    echo "commands:"
    echo "  help                                     - this help screen"
    echo
    echo "  build <repo> <!env>                      - build a docker image for the specified repo, env can be used to target an environment"
    echo "  update <account> <env>                   - pull the latest source images and push to the specified environment"
    echo "  update-service <account> <env> <service> - pull the latest source image and push to the specified service in environment"
    echo "  get-recent-tag <ecr-repo> <!account>     - gets the latest image tag from the given repo in the current account"
    echo
    echo "  ecr:login                                - login to ECR in the tools account"
    echo "  ecr:login <account>                      - login to ECR in the specified account"
    echo

    return 0
}

function _docker() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "build") _docker_build_with_custom_tag $args ;;
        "update") _docker_update $args ;;
        "update-service") _docker_update_service $args ;;
        "get-recent-tag") _docker_get_most_recent_image_tag_from_repo $args ;;
        "ecr:login") _docker_ecr_login $args ;;

        *) _docker_help ;;
    esac
}

function _docker_build_with_custom_tag() {
    local repo=$1
    local env_name=$2

    if [[ -z ${repo} ]]; then
        echo "Repo is required" >&2
        return 1
    fi

    if [[ -z ${env_name} ]]; then
      local env=$(_get_env_name)
    else
      local env=$env_name
    fi

    local account_name="dev"
    uhd docker ecr:login ${account_name}

    local dev_account_id=$(_get_target_aws_account_id ${account_name})

    if [[ ${repo} == "ingestion" ]]; then
      cd $root/../data-dashboard-api
      echo "building docker image for ingestion lambda"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build -f Dockerfile-ingestion --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-ingestion-lambda:custom-${commit_hash}-${RANDOM} --push .
    fi

    if [[ ${repo} == "api" || ${repo} == "back-end" || ${repo} == "backend" ]]; then
      cd $root/../data-dashboard-api
      echo "building docker image for back end"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-back-end-ecs:custom-${commit_hash}-${RANDOM} --push .
    fi

    if [[ ${repo} == "front-end" || ${repo} == "frontend" ]]; then
      cd $root/../data-dashboard-frontend
      echo "building docker image for front end"
      local commit_hash=$(git rev-parse --short HEAD)
      docker buildx build --platform linux/arm64 -t ${dev_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-front-end-ecs:custom-${commit_hash}-${RANDOM} --push .
    fi

    cd $root
}

function _docker_update_service() {
    local account=$1
    local env=$2
    local service=$3

    if [[ -z ${account} ]]; then
        echo "Account is required" >&2
        return 1
    fi

    if [[ -z ${env} ]]; then
        echo "Env is required" >&2
        return 1
    fi

    if [[ -z ${service} ]]; then
        echo "Service (back-end|ingestion|front-end) is required" >&2
        return 1
    fi

    uhd docker ecr:login tools

    local latest_image_tag
    case "${service}" in
        "back-end")
            latest_image_tag=$(_docker_get_most_recent_back_end_image_tag)
            ;;
        "ingestion")
            latest_image_tag=$(_docker_get_most_recent_ingestion_image_tag)
            ;;
        "front-end")
            latest_image_tag=$(_docker_get_most_recent_front_end_image_tag)
            ;;
    esac

    src_account_id=$(_get_tools_account_id)
    dest_account_id=$(_get_target_aws_account_id $account)

    local src_image="${src_account_id}.dkr.ecr.eu-west-2.amazonaws.com/ukhsa-data-dashboard/${service}:${latest_image_tag}"
    local dest_image="${dest_account_id}.dkr.ecr.eu-west-2.amazonaws.com/uhd-${env}-${service}-"

    if [[ "${service}" == "ingestion" ]]; then
        dest_image+="lambda:${latest_image_tag}-${RANDOM}"
    else
        dest_image+="ecs:${latest_image_tag}-${RANDOM}"
    fi

    echo "Pulling ${src_image}..."
    docker pull "${src_image}" || { echo "Failed to pull image ${src_image}"; return 1; }

    uhd docker ecr:login $account
    echo "Tagging ${src_image} as ${dest_image}..."
    docker tag "${src_image}" "${dest_image}"

    _docker_ecr_login "tools"
    echo "Pushing ${dest_image}..."
    docker push "${dest_image}" || { echo "Failed to push image"; return 1; }
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