#!/bin/bash

function _update() {
    local workspace="$(_get_workspace_name)"

    uhd terraform apply
    uhd docker ecr:login
    uhd docker pull 
    uhd docker push dev $workspace

    export AWS_PROFILE=uhd-dev/assumed-role

    uhd ecs restart-services

    export AWS_PROFILE=uhd-tools/assumed-role
}