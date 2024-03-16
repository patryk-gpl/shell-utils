#!/usr/bin/env bash
# Functions to work with Kubernetes pods

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# List all images used in the current namespace
kube_list_image_names_from_pods() {
  kubectl get pods -n "$namespace" -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" "$@" | sort -u
}

kube_get_logs_from_pod_containers_with_filter() {
  local pod_name="$1"
  local namespace="$2"
  local filter="$3"

  if [[ -z "$pod_name" || -z "$namespace" || -z "$filter" ]]; then
    echo "Usage: ${FUNCNAME[0]} <pod_name> <namespace> <filter>"
    return 1
  fi

  local containers
  containers=$(kubectl get pod "$pod_name" -n "$namespace" -o=jsonpath='{.spec.containers[*].name}')

  for container in $containers; do
    echo -e "${GREEN}== Logs for container $container in pod $pod_name ==${RESET}"
    kubectl logs -n "$namespace" "$pod_name" -c "$container" | grep -E -i "$filter"
  done
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

kube_show_pods_total_by_namespace() {
  kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace'  | sort | uniq -c | sort -rn
}
