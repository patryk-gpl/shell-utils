#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Kubernetes cronjobs
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

## Cronjobs / jobs
alias kube_delete_jobs_with_success_status="kubectl delete jobs --field-selector status.successful=1"

kube_show_cronjobs_by_policy() {
  kubectl get cronjobs.batch --all-namespaces -o custom-columns="CronJob:.metadata.name,ConcurrencyPolicy:.spec.concurrencyPolicy"
}
