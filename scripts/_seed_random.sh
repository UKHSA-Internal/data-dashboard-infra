#!/bin/bash

function _seed_random_help() {
    echo
    echo "uhd seed-random [options]"
    echo
    echo "Generates random metric ingestion JSON for one topic configuration and uploads to the target environment ingest bucket via S3."
    echo "This command does NOT write directly to any database."
    echo
    echo "Required options:"
    echo "  --target <workspace>           Personal dev workspace name (e.g. abcd1234)"
    echo "  --data-type <headline|timeseries>"
    echo "  --topic <value>"
    echo "  --theme <value>"
    echo "  --sub-theme <value>"
    echo "  --geography <value>"
    echo "  --geography-type <value>"
    echo "  --metric-name <value>"
    echo "  --metric-min <number>"
    echo "  --metric-max <number>"
    echo
    echo "Optional options:"
    echo "  --points <int>                 Number of points (default: 30)"
    echo "  --geography-code <value>       Default: E92000001"
    echo "  --metric-group <value>         Default: generated"
    echo "  --include-null-points <bool>   true/false (default: false)"
    echo "  --include-erroneous-points <bool> true/false (default: false)"
    echo "  --include-non-public-points <bool> true/false (default: false)"
    echo "  --non-public-mode <some|all>   Default: some"
    echo "  --relative-span \"<n> <unit>\"   e.g. \"3 years\", \"90 days\" (default: 1 year)"
    echo "  --start-date YYYY-MM-DD        Use with --end-date"
    echo "  --end-date YYYY-MM-DD          Use with --start-date"
    echo "  --seed <int>                   Deterministic generation seed"
    echo "  --dry-run                      Generate locally only, no S3 upload"
    echo "  help                           Show this help"
    echo
    echo "Examples:"
    echo "  uhd seed-random --target abcd1234 --data-type timeseries --topic \"COVID-19\" --theme infectious_disease --sub-theme respiratory --geography England --geography-type Nation --metric-name covid_cases_rate --metric-min 0 --metric-max 100 --points 120 --relative-span \"3 years\" --seed 42"
    echo "  uhd seed-random --target abcd1234 --data-type headline --topic \"Flu\" --theme infectious_disease --sub-theme respiratory --geography England --geography-type Nation --metric-name flu_headline --metric-min 5 --metric-max 25 --start-date 2025-01-01 --end-date 2025-06-30 --include-null-points true --include-erroneous-points true --include-non-public-points true --dry-run"
    echo
    return 0
}

function _seed_random_validate_bool() {
    local input="$1"
    case "${input}" in
        true|false) echo "${input}" ;;
        *)
            echo "Boolean options must be true or false. Got '${input}'." >&2
            return 1
            ;;
    esac
}

function _seed_random_normalize_workspace() {
    local target="$1"
    if [[ "${target}" == uhd-* ]]; then
        echo "${target#uhd-}"
        return 0
    fi
    echo "${target}"
}

function _seed_random_assert_personal_dev_workspace() {
    local workspace="$1"

    if [[ ! "${workspace}" =~ ^[a-z0-9-]+$ ]]; then
        echo "Invalid target workspace '${workspace}'. Use lowercase letters, numbers, and hyphens only." >&2
        return 1
    fi

    if (( ${#workspace} > 14 )); then
        echo "Invalid target workspace '${workspace}'. Maximum length is 14 characters." >&2
        return 1
    fi

    case "${workspace}" in
        dev|dpd|test|uat|staging|prod|perf|pen|shared|default)
            echo "Blocked target '${workspace}'. Only personal dev workspaces are allowed." >&2
            return 1
            ;;
    esac

    if [[ "${workspace}" == ci-* ]] || [[ "${workspace}" == etl-ci-* ]] || [[ "${workspace}" == auth-* ]] || [[ "${workspace}" == *shared* ]]; then
        echo "Blocked target '${workspace}'. This command can only run for personal dev workspaces." >&2
        return 1
    fi
}

function _seed_random_sanitize_metric_token() {
    local input="$1"
    local sanitized
    sanitized=$(echo "${input}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_')
    sanitized="${sanitized##_}"
    sanitized="${sanitized%%_}"
    if [[ -z "${sanitized}" ]]; then
        sanitized="metric"
    fi
    echo "${sanitized}"
}

function _seed_random_geography_type_token() {
    local geography_type="$1"
    local lowered="${geography_type,,}"
    case "${lowered}" in
        nation|country) echo "CTRY" ;;
        region) echo "RGN" ;;
        utla) echo "UTLA" ;;
        ltla) echo "LTLA" ;;
        *)
            echo "${geography_type}" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-8
            ;;
    esac
}

function _seed_random() {
    if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        _seed_random_help
        return 0
    fi

    local target=""
    local points="30"
    local data_type=""
    local topic=""
    local theme=""
    local sub_theme=""
    local geography=""
    local geography_type=""
    local geography_code="E92000001"
    local metric_name=""
    local metric_group="generated"
    local include_null_points="false"
    local include_erroneous_points="false"
    local include_non_public_points="false"
    local non_public_mode="some"
    local relative_span=""
    local start_date=""
    local end_date=""
    local metric_min=""
    local metric_max=""
    local seed=""
    local dry_run="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target=*) target="${1#*=}"; shift ;;
            --points=*) points="${1#*=}"; shift ;;
            --data-type=*) data_type="${1#*=}"; shift ;;
            --topic=*) topic="${1#*=}"; shift ;;
            --theme=*) theme="${1#*=}"; shift ;;
            --sub-theme=*) sub_theme="${1#*=}"; shift ;;
            --geography=*) geography="${1#*=}"; shift ;;
            --geography-type=*) geography_type="${1#*=}"; shift ;;
            --geography-code=*) geography_code="${1#*=}"; shift ;;
            --metric-name=*) metric_name="${1#*=}"; shift ;;
            --metric-group=*) metric_group="${1#*=}"; shift ;;
            --include-null-points=*) include_null_points="${1#*=}"; shift ;;
            --include-erroneous-points=*) include_erroneous_points="${1#*=}"; shift ;;
            --include-non-public-points=*) include_non_public_points="${1#*=}"; shift ;;
            --non-public-mode=*) non_public_mode="${1#*=}"; shift ;;
            --relative-span=*) relative_span="${1#*=}"; shift ;;
            --start-date=*) start_date="${1#*=}"; shift ;;
            --end-date=*) end_date="${1#*=}"; shift ;;
            --metric-min=*) metric_min="${1#*=}"; shift ;;
            --metric-max=*) metric_max="${1#*=}"; shift ;;
            --seed=*) seed="${1#*=}"; shift ;;
            --dry-run) dry_run="true"; shift ;;
            --include-null-points) include_null_points="true"; shift ;;
            --include-erroneous-points) include_erroneous_points="true"; shift ;;
            --include-non-public-points) include_non_public_points="true"; shift ;;
            --target|--points|--data-type|--topic|--theme|--sub-theme|--geography|--geography-type|--geography-code|--metric-name|--metric-group|--non-public-mode|--relative-span|--start-date|--end-date|--metric-min|--metric-max|--seed)
                local opt="$1"
                shift
                if [[ $# -eq 0 ]]; then
                    echo "Missing value for ${opt}" >&2
                    return 1
                fi
                case "${opt}" in
                    --target) target="$1" ;;
                    --points) points="$1" ;;
                    --data-type) data_type="$1" ;;
                    --topic) topic="$1" ;;
                    --theme) theme="$1" ;;
                    --sub-theme) sub_theme="$1" ;;
                    --geography) geography="$1" ;;
                    --geography-type) geography_type="$1" ;;
                    --geography-code) geography_code="$1" ;;
                    --metric-name) metric_name="$1" ;;
                    --metric-group) metric_group="$1" ;;
                    --non-public-mode) non_public_mode="$1" ;;
                    --relative-span) relative_span="$1" ;;
                    --start-date) start_date="$1" ;;
                    --end-date) end_date="$1" ;;
                    --metric-min) metric_min="$1" ;;
                    --metric-max) metric_max="$1" ;;
                    --seed) seed="$1" ;;
                esac
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Run: uhd seed-random help" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "${target}" ]]; then
        echo "--target is required" >&2
        return 1
    fi

    local workspace
    workspace=$(_seed_random_normalize_workspace "${target}")
    _seed_random_assert_personal_dev_workspace "${workspace}" || return 1

    if [[ ! "${points}" =~ ^[0-9]+$ ]] || [[ "${points}" -le 0 ]]; then
        echo "--points must be a positive integer." >&2
        return 1
    fi

    case "${data_type}" in
        headline|timeseries) ;;
        *)
            echo "--data-type must be one of: headline, timeseries" >&2
            return 1
            ;;
    esac

    for required_value in topic theme sub_theme geography geography_type metric_name metric_min metric_max; do
        if [[ -z "${!required_value}" ]]; then
            echo "--${required_value//_/-} is required" >&2
            return 1
        fi
    done

    include_null_points=$(_seed_random_validate_bool "${include_null_points}") || return 1
    include_erroneous_points=$(_seed_random_validate_bool "${include_erroneous_points}") || return 1
    include_non_public_points=$(_seed_random_validate_bool "${include_non_public_points}") || return 1

    case "${non_public_mode}" in
        some|all) ;;
        *)
            echo "--non-public-mode must be one of: some, all" >&2
            return 1
            ;;
    esac

    if [[ -n "${seed}" ]] && ! [[ "${seed}" =~ ^[0-9]+$ ]]; then
        echo "--seed must be an integer" >&2
        return 1
    fi

    if [[ -n "${relative_span}" ]] && ([[ -n "${start_date}" ]] || [[ -n "${end_date}" ]]); then
        echo "Use either --relative-span OR --start-date/--end-date, not both." >&2
        return 1
    fi

    if [[ -n "${start_date}" ]] && [[ -z "${end_date}" ]]; then
        echo "--end-date is required when --start-date is provided." >&2
        return 1
    fi

    if [[ -n "${end_date}" ]] && [[ -z "${start_date}" ]]; then
        echo "--start-date is required when --end-date is provided." >&2
        return 1
    fi

    local generator_script="$root/scripts/_seed_random_generate.py"
    if [[ ! -f "${generator_script}" ]]; then
        echo "Missing generator script: ${generator_script}" >&2
        return 1
    fi

    local timestamp
    timestamp=$(date +%Y%m%dT%H%M%S)
    local run_dir="$root/tmp/seed-random/${workspace}/${timestamp}"
    local metric_token
    metric_token=$(_seed_random_sanitize_metric_token "${metric_name}")
    local geo_type_token
    geo_type_token=$(_seed_random_geography_type_token "${geography_type}")
    if [[ -z "${geo_type_token}" ]]; then
        geo_type_token="GEO"
    fi
    local output_file="${run_dir}/${metric_token}_${geo_type_token}_${geography_code}_all_all_default.json"

    local python_cmd=("python3")
    if ! command -v python3 >/dev/null 2>&1; then
        if command -v python >/dev/null 2>&1; then
            python_cmd=("python")
        else
            echo "Python is required but was not found on PATH." >&2
            return 1
        fi
    fi

    local generator_args=(
        "${generator_script}"
        "--output-file" "${output_file}"
        "--points" "${points}"
        "--data-type" "${data_type}"
        "--topic" "${topic}"
        "--theme" "${theme}"
        "--sub-theme" "${sub_theme}"
        "--geography" "${geography}"
        "--geography-type" "${geography_type}"
        "--geography-code" "${geography_code}"
        "--metric-name" "${metric_name}"
        "--metric-group" "${metric_group}"
        "--include-null-points" "${include_null_points}"
        "--include-erroneous-points" "${include_erroneous_points}"
        "--include-non-public-points" "${include_non_public_points}"
        "--non-public-mode" "${non_public_mode}"
        "--metric-min" "${metric_min}"
        "--metric-max" "${metric_max}"
    )

    if [[ -n "${relative_span}" ]]; then
        generator_args+=("--relative-span" "${relative_span}")
    fi
    if [[ -n "${start_date}" ]]; then
        generator_args+=("--start-date" "${start_date}")
    fi
    if [[ -n "${end_date}" ]]; then
        generator_args+=("--end-date" "${end_date}")
    fi
    if [[ -n "${seed}" ]]; then
        generator_args+=("--seed" "${seed}")
    fi

    "${python_cmd[@]}" "${generator_args[@]}" || return 1

    echo "Generated ingestion file: ${output_file}"

    if [[ "${dry_run}" == "true" ]]; then
        echo "Dry run enabled. No upload performed."
        echo "Dry-run output directory: ${run_dir}"
        return 0
    fi

    echo "Resolving terraform outputs for workspace '${workspace}'..."
    uhd terraform output "${workspace}" || return 1

    echo "Uploading generated file(s) via: uhd data upload ${run_dir}"
    uhd data upload "${run_dir}" || return 1

    local ingest_bucket
    ingest_bucket=$(_get_ingest_bucket_id)
    echo "Upload complete to s3://${ingest_bucket}/in/"
}
