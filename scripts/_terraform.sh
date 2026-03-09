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
    echo "  cleanup                                         - destroys all CI test environments"
    echo "  force-unlock <layer> <lock id>                  - releases the lock on a workspace"
    echo "  workspace-list                                  - lists all terraform workspaces"
    echo "  state-rm                                        - Removes the given item from the Terraform state"
    echo "  get-dev-workspace-name <!username>              - Generates the personal dev env ID of the current user"
    echo
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
        "workspace-list") _terraform_workspace_list $args ;;
        "state-rm") _terraform_state_rm $args ;;
        "get-dev-workspace-name") _get_dev_workspace_name $args ;;

        "cleanup") _terraform_cleanup $args ;;

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
    local ukhsa_tenant_id=$(_get_ukhsa_tenant_id)
    local ukhsa_client_id=$(_get_ukhsa_client_id)
    local ukhsa_client_secret=$(_get_ukhsa_client_secret)

    echo "Running terraform plan for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local etl_account_id=$(_get_etl_sibling_aws_account_id $target_account_name)

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform plan \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var "etl_account_id=${etl_account_id}" \
        -var "ukhsa_tenant_id=${ukhsa_tenant_id}" \
        -var "ukhsa_client_id=${ukhsa_client_id}" \
        -var "ukhsa_client_secret=${ukhsa_client_secret}" \
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
    local ukhsa_tenant_id=$(_get_ukhsa_tenant_id)
    local ukhsa_client_id=$(_get_ukhsa_client_id)
    local ukhsa_client_secret=$(_get_ukhsa_client_secret)

    echo "Running terraform import for address '$address' and id '$id' into layer '$layer', workspace '$workspace', and account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local etl_account_id=$(_get_etl_sibling_aws_account_id $target_account_name)

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform import \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var "etl_account_id=${etl_account_id}" \
        -var "ukhsa_tenant_id=${ukhsa_tenant_id}" \
        -var "ukhsa_client_id=${ukhsa_client_id}" \
        -var "ukhsa_client_secret=${ukhsa_client_secret}" \
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
    local ukhsa_tenant_id=$(_get_ukhsa_tenant_id)
    local ukhsa_client_id=$(_get_ukhsa_client_id)
    local ukhsa_client_secret=$(_get_ukhsa_client_secret)

    echo "Running terraform apply for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local etl_account_id=$(_get_etl_sibling_aws_account_id $target_account_name)

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    # Check if a Cognito User Pool exists and if it's missing the custom attribute - This functionality should be deleted once all user pools have been migrated to new schema.

    echo "Checking for user pool"
    local user_pool=$(terraform state list 2>/dev/null | grep "aws_cognito_user_pool\." | grep -v "client" | grep -v "domain" | head -n 1)

    if [[ -n ${user_pool} ]]; then
        echo "User pool found"

        local migration_result=$(_migrate_cognito_user_pool_schema \
            "$user_pool" \
            "$assume_account_id" \
            "$tools_account_id" \
            "$python_version" \
            "$etl_account_id" \
            "$ukhsa_tenant_id" \
            "$ukhsa_client_id" \
            "$ukhsa_client_secret" \
            "$var_file" 2>&1)

        local migration_exit=$?

        echo "$migration_result"

        if [[ ${migration_exit} -ne 0 ]]; then
            echo "Migration check failed. Aborting." >&2
            return 1
        fi
    else
        echo "No user pool found in Terraform state. Skipping migration check."
    fi

    terraform apply \
        -parallelism=20 \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var "etl_account_id=${etl_account_id}" \
        -var "ukhsa_tenant_id=${ukhsa_tenant_id}" \
        -var "ukhsa_client_id=${ukhsa_client_id}" \
        -var "ukhsa_client_secret=${ukhsa_client_secret}" \
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
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_hydrate_private_api_cache_reserved_namespace
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_hydrate_public_api_cache
    uhd terraform output-file:layer 20-app $workspace local_sensitive_file.ecs_job_bootstrap_env
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
    local ukhsa_tenant_id=$(_get_ukhsa_tenant_id)
    local ukhsa_client_id=$(_get_ukhsa_client_id)
    local ukhsa_client_secret=$(_get_ukhsa_client_secret)

    echo "Running terraform destroy for layer '$layer', workspace '$workspace', into account '$target_account_name'..."

    local assume_account_id=$(_get_target_aws_account_id $target_account_name)

    if [[ -z ${assume_account_id} ]]; then
        echo "Can't find aws account id for account $target_account_name" >&2
        return 1
    fi

    local etl_account_id=$(_get_etl_sibling_aws_account_id $target_account_name)

    local var_file="etc/${target_account_name}.tfvars"

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1

    terraform destroy \
        -parallelism=20 \
        -var "assume_account_id=${assume_account_id}" \
        -var "tools_account_id=${tools_account_id}" \
        -var "python_version=${python_version}" \
        -var "etl_account_id=${etl_account_id}" \
        -var "ukhsa_tenant_id=${ukhsa_tenant_id}" \
        -var "ukhsa_client_id=${ukhsa_client_id}" \
        -var "ukhsa_client_secret=${ukhsa_client_secret}" \
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

function _terraform_state_rm() {
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
        echo "Address is required" >&2
        return 1
    fi

    local terraform_dir=$(_get_terraform_dir $layer)
    echo "Running terraform state rm for layer '$layer', workspace '$workspace' & address '$address'..."

    cd $terraform_dir
    terraform workspace select "$workspace" || terraform workspace new "$workspace" || return 1
    terraform state rm $address || return 1
}

function _terraform_workspace_list() {
  local envs=($(terraform -chdir=terraform/20-app workspace list))

  for env in ${envs[@]}; do
    if [[ ! $env == "*" ]] && [[ ! " ${files[@]} " =~ " ${env} " ]]; then
      echo "-> ${env}"
    fi
  done
}

function _terraform_cleanup() {
    local envs=($(terraform -chdir=terraform/20-app workspace list))
    local files=($(echo \*))
    
    for env in ${envs[@]}; do
        if [[ ! $env == "*" ]] && [[ ! " ${files[@]} " =~ " ${env} " ]]; then
            if [[ $env == ci-* ]]; then
                echo "Environment $env is a test environment.  It will be destroyed... "
                echo
                uhd terraform destroy:layer 20-app $env
            elif [[ $env == etl-ci-* ]]; then
                echo "Environment $env is a CI environment belonging to the ETL infra. Skipping this. "
            else
                echo "Environment $env is an engineer's dev or well known environment."
            fi
        fi
    done
}

function _migrate_cognito_user_pool_schema() {
    local user_pool_resource=$1
    local assume_account_id=$2
    local tools_account_id=$3
    local python_version=$4
    local etl_account_id=$5
    local ukhsa_tenant_id=$6
    local ukhsa_client_id=$7
    local ukhsa_client_secret=$8
    local var_file=$9
    
    echo "Checking Cognito User Pool for schema migration..."
    
    # Extract user pool ID from Terraform state
    local pool_id=$(terraform state show "$user_pool_resource" 2>/dev/null | \
                    grep "^[[:space:]]*id[[:space:]]*=" | \
                    awk -F'"' '{print $2}')

    echo "User pool ID found: ${pool_id}"
    
    if [[ -z ${pool_id} ]]; then
        echo "Warning: Could not determine user pool ID. Skipping migration check." >&2
        return 0
    fi
    
    # Check if the entraObjectId attribute already exists
    local has_attribute=$(aws cognito-idp describe-user-pool \
                         --user-pool-id "$pool_id" \
                         --query "UserPool.SchemaAttributes[?Name=='custom:entraObjectId'].Name" \
                         --output text 2>&1)

    local aws_exit_code=$?

    if [[ ${aws_exit_code} -ne 0 ]]; then
        echo "Error: Failed to query user pool attributes. AWS CLI output:" >&2
        echo "$has_attribute" >&2
        echo "Skipping migration to avoid accidental user loss." >&2
        return 1
    fi

    local needs_migration=false
    
    # Check user pool schema
    if [[ -z ${has_attribute} ]]; then
        echo "Custom attribute 'entraObjectId' missing in user pool."
        needs_migration=true
    else
        echo "Custom attribute 'entraObjectId' exists in user pool."
    fi

    # Check if identity provider needs the attribute mapping
    local idp_resource=$(terraform state list 2>/dev/null | \
                        grep "aws_cognito_identity_provider.ukhsa_oidc_idp" | \
                        head -n 1)

    if [[ -n ${idp_resource} ]]; then
        echo "Checking identity provider attribute mappings..."
        
        # Get the identity provider details from state
        local idp_state=$(terraform state show "$idp_resource" 2>/dev/null)
        
        # Check if custom:entraObjectId mapping exists
        if echo "$idp_state" | grep -q '"custom:entraObjectId"'; then
            echo "Identity provider already has 'custom:entraObjectId' mapping."
        else
            echo "Identity provider missing 'custom:entraObjectId' mapping."
            echo "To add attribute mapping, entire user pool stack must be recreated."
            needs_migration=true
        fi
    fi

    # If no migration needed, exit early
    if [[ "$needs_migration" == false ]]; then
        echo "No migration needed. All resources are up to date."
        return 0
    fi

    # Build list of all Cognito resources to destroy
    echo "Starting Cognito stack migration..."
    echo "WARNING: This will delete all users in the user pool."
    
    local resources_to_replace=()
    
    # Find and add domain
    local domain_resource=$(terraform state list 2>/dev/null | \
                           grep "aws_cognito_user_pool_domain" | \
                           head -n 1)
    
    if [[ -n ${domain_resource} ]]; then
        echo "  → Will destroy: $domain_resource"
        resources_to_replace+=("$domain_resource")
    fi
    
    # Add user pool
    echo "  → Will destroy: $user_pool_resource"
    resources_to_replace+=("$user_pool_resource")
    
    # Add identity provider if it exists
    if [[ -n ${idp_resource} ]]; then
        echo "Will destroy: $idp_resource"
        resources_to_replace+=("$idp_resource")
    fi
    
    # Add user pool client
    local client_resource=$(terraform state list 2>/dev/null | \
                           grep "aws_cognito_user_pool_client.user_pool_client" | \
                           head -n 1)
    
    if [[ -n ${client_resource} ]]; then
        echo "Will destroy: $client_resource"
        resources_to_replace+=("$client_resource")
    fi
    
    # Add user groups
    local group_resources=$(terraform state list 2>/dev/null | \
                           grep "aws_cognito_user_group.cognito_user_groups")
    
    if [[ -n ${group_resources} ]]; then
        while IFS= read -r group; do
            echo "Will destroy: $group"
            resources_to_replace+=("$group")
        done <<< "$group_resources"
    fi

    # Build terraform destroy command with all targets
    if [[ ${#resources_to_replace[@]} -gt 0 ]]; then
        echo "Destroying ${#resources_to_replace[@]} Cognito resources..."
        
        local target_flags=()
        for resource in "${resources_to_replace[@]}"; do
            target_flags+=("-target=$resource")
        done
        
        terraform destroy \
            -var "assume_account_id=${assume_account_id}" \
            -var "tools_account_id=${tools_account_id}" \
            -var "python_version=${python_version}" \
            -var "etl_account_id=${etl_account_id}" \
            -var "ukhsa_tenant_id=${ukhsa_tenant_id}" \
            -var "ukhsa_client_id=${ukhsa_client_id}" \
            -var "ukhsa_client_secret=${ukhsa_client_secret}" \
            -var-file="$var_file" \
            "${target_flags[@]}" \
            -auto-approve || return 1
        
        echo "Waiting 60s for AWS to propagate deletions..."
        sleep 60
        echo "Migration preparation complete. Resources will be recreated with new configuration."
        echo ""
    fi
    
    return 0
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

function _get_etl_sibling_aws_account_id() {
  local account=$1

  local account_name=${account#auth-}

  aws secretsmanager get-secret-value \
    --secret-id "aws/account-id/etl-$account_name" \
    --query SecretString \
    --output text
}

function _get_ukhsa_tenant_id() {
  aws secretsmanager get-secret-value --secret-id "aws/auth/ukhsa-tenant-id" --query SecretString --output text
}

function _get_ukhsa_client_id() {
  aws secretsmanager get-secret-value --secret-id "aws/auth/ukhsa-client-id" --query SecretString --output text
}

function _get_ukhsa_client_secret() {
  aws secretsmanager get-secret-value --secret-id "aws/auth/ukhsa-client-secret" --query SecretString --output text
}

function _get_target_aws_account_name() {
    local layer=$1
    local workspace=$2

    if [[ $layer == "10-account" ]]; then
        echo "$workspace"
        return
    fi

    if [[ $workspace == *"auth"* ]]; then
        _get_auth_target_aws_account_name "$workspace"
    else
        _get_main_target_aws_account_name "$workspace"
    fi
}

function _get_main_target_aws_account_name() {
    local workspace=$1

    if [[ $workspace == "prod" ]]; then
        echo "prod"
    elif [[ $CI == "true" ]]; then
        if [[ $workspace == ci-* ]] || [[ $workspace == perf ]] || [[ $workspace == pen ]]; then
            echo "test"
        else
            case $branch in
                env/dev/*)  echo "dev"  ;;
                env/uat/*)  echo "uat"  ;;
                env/test/*) echo "test" ;;
                *)          echo "dev"  ;; # Default to dev
            esac
        fi
    else
        echo "dev"
    fi
}

function _get_auth_target_aws_account_name() {
    local workspace=$1

    if [[ $workspace == "auth-prod" ]]; then
        echo "auth-prod"
    elif [[ $CI == "true" ]]; then
        if [[ $workspace == ci-* ]]|| [[ $workspace == perf ]] || [[ $workspace == pen ]]; then
            echo "auth-test"
        else
            case $branch in
                env/auth-dev/*)  echo "auth-dev"  ;;
                env/auth-uat/*)  echo "auth-uat"  ;;
                env/auth-test/*) echo "auth-test" ;;
                *)               echo "auth-dev"  ;;
            esac
        fi
    else
        echo "auth-dev"
    fi
}

_get_dev_workspace_name() {
    local input="${1:-$(whoami)}"
    echo "$input" | openssl dgst -sha1 -binary | xxd -p | cut -c1-8
}

_get_workspace_name() {
    local workspace=$1

    if [[ -z $workspace ]]; then
        # This creates a hash of your username on your machine.  We use this as your
        # dev env name to ensure everyone has their own isolated environment to break 🔥
        # For example janesmith evaluates to 4279cbe8
        echo $(_get_dev_workspace_name)
    else
        echo $workspace
    fi
}

_get_python_version() {
    cat .python-version
}