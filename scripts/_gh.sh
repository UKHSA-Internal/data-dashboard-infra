#!/bin/bash

function _gh_help() {
    echo
    echo "uhd gh <command> [options]"
    echo
    echo "commands:"
    echo "  help           - this help screen"
    echo 
    echo "  clone          - clone all the repos"
    echo "  co [repo] [pr] - checkout the specified pull request"
    echo "  main           - switch to main branch in all repos and pull the latest if possible"
    echo

    return 0
}

function _gh() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "clone") _gh_clone $args ;;
        "co") _gh_co $args ;;
        "main") _gh_main $args ;;
        
        *) _gh_help ;;
    esac
}

function _gh_clone() {
    local repos=($(_gh_get_repos))

    for repo in ${repos[@]}; do 
        echo "Cloning $repo..."
        git clone git@github.com:UKHSA-Internal/$repo.git $root/../$repo
        echo
    done
}

function _gh_main() {
    local repos=($(_gh_get_repos))

    for repo in ${repos[@]}; do 
        echo "Switching to main in $repo"
        cd $root/../$repo
        git checkout main
        echo
        echo "Pulling latest changes..."
        git pull --ff-only
        echo
    done

    cd $root
}

function _gh_co() {
    local repo=$1
    local pr=$2

    if [[ -z ${repo} ]]; then
        echo "Repo is required" >&2
        return 1
    fi

    if [[ -z ${pr} ]]; then
        echo "PR is required" >&2
        return 1
    fi

    echo "Checking out PR #$pr in data-dashboard-$repo"

    cd $root/../data-dashboard-$repo
    gh co $pr

    cd $root 

}

function _gh_get_repos() {
    local repos=("data-dashboard-api"
                 "data-dashboard-frontend" 
                 "data-dashboard-infra")
    
    echo ${repos[@]}
}



