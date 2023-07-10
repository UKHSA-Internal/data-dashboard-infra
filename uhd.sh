#!/bin/bash

root=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

for script_file in "$root"/scripts/_*.sh; do
    source $script_file
done

function _uhd_commands_help() {
    echo
    echo UKHSA Dashboard CLI Tool 
    echo
    echo "uhd <command> [options]"
    echo
    echo "commands:"
    echo "  help        - this help screen"
    echo
    echo "  aws         - aws commands"
    echo "  docker      - docker commands"
    echo "  ecs         - ecs commands" 
    echo "  terraform   - terraform commands"
    echo

    return 1
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
        "docker") _docker $args ;;
        "ecs") _ecs $args ;;
        "terraform") _terraform $args ;;

        *) _uhd_commands_help ;;
    esac

    local exit_code=$?

    cd $current

    return $exit_code
}

echo "Usage: uhd"