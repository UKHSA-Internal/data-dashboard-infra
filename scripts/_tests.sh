#!/bin/bash

function _tests_help() {
    echo
    echo "uhd tests <command> [options]"
    echo
    echo "commands:"
    echo "  help                                        - this help screen"
    echo
    echo "  run-virtuoso-test-pack <token> <goal-id>    - run the virtuoso proof of concept test pack"

    return 0
}

function _tests() {
    local verb=$1
    local args=(${@:2})

    case $verb in
        "run-virtuoso-test-pack") _run_virtuoso_test_pack $args ;;

        *) _tests_help ;;
    esac
}

function _run_virtuoso_test_pack() {
  #-----------------------------#
  # Author: SpotQA
  # Contact: support@spotqa.com
  # Title: Example script for triggering Virtuoso APIs to execute journeys in a goal
  # Requirements: This script requires curl and jq to be installed.
  # Last modified: 23/02/2023
  #-----------------------------#


  if [[ $# -eq 0 ]]; then
      echo "Usage: ./execute.sh -t VIRTUOSO_TOKEN --goal_id ID_OF_GOAL_TO_EXECUTE [--app2] [--max_retry_time MAX_RETRY_TIME] [--retry_delay_time RETRY_DELAY_TIME]"
      exit 1
  fi

  # Check for support
  if ! type "jq" > /dev/null; then
    echo "jq needs to be installed. See: https://stedolan.github.io/jq/download/"
    exit 1
  fi

  if ! type "curl" > /dev/null; then
    echo "curl needs to be installed."
    exit 1
  fi

  ENV="api"
  UI="app"
  MAX_RETRY_TIME=300
  RETRY_DELAY_TIME=10

  TOKEN=$1
  GOAL_ID=$2

  # Launch execution
  echo "Going to execute goal $GOAL_ID"
  JOB_ID=$(curl -s --header "Authorization: Bearer $TOKEN" -X POST "https://$ENV.virtuoso.qa/api/goals/$GOAL_ID/execute?envelope=false" | jq -r .id)

  echo "Launched execution job $JOB_ID"

  # wait for job to complete
  echo "--------"
  RUNNING=true
  OUTCOME=""
  while $RUNNING; do
    ERROR=true
    RETRY_TIME=0;
    # As we poll for the status of the job, we need to ensure that a single API failure would not lead to failure of this entire script
    while $ERROR; do
      JOB=$(curl -s --fail --header "Authorization: Bearer $TOKEN" "https://$ENV.virtuoso.qa/api/executions/$JOB_ID/status?envelope=false")
      if [[ "$JOB" == "" ]]; then
          if [ $MAX_RETRY_TIME -gt $RETRY_TIME ]; then
            echo "Request failed. Retrying..."
            RETRY_TIME=$(($RETRY_TIME + $RETRY_DELAY_TIME))
            ERROR=true
            sleep $RETRY_DELAY_TIME
          else
            echo "Failed to get job status... Try to re-run the job again."
            exit 2
          fi
      else
        ERROR=false
      fi
    done

    JOB_STATUS=$(echo $JOB | jq -r .status)
    OUTCOME=$(echo $JOB | jq -r .outcome)

    echo "Job execution status: $JOB_STATUS, outcome: $OUTCOME"

    if [[ "$JOB_STATUS" == "FINISHED" ]] || [[ "$JOB_STATUS" == "CANCELED" ]] || [[ "$JOB_STATUS" == "FAILED" ]]; then
      RUNNING=false
    else
      sleep 2
    fi
  done

  echo "--------"
  echo "Executed job $JOB_ID with outcome: $OUTCOME"

  # Save execution result
  curl -s --header "Authorization: Bearer $TOKEN" "https://$ENV.virtuoso.qa/api/jobs/$JOB_ID/status?envelope=false" | jq -r '.' > "execution_report.json"
  curl -s --header "Authorization: Bearer $TOKEN" "https://$ENV.virtuoso.qa/api/goals/$GOAL_ID?envelope=false" | jq -r '.' > "goal.json"

  echo "Exported tests and the report as tests.json, execution_report.json and goal.json"
  echo "Execution link: https://$UI.virtuoso.qa/#/project/execution/$JOB_ID"

  # Different exit code for when job did not fail/error but status was not finished (cancelled/failed)
  if [[ "$JOB_STATUS" != "FINISHED" ]]; then
  fi

  # terminate unsuccessfully if job did not pass
  if [[ "$OUTCOME" == "FAIL" ]] || [[ "$OUTCOME" == "ERROR" ]]; then
  fi

  echo "Done!"

}
