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

    secret_ids=("uhd-${env}-private-api-key"
                "uhd-${env}-cms-admin-user-credentials"
                "uhd-${env}-backend-cryptographic-signing-key"
                "uhd-${env}-cdn-front-end-secure-header-value"
                "uhd-${env}-cdn-public-api-secure-header-value"
                "uhd-${env}-private-api-email-credentials"
                "uhd-${env}-google-analytics-credentials"
                "uhd-${env}-aurora-db-feature-flags-credentials"
                "uhd-${env}-feature-flags-admin-user-credentials"
                "uhd-${env}-feature-flags-api-keys"
                "uhd-${env}-esri-api-key")

    for ((i=1; i<=${#secret_ids[@]}; ++i)); do
        _delete_secret "${secret_ids[i]}"
    done
}
