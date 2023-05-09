#!/bin/bash

function _terraform_help() {
    echo
    echo "uhd terraform <command> [options]"
    echo
    echo "commands:"
    echo "  help                             - this help screen"
    echo
    echo "  init:layer <layer>               - runs terraform init for the specified layer" 
    echo "  plan:layer <layer> <workspace>   - runs terraform plan for the specified layer and workspace"
    echo "  apply:layer <layer> <workspace>  - runs terraform apply for the specified layer and workspace"
    echo

    return 1
}

function _terraform() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "init:layer") _terraform_init_layer $args ;;
        "plan:layer") _terraform_plan_layer $args ;;
        "apply:layer") _terraform_apply_layer $args ;;

        *) _terraform_help ;;
    esac
}

function _terraform_init_layer() {
    local layer=$1

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)

    echo "Initialising terraform for layer '$layer'..."

    cd $terraform_dir
    terraform init
}

function _terraform_plan_layer() {
    local layer=$1
    local workspace=$2

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    if [[ -z ${workspace} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)

    echo "Running terraform plan for layer '$layer' and workspace '$workspace'..."

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    local assume_account_id=$(_get_aws_account_id $workspace)

    terraform plan \
        -var "assume_account_id=${assume_account_id}" 
}

function _terraform_apply_layer() {
    local layer=$1
    local workspace=$2

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    if [[ -z ${workspace} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)

    echo "Running terraform apply for layer '$layer' and workspace '$workspace'..."

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    local assume_account_id=$(_get_aws_account_id $workspace)

    terraform apply \
        -var "assume_account_id=${assume_account_id}" \
        -auto-approve 
}

function _get_terraform_dir() {
  local layer=$1
  
  echo "$root/terraform/$layer"
}

function _get_tools_account_id() {
  aws sts get-caller-identity | jq -r .Account 
}

function _get_aws_account_id() {
  local account=$1  
  local tools_account_id=$(_get_tools_account_id)
  
  aws secretsmanager get-secret-value --secret-id "aws/account-id/$account" --query SecretString --output text
}