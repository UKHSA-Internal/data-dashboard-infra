#!/bin/bash


function _aws_help() {
    echo
    echo "uhd aws <command> [options]"
    echo
    echo "commands:"
    echo "  help            - this help screen"
    echo
    echo "  login <profile> - login and assume the configured role"
    echo

    return 1
}

function _aws() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "login") _aws_login $args ;;

        *) _aws_help ;;
    esac
}

function _aws_login() {
    local profile_name=$1
    if [[ -z ${profile_name} ]]; then
        echo "Profile name is required." >&2
        return 1
    fi

    aws sso login --profile $profile_name

    export AWS_PROFILE=$profile_name
}
