#!/bin/bash

root=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)

for script_file in "$root"/scripts/*.sh; do
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
    echo "  terraform   - terraform commands"
    echo

    return 1
}

function uhd() {
    if [ "$RUNNING_IN_CI" = "1" ]; then
        echo $0 $@
    fi

    local current=$(pwd)
    local command=$1

    cd $root

    case $command in
        "aws") _aws "${@:2}" ;;
        "terraform") _terraform "${@:2}" ;;

        *) _uhd_commands_help ;;
    esac

    cd $current
}

echo "Usage: uhd"