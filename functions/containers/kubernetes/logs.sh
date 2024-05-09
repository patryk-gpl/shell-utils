#!/usr/bin/env bash
# Functions to work with Kubernetes logs

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_logs_dump_from_pod_containers_with_filter() {
  local namespace="$1"
  local pod_name="$2"
  local filter="$3"

  if [[ -z "$pod_name" || -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace> <pod_name> [filter]"
    return 1
  fi

  local containers
  containers=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.spec.containers[*].name} {.spec.initContainers[*].name}')

  for container in $containers; do
    echo -e "${GREEN}== Logs for container $container in pod $pod_name ==${RESET}"
    if [[ -n "$filter" ]]; then
      kubectl logs -n "$namespace" "$pod_name" -c "$container" | grep -E -i "$filter"
    else
      kubectl logs -n "$namespace" "$pod_name" -c "$container"
    fi
  done
}

kube_logs_dump_from_all_pods() {
  local namespace="$1"

  if [[ -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace>"
    return 1
  fi

  local pods
  pods=$(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name")

  for pod in $pods;
  do
    echo "Dumping logs for pod $pod, namespace $namespace..."
    containers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name} {.spec.initContainers[*].name}')
    for container in $containers
    do
      kubectl logs -n "$namespace" "$pod" -c "$container" > "$namespace_$pod_${container}.log"
    done
  done
}
