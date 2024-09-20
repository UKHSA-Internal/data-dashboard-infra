#!/bin/bash

function _update() {
    local workspace="$(_get_workspace_name)"

    uhd terraform init
    uhd terraform apply
    uhd docker update dev $workspace

    export AWS_PROFILE=uhd-dev/assumed-role

    uhd ecs restart-services
    uhd lambda restart-functions

    export AWS_PROFILE=uhd-tools/assumed-role
}