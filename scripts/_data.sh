#!/bin/bash

function _data_help() {
    echo
    echo "uhd data <command> [options]"
    echo
    echo "commands:"
    echo "  help           - this help screen"
    echo 
    echo "  upload [folder] - upload files to the ingest s3 bucket"
    echo "  ingest          - ingest files from s3"
    echo
    echo "  load [folder]   - upload files, ingest them, and flush the caches"

    return 0
}

function _data() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        
        *) _data_help ;;
    esac
}
