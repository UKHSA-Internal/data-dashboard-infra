#!/bin/bash


function _aws_help() {
    echo
    echo "uhd aws <command> [options]"
    echo
    echo "commands:"
    echo "  help            - this help screen"
    echo
    echo "  login           - login to the dev and tools accounts as a developer"
    echo "  login-auth      - login to the auth-dev and tools accounts as a developer"
    echo "  login <profile> - login and assume the configured role"
    echo
    echo "  use <profile>   - switch to the specified profile"
    echo
    echo "  whoami          - display the account you're logged into and which role you have assumed"
    echo

    return 1
}

function _aws() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "login") _aws_login $args ;;
        "login-auth") _aws_login_auth $args ;;
        "use") _aws_use $args ;;
        "whoami") _aws_whoami $args ;;

        *) _aws_help ;;
    esac
}

function _aws_login() {
    local profile_name=$1
    if [[ -z ${profile_name} ]]; then
        uhd aws login uhd-dev

        # If using the auth infra you can enable this profile and comment out the uhd-dev command above.
        # uhd aws login uhd-auth-dev
        uhd aws login uhd-tools
        
        return 0
    fi

    aws sso login --profile $profile_name

    echo

    case $profile_name in
        "uhd-dev" | "uhd-auth-dev" | "uhd-dev:ops" | "uhd-test" | "uhd-uat" | "uhd-prod" | "uhd-tools" | "uhd-tools:ops" )
            echo "Logged into AWS using profile '$profile_name', and switched to profile '${profile_name}/assumed-role'"
            export AWS_PROFILE=${profile_name}/assumed-role ;;

        *)
            echo "Logged into AWS using profile '$profile_name'"
            export AWS_PROFILE=$profile_name ;;
    esac
}

function _aws_login_auth() {
    local profile_name=$1
    if [[ -z ${profile_name} ]]; then

        uhd aws login uhd-auth-dev
        uhd aws login uhd-tools
        
        return 0
    fi
}

function _aws_use() {
    local profile_name=$1
    if [[ -z ${profile_name} ]]; then
        echo "Profile is required"
        
        return 1
    fi

    case $profile_name in
        "uhd-dev" | "uhd-tools")
            echo "Switching to profile '${profile_name}/assumed-role'"
            export AWS_PROFILE=${profile_name}/assumed-role ;;

        *)
            echo "Switching to profile '$profile_name'"
            export AWS_PROFILE=$profile_name ;;
    esac
}

function _aws_whoami() {
    local env=$(_get_env_name)
    local urls=$(_get_public_urls)

    echo "Using profile $AWS_PROFILE:"

    aws sts get-caller-identity | jq .

    echo
    echo Connected to $env environment:
    echo $urls | jq .
}

function _get_public_urls() {
    local terraform_output_file=terraform/20-app/output.json
    local urls=$(jq -r '.urls.value | { cms_admin, front_end, public_api }'  $terraform_output_file)

    echo $urls
}
