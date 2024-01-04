#!/bin/bash

root=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

for script_file in "$root"/scripts/_*.sh; do
    source $script_file
done

function _uhd_commands_help() {

    echo 
    echo "                    █░█ █▄▀ █░█ █▀ ▄▀█ "
    echo "                    █▄█ █░█ █▀█ ▄█ █▀█ "
    echo 
    echo "    █▀▄ ▄▀█ ▀█▀ ▄▀█   █▀▄ ▄▀█ █▀ █░█ █▄▄ █▀█ ▄▀█ █▀█ █▀▄ "
    echo "    █▄▀ █▀█ ░█░ █▀█   █▄▀ █▀█ ▄█ █▀█ █▄█ █▄█ █▀█ █▀▄ █▄▀ "
    echo 
    echo "                        █▀▀ █░░ █"
    echo "                        █▄▄ █▄▄ █"
    echo
    echo "               UKHSA Data Dashboard CLI Tool" 
    echo
    echo "uhd <command> [options]"
    echo
    echo "commands:"
    echo "  help        - this help screen"
    echo
    echo "  aws         - aws commands"
    echo "  cache       - cache commands"
    echo "  data        - upload and ingest metric data"
    echo "  docker      - docker commands"
    echo "  ecs         - ecs commands"
    echo "  lambda      - lambda commands"
    echo "  gh          - github commands"
    echo "  terraform   - terraform commands"
    echo
    echo "  update      - update all the things - infra, containers, etc"
    echo

    return 0
}

function uhd() {
    if [ $CI ]; then
        echo $0 $@
    fi

    local current=$(pwd)
    local command=$1
    local args=(${@:2}) 

    cd $root

    case $command in
        "aws") _aws $args ;;
        "cache") _cache $args ;;
        "data") _data $args ;;
        "docker") _docker $args ;;
        "ecs") _ecs $args ;;
        "lambda") _lambda $args ;;
        "gh") _gh $args ;;
        "terraform") _terraform $args ;;
        "update") _update $args ;;

        *) _uhd_commands_help ;;
    esac

    local exit_code=$?

    cd $current

    return $exit_code
}

echo
echo "uhd cli loaded"
echo
echo "Type uhd for the help screen"
echo

return 0