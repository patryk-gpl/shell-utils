#!/usr/bin/env bash
# Functions to work with Github repositories

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

gh_delete_disabled_workflows_history() {
  if [[ -z $1 || -z $2 ]]; then
    echo "Please provide the organization and repository names as arguments."
    return 1
  fi

  org="$1"
  repo="$2"

  echo "Show all workflows"
  gh workflow list -a -R "$org/$repo"

  mapfile -t workflow_ids < <(gh api "repos/$org/$repo/actions/workflows" --paginate | jq -r '.workflows[] | select(.state | contains("disabled_manually")) | .id')
  for workflow_id in "${workflow_ids[@]}"; do
    echo "Listing runs for the workflow ID $workflow_id"
    mapfile -t run_ids < <(gh api "repos/$org/$repo/actions/workflows/$workflow_id/runs" --paginate | jq -r '.workflow_runs[].id')
    for run_id in "${run_ids[@]}"; do
      echo "Deleting Run ID $run_id"
      gh api "repos/$org/$repo/actions/runs/$run_id" -X DELETE >/dev/null &
    done
  done

  # Wait for all background processes to finish
  wait
}
