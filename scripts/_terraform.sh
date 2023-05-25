#!/bin/bash

function _terraform_help() {
    echo
    echo "uhd terraform <command> [options]"
    echo
    echo "commands:"
    echo "  help                               - this help screen"
    echo
    echo "  plan <workspace?>                  - runs terraform plan for the app layer and optional workspace"
    echo "  apply <workspace?>                 - runs terraform apply for the app layer and optional workspace"
    echo
    echo "  init:layer <layer>                 - runs terraform init for the specified layer" 
    echo "  plan:layer <layer> <workspace>     - runs terraform plan for the specified layer and workspace"
    echo "  apply:layer <layer> <workspace>    - runs terraform apply for the specified layer and workspace"
    echo "  destroy:layer <layer> <workspace>  - runs terraform destroy for the specified layer and workspace"
    echo

    return 1
}

function _terraform() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "plan") _terraform_plan_app_layer $args ;;
        "apply") _terraform_apply_app_layer $args ;;
        "init:layer") _terraform_init_layer $args ;;
        "plan:layer") _terraform_plan_layer $args ;;
        "apply:layer") _terraform_apply_layer $args ;;
        "destroy:layer") _terraform_destroy_layer $args ;;

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

function _terraform_plan_app_layer() {
    local workspace="$(_get_workspace_name $1)"

    _terraform_plan_layer "20-app" $workspace
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
    local target_account_name=$(_get_target_aws_account_name $layer $workspace)

    echo "Running terraform plan for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $workspace" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform plan \
        -var "assume_account_id=${assume_account_id}" \
        -var-file=$var_file || return 1
}

function _terraform_apply_app_layer() {
    local workspace="$(_get_workspace_name $1)"

    _terraform_apply_layer "20-app" $workspace
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
    local target_account_name=$(_get_target_aws_account_name $layer $workspace)

    echo "Running terraform apply for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $workspace" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform apply \
        -var "assume_account_id=${assume_account_id}" \
        -var-file=$var_file \
        -auto-approve || return 1
}

function _terraform_destroy_layer() {
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
    local target_account_name=$(_get_target_aws_account_name $layer $workspace)

    echo "Running terraform destroy for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $workspace" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform destroy \
        -var "assume_account_id=${assume_account_id}" \
        -var-file=$var_file \
        -auto-approve || return 1
}

function _get_terraform_dir() {
  local layer=$1
  
  echo "$root/terraform/$layer"
}

function _get_tools_account_id() {
  aws sts get-caller-identity | jq -r .Account 
}

function _get_target_aws_account_id() {
  local account=$1  
  local tools_account_id=$(_get_tools_account_id)
  
  aws secretsmanager get-secret-value --secret-id "aws/account-id/$account" --query SecretString --output text
}

function _get_target_aws_account_name() {
    local layer=$1
    local workspace=$2 

    if [[ $layer == "10-account" ]]; then
        echo $workspace
    else
        if [[ $workspace == "prod" ]]; then
            echo "prod"
        elif [[ $CI == "true" ]]; then
            if [[ $GITHUB_REF_NAME == "wke/dev/"* ]]; then
                echo "dev"
            elif [[ $GITHUB_REF_NAME == "wke/uat/"* ]]; then
                echo "uat"
            else
                echo "test"
            fi    
        else
            echo "dev"
        fi
    fi 
}

_get_workspace_name() {
    local workspace=$1

    if [[ -z $workspace ]]; then
        # This creates a hash of your username on your machine.  We use this as your
        # dev env name to ensure everyone has their own isolated environemtnt to break 🔥
        # For example janesmith evaluates to 4279cbe8
        echo $(whoami | openssl dgst -sha1 -binary | xxd -p | cut -c1-8)
    else
        echo $workspace
    fi
}