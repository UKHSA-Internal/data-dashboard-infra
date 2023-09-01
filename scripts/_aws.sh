#!/bin/bash


function _aws_help() {
    echo
    echo "uhd aws <command> [options]"
    echo
    echo "commands:"
    echo "  help            - this help screen"
    echo
    echo "  login           - login to the dev and tools accounts as a developer"
    echo "  login <profile> - login and assume the configured role"
    echo "  whoami          - display the account you're logged into and which role you have assumed"
    echo

    return 1
}

function _aws() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "login") _aws_login $args ;;
        "whoami") _aws_whoami $args ;;

        *) _aws_help ;;
    esac
}

function _aws_login() {
    local profile_name=$1
    if [[ -z ${profile_name} ]]; then
        uhd aws login uhd-dev
        uhd aws login uhd-tools
        
        return 0
    fi

    aws sso login --profile $profile_name

    case $profile_name in
        "uhd-dev" | "uhd-tools")
            export AWS_PROFILE=${profile_name}/assumed-role ;;

        "*")
            export AWS_PROFILE=$profile_name ;;
    esac
}

function _aws_whoami() {
    aws sts get-caller-identity | jq .
}
