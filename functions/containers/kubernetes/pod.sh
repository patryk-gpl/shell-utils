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

function kube_pods_describe_all() {
  namespace=$1
  if [ -z "$namespace" ]; then
    echo "Usage: kube_pods_describe_all <namespace>"
    return 1
  fi

  local filename="podsDescribeAll-${namespace}.log"
  echo "== Processing pod descriptions for namespace $namespace ==" | tee "$filename"
  pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}')

  for pod in $pods; do
    echo "Describe pod $pod in namespace $namespace"
    echo "========================================" >>"$filename"
    kubectl describe pod "$pod" -n "$namespace" >>"$filename"
  done
}

kube_pods_delete_all() {
  local namespace="$1"
  if [[ -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace>"
  else
    kubectl delete pods --all -n "$namespace"
  fi
}

kube_pods_get_by_age() {
  local namespace=${1:-default}
  kubectl get pod --namespace "$namespace" --sort-by=.metadata.creationTimestamp
}

kube_pods_get_termination_reason() {
  reason=$1
  kubectl get pod "$reason" -o go-template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"
}

kube_pods_get_failed() {
  kubectl get pods --field-selector=status.phase=Failed "$@"
}

kube_pods_show_total_by_namespace() {
  kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace' | sort | uniq -c | sort -rn
}
