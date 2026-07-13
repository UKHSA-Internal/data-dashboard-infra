#!/bin/bash

function _secrets_help() {
    echo
    echo "uhd secrets <command> [options]"
    echo
    echo "commands:"
    echo "  help                      - this help screen"
    echo
    echo "  delete-secret <id>        - delete a secret by id"
    echo "  delete-all-secrets <env>  - delete all secrets for the given environment"

    return 0
}

function _secrets() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "delete-secret") _delete_secret $args ;;
        "delete-all-secrets") _delete_all_secrets $args ;;

        *) _secrets_help ;;
    esac
}

function _delete_secret() {
    local secret_id=$1

    if [[ -z ${secret_id} ]]; then
        echo "Secret ID is required" >&2
        return 1
    fi

   aws secretsmanager delete-secret --secret-id "$secret_id" --force-delete-without-recovery
}

function _delete_all_secrets() {
    local env=$1

    if [[ -z ${env} ]]; then
        echo "Env is required" >&2
        return 1
    fi

    # get all secrets for $env
    secret_ids=$(aws secretsmanager list-secrets \
        --include-planned-deletion \
        --query "SecretList[?contains(Name, \`$env\`)].Name" \
        --output json | jq -r '.[]')

    if [[ -z "$secret_ids" ]]; then
      echo "No secrets to delete"
    return 0
    fi
 
    # call delete on all secrets in $env
    while IFS= read -r secret_id; do
      _delete_secret $secret_id
    done <<< "$secret_ids"
}
