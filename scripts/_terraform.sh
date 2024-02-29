#!/bin/bash

function _terraform_help() {
    echo
    echo "uhd terraform <command> [options]"
    echo
    echo "commands:"
    echo "  help                                            - this help screen"
    echo
    echo "  init                                            - runs terraform init for all layers" 
    echo "  plan                                            - runs terraform plan for the app layer in your dev workspace"
    echo "  apply                                           - runs terraform apply for the app layer in your dev workspace"
    echo "  upgrade                                         - runs terraform upgrade for all layers"
    echo
    echo "  plan <workspace>                                - runs terraform plan for the app layer and workspace"
    echo "  apply <workspace>                               - runs terraform apply for the app layer and workspace"
    echo "  output <workspace>                              - runs terraform output for the app layer and workspace and write ECS task files"
    echo
    echo "  init:layer <layer>                              - runs terraform init for the specified layer" 
    echo "  plan:layer <layer> <workspace>                  - runs terraform plan for the specified layer and workspace"
    echo "  import:layer <layer> <workspace> <address> <id> - runs terraform import for the specified layer, workspace, address and id"
    echo "  apply:layer <layer> <workspace>                 - runs terraform apply for the specified layer and workspace"
    echo "  output:layer <layer> <workspace>                - runs terraform output for the specified layer and workspace"
    echo "  upgrade:layer <layer>                           - runs terraform upgrade for the specified layer"
    echo "  destroy:layer <layer> <workspace>               - runs terraform destroy for the specified layer and workspace"
    echo
    echo "  output-file:layer <layer> <workspace> <address> - writes the contents of templated file to disk"
    echo
    echo "  force-unlock <layer> <lock id>                  - releases the lock on a workspace"
    return 1
}

function _terraform() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "init") _terraform_init $args ;;
        "plan") _terraform_plan_app_layer $args ;;
        "apply") _terraform_apply_app_layer $args ;;
        "upgrade") _terraform_upgrade $args ;;
        "output") _terraform_output $args ;;
        "init:layer") _terraform_init_layer $args ;;
        "plan:layer") _terraform_plan_layer $args ;;
        "apply:layer") _terraform_apply_layer $args ;;
        "import:layer") _terraform_import_layer $args ;;
        "upgrade:layer") _terraform_upgrade_layer $args ;;
        "output:layer") _terraform_output_layer $args ;;
        "output-file:layer") _terraform_output_layer_file $args ;;
        "destroy:layer") _terraform_destroy_layer $args ;;
        "force-unlock") _terraform_force_unlock $args ;;

        *) _terraform_help ;;
    esac
}

function _terraform_init() {
    _terraform_init_layer "10-account"
    echo
    _terraform_init_layer "20-app"
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

function _terraform_upgrade() {
    _terraform_upgrade_layer "10-account"
    echo
    _terraform_upgrade_layer "20-app"
}

function _terraform_upgrade_layer() {
    local layer=$1

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)

    echo "Upgrading terraform providers for layer '$layer'..."

    cd $terraform_dir

    terraform init -upgrade
    terraform providers lock -platform=darwin_amd64 -platform=darwin_arm64 -platform=linux_amd64
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
    local tools_account_id=$(_get_tools_account_id)
    local python_version=$(_get_python_version)

    echo "Running terraform plan for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform plan \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var-file=$var_file || return 1
}

function _terraform_import_layer() {
    local layer=$1
    local workspace=$2
    local address=$3
    local id=$4

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    if [[ -z ${workspace} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    if [[ -z ${address} ]]; then
        echo "Address is required" >&2
        return 1
    fi

    if [[ -z ${id} ]]; then
        echo "ID is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)
    local target_account_name=$(_get_target_aws_account_name $layer $workspace)
    local tools_account_id=$(_get_tools_account_id)
    local python_version=$(_get_python_version)

    echo "Running terraform import for address '$address' and id '$id' into layer '$layer', workspace '$workspace', and account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform import \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var-file=$var_file \
        $address \
        $id || return 0
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
    local tools_account_id=$(_get_tools_account_id)
    local python_version=$(_get_python_version)

    echo "Running terraform apply for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform apply \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var-file=$var_file \
        -auto-approve || return 1

    terraform output -json > output.json
}

function _terraform_output() {
    local workspace=$1

    if [[ -z ${workspace} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    uhd terraform output:layer 20-app $workspace
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_hydrate_frontend_cache 
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_hydrate_private_api_cache 
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_hydrate_public_api_cache 
}

function _terraform_output_layer() {
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
    
    echo "Running terraform output for layer '$layer', workspace '$workspace'..."

    cd $terraform_dir

    terraform workspace select "$workspace" || return 1
    terraform output -json > output.json
}

function _terraform_output_layer_file() {
    local layer=$1
    local workspace=$2
    local address=$3

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi

    if [[ -z ${workspace} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    if [[ -z ${address} ]]; then
        echo "Workspace is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)
    
    echo "Running terraform output-file for layer '$layer', workspace '$workspace', for resource '$address'..."

    cd $terraform_dir

    terraform workspace select "$workspace" || return 1
    
    resource=$(terraform show -json | jq -r --arg ADDRESS $address '.values.root_module.resources[] | select(.address  == $ADDRESS)')
    filename=$(jq -r .values.filename <<< $resource)

    echo "Writing file content to '$filename'..."
    jq -r .values.content <<< $resource > $filename
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
    local tools_account_id=$(_get_tools_account_id)
    local python_version=$(_get_python_version)

    echo "Running terraform destroy for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform destroy \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var-file=$var_file \
        -auto-approve || return 1

    _terraform_delete_workspace $workspace || return 1
}

function _terraform_delete_workspace() {
    local workspace=$1

    # terraform does not allow deletion of the current workspace.
    # So we need to switch to another workspace before deleting it
    terraform workspace select "default"
    echo "Running terraform workspace delete for workspace '$workspace'"

    terraform workspace delete "$workspace"
}

function _terraform_force_unlock() {
    local layer=$1
    local lock_id=$2

    if [[ -z ${layer} ]]; then
        echo "Layer is required" >&2
        return 1
    fi
    
    if [[ -z ${lock_id} ]]; then
        echo "Lock id is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)

    echo "Running terraform force unlock for layer '$layer', and lock id '$lock_id'..."

    cd $terraform_dir
    terraform force-unlock --force $lock_id
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
            if [[ $branch == "env/dev/"* ]]; then
                echo "dev"
            elif [[ $branch == "env/uat/"* ]]; then
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

_get_python_version() {
    cat .python-version
}