#!/bin/bash

function _terraform_help() {
    echo
    echo "uhd terraform <command> [options]"
    echo
    echo "commands:"
    echo "  help                         - this help screen"
    echo
    echo "  init:layer <layer>           - runs `terraform init` for the specified layer" 
    echo

    return 1
}

function _terraform() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "init:layer") _terraform_init_layer $args ;;

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

function _get_terraform_dir() {
  local layer=$1
  
  echo "$root/terraform/$layer"
}