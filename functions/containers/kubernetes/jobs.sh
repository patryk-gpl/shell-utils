#!/usr/bin/env bash
# Functions to work with Kubernetes (jobs)

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_jobs_remove_completed() {
  local namespace="$1"
  if [ -z "$namespace" ]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo "No namespace provided, using current context namespace: $namespace"
  else
    echo "Using namespace: $namespace"

  fi
  jobs=$(kubectl get job -o=jsonpath='{.items[?(@.status.succeeded==1)].metadata.name}' -n "$namespace")
  if [ -z "$jobs" ]; then
    echo "No completed jobs found in namespace: $namespace. Skipping..."
    return 0
  else
    echo "Removing completed jobs in namespace: $namespace"
    for job in $jobs; do
      kubectl delete job "$job" -n "$namespace"
    done
  fi
}
