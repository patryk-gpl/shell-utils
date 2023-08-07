#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Kubernetes
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly


## Namespaces
alias kube_get_ns_sorted_by_name="kubectl get ns --sort-by={.metadata.name}"

kube_ns_current() {
  kubectl config view --minify --output 'jsonpath={..namespace}'
}

## Pods
alias kube_get_pods_by_age_all_namespaces="kubectl get pod --sort-by=.metadata.creationTimestamp -A"

# List all images used in the current namespace
kube_image_list_names_from_pods() {
  namespace=${1:-$(kube_ns_current)}

  kubectl get pods -n "$namespace" -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" | sort -u
}

# List all images used in all namespaces
kube_image_list_names_from_pods_all_namespaces() {
  kubectl get pods -A -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" | sort -u
}

kube_dump_all_logs_from_pods() {
  local pods
  local namespace="$1"
  pods=$(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name")

  for pod in $pods; do
    kubectl logs -n "$namespace" "$pod" > "${pod}.log"
    echo "Logs for pod $pod dumped to ${pod}.log"
  done
}

kube_delete_all_pods() {
  local namespace="$1"
  if [[ -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace>"
  else
    kubectl delete pods --all -n "$namespace"
  fi
}

kube_get_pods_by_age() {
  local namespace=${1:-default}
  kubectl get pod --namespace "$namespace" --sort-by=.metadata.creationTimestamp
}

kube_get_pod_termination_reason() {
  reason=$1
  kubectl get pod "$reason" -o go-template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"
}

kube_get_pod_failed() {
  kubectl get pods --field-selector=status.phase=Failed "$@"
}

## Nodes

# Show a container runtime version of the current cluster
kube_show_container_runtime_version() {
  kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' | sort | uniq -c
}

## Deployments / Replica Sets

kube_delete_replica_sets() {
  namespace=${1:-$(kubectl config view --minify --output 'jsonpath={..namespace}')}
  rs=$(kubectl get rs -n "$namespace" --no-headers | awk '{if ($2 + $3 + $4 == 0) print $1}')
  if [ -z "$rs" ]; then
    echo "No resources found to clean in $namespace namespace."
  else
    kubectl delete rs "$rs" -n "$namespace"
  fi
}

kube_delete_replica_sets_all_namespaces() {
  for ns in $(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}'); do
    if kubectl get rs -n "$ns" >/dev/null 2>&1; then
      kube_delete_replica_sets "$ns"
    else
      echo "No resources found to clean in $ns namespace."
    fi
  done
}

## Cronjobs / jobs
alias kube_delete_jobs_with_success_status="kubectl delete jobs --field-selector status.successful=1"

## Generic
alias kube_get_events_all="kubectl get events --sort-by=.metadata.creationTimestamp"
alias kube_get_events_with_warn="kubectl get events --field-selector type=Warning --sort-by=.metadata.creationTimestamp"

alias kube_get_status_metric_server="kubectl get --raw '/apis/metrics.k8s.io/v1beta1/nodes' | jq ."

kube_get_all_resources() {
  namespace=${1:-default}
  shift
  echo "== Show all resources created in namespace: $namespace"
  kubectl api-resources --verbs=list --namespaced -o name |
    xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$namespace" "$@"
}
