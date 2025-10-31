#!/bin/bash

function _rds_help() {
    echo
    echo "uhd rds <command> [options]"
    echo
    echo "commands:"
    echo "  help                                          - this help screen"
    echo 
    echo "  remove-deletion-protection <cluster-id>       - removes deletion protection and allows the cluster to be deleted"
    echo "  remove-deletion-protection-current-clusters   - removes deletion protection from all current clusters"
    echo

    return 0
}

function _rds() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "remove-deletion-protection") _rds_remove_deletion_protection $args ;;
        "remove-deletion-protection-current-clusters") _rds_remove_deletion_protection_current_clusters ;;

        *) _rds_help ;;
    esac
}

function _rds_remove_deletion_protection() {
    local cluster_id=$1

    if [[ -z ${cluster_id} ]]; then
        echo "DB cluster ID is required" >&2
        return 1
    fi

    echo "Removing deletion protection for Aurora DB cluster '${cluster_id}'..."

    aws rds modify-db-cluster \
      --db-cluster-identifier "${cluster_id}" \
      --apply-immediately \
      --no-deletion-protection \
      --no-cli-pager
}

function _rds_remove_deletion_protection_current_clusters() {
  local current_main_db_cluster_id=$(_get_current_main_db_cluster_id)
  local current_feature_flags_db_cluster_id=$(_get_current_feature_flags_db_cluster_id)

  _rds_remove_deletion_protection "${current_main_db_cluster_id}"
  _rds_remove_deletion_protection "${current_feature_flags_db_cluster_id}"
}

function _get_current_main_db_cluster_id() {
    local terraform_output_file=terraform/20-app/output.json
    local main_db_cluster_id=$(jq -r '.rds.value.main_db_cluster_id'  $terraform_output_file)
    echo "$main_db_cluster_id"
}

function _get_current_feature_flags_db_cluster_id() {
    local terraform_output_file=terraform/20-app/output.json
    local feature_flags_db_cluster_id=$(jq -r '.rds.value.feature_flags_db_cluster_id'  $terraform_output_file)
    echo "$feature_flags_db_cluster_id"
}
