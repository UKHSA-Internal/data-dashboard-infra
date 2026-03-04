#!/bin/bash

function _seed_random_help() {
    echo
    echo "uhd seed-random [options]"
    echo
    echo "Runs the API 'seed_random' Django management command as an ECS task in the target personal dev environment."
    echo
    echo "Examples:"
    echo "  uhd seed-random --target=uhd-dev --dataset=metrics --scale=small --truncate-first --yes"
    echo "  uhd seed-random --target uhd-abcd --dataset both --scale medium --seed 1234 --truncate-first --yes"
    echo
    echo "Options:"
    echo "  --target <name>           Required. Personal dev env name. Must start with 'uhd-'."
    echo "  --dataset <cms|metrics|both>   Default: both"
    echo "  --scale <small|medium|large>  Default: small"
    echo "  --seed <int>              Optional. If omitted, API command will generate one and print it."
    echo "  --truncate-first          Optional. Deletes existing seeded metrics data before seeding."
    echo "  --yes                     Required in non-interactive mode when using --truncate-first."
    echo "  help                      Show this help."
    echo
    echo "Notes:"
    echo "  - This runs in AWS (ECS). It does not use your local Postgres/Django."
    echo "  - Ensure you're logged into AWS first: uhd aws login uhd-dev"
    echo "  - Requires jq to be installed locally."
    echo
    return 0
}

function _seed_random() {
    # Allow: uhd seed-random help
    if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        _seed_random_help
        return 0
    fi

    local target=""
    local dataset="both"
    local scale="small"
    local seed=""
    local truncate_first=false
    local yes=false

    # Robust parsing: supports both --flag value and --flag=value
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target=*)  target="${1#*=}"; shift ;;
            --dataset=*) dataset="${1#*=}"; shift ;;
            --scale=*)   scale="${1#*=}"; shift ;;
            --seed=*)    seed="${1#*=}"; shift ;;

            --target)
                shift
                target="${1:-}"
                if [[ -z "$target" ]]; then
                    echo "Target is required" >&2
                    return 1
                fi
                shift
                ;;
            --dataset)
                shift
                dataset="${1:-}"
                if [[ -z "$dataset" ]]; then
                    echo "Dataset is required" >&2
                    return 1
                fi
                shift
                ;;
            --scale)
                shift
                scale="${1:-}"
                if [[ -z "$scale" ]]; then
                    echo "Scale is required" >&2
                    return 1
                fi
                shift
                ;;
            --seed)
                shift
                seed="${1:-}"
                if [[ -z "$seed" ]]; then
                    echo "Seed is required" >&2
                    return 1
                fi
                shift
                ;;
            --truncate-first)
                truncate_first=true
                shift
                ;;
            --yes)
                yes=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Run: uhd seed-random help" >&2
                return 1
                ;;
        esac
    done

    # Validate
    if [[ -z "${target}" ]]; then
        echo "--target is required" >&2
        return 1
    fi

    if [[ "${target}" != uhd-* ]]; then
        echo "Target must start with 'uhd-'" >&2
        return 1
    fi

    case "${dataset}" in
        cms|metrics|both) ;;
        *)
            echo "Dataset must be one of: cms, metrics, both" >&2
            return 1
            ;;
    esac

    case "${scale}" in
        small|medium|large) ;;
        *)
            echo "Scale must be one of: small, medium, large" >&2
            return 1
            ;;
    esac

    if [[ -n "${seed}" ]] && ! [[ "${seed}" =~ ^[0-9]+$ ]]; then
        echo "Seed must be an integer" >&2
        return 1
    fi

    # Confirmation for destructive action
    if [[ "${truncate_first}" == true ]] && [[ "${yes}" != true ]]; then
        if [[ -t 0 ]]; then
            read -r -p "--truncate-first will remove existing data before seeding. Continue? [y/N] " response
            if [[ ! "${response}" =~ ^[Yy]$ ]]; then
                echo "Cancelled."
                return 1
            fi
        else
            echo "--truncate-first requires --yes in non-interactive mode" >&2
            return 1
        fi
    fi

    # Ensure ECS job JSON is generated for this workspace/env
    uhd terraform output "${target}" || return 1

    local base_job_file="terraform/20-app/ecs-jobs/seed-random.json"
    if [[ ! -f "${base_job_file}" ]]; then
        echo "Missing ECS job file: ${base_job_file}" >&2
        echo "Did terraform output generate it? Check scripts/_terraform.sh output-file entries." >&2
        return 1
    fi

    # Use mktemp for portability (Git Bash/WSL/Linux)
    local temp_job_file
    temp_job_file="$(mktemp -t "seed-random-${target}.XXXXXX").json" || return 1

    # Build command override JSON
    local command_json
    command_json=$(jq -n \
        --arg dataset "${dataset}" \
        --arg scale "${scale}" \
        --arg seed "${seed}" \
        --arg truncate_first "${truncate_first}" \
        '["python","manage.py","seed_random","--dataset",$dataset,"--scale",$scale]
         + (if $seed != "" then ["--seed",$seed] else [] end)
         + (if $truncate_first == "true" then ["--truncate-first"] else [] end)'
    ) || return 1

    jq --argjson command "${command_json}" \
       '.overrides.containerOverrides[0].command = $command' \
       "${base_job_file}" > "${temp_job_file}" || return 1

    local current_cluster_name
    current_cluster_name=$(_get_current_cluster)
    if [[ -z "${current_cluster_name}" ]]; then
        echo "Failed to determine current ECS cluster name" >&2
        return 1
    fi

    echo "Starting seed-random ECS task in target=${target} (cluster=${current_cluster_name})..."
    local task_arn
    task_arn=$(aws ecs run-task --cli-input-json "file://${temp_job_file}" | jq -r ".tasks[0].taskArn")

    if [[ -z "${task_arn}" ]] || [[ "${task_arn}" == "null" ]]; then
        echo "Failed to start task" >&2
        echo "Tip: check AWS auth with: uhd aws whoami" >&2
        return 1
    fi

    echo "Task (${task_arn}) is now running, waiting for completion..."
    aws ecs wait tasks-stopped --tasks "${task_arn}" --cluster "${current_cluster_name}" || return 1

    # Flush caches after seeding
    uhd cache flush || return 1

    # Clean up temp file
    rm -f "${temp_job_file}" >/dev/null 2>&1 || true

    local seed_value="${seed:-none}"
    echo "Seed-random completed for target=${target}, dataset=${dataset}, scale=${scale}, seed=${seed_value}"
}