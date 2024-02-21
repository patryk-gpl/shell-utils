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

## Check validitiy of the TLS/SSL certificate stored in the K8S secret
kube_secret_check_cert_expiry() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: kube_secret_check_cert_expiry <secret-name> <namespace>"
    return 1
  fi

  local secret_name=$1
  local namespace=$2
  kubectl get secret "$secret_name" -n "$namespace" -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509 -noout -enddate
}

## Run command on multiple namespace at once within the same cluster
kube_cmd_many_ns() {
  if [ "$#" -lt 2 ]; then
    echo "Error: Invalid number of parameters. Usage: kube_cmd_many <kubectl_command> <namespace1> [<namespace2> ...]"
    return 1
  fi

  local kubectl_cmd=$1
  shift
  local namespaces=("$@")

  for namespace in "${namespaces[@]}"; do
    echo "Running command '$kubectl_cmd' against namespace '$namespace'"
    kubectl --namespace "$namespace" "$kubectl_cmd"
    echo
  done
}

# kube_cmd_clusters - Run the same command on different Kubernetes clusters.
#
# Usage: kube_cmd_clusters <kubectl_command>
#
# This function allows running the provided kubectl_command on multiple Kubernetes clusters.
# It reads the cluster names from a configuration file located at $HOME/.kube/clusters.conf.
# Each cluster name should be defined as a key-value pair in the INI format, with one cluster per line.
#
# Example ~/.kube/clusters.conf:
# [qa]
# cluster_name = cluster-qa
#
# [prod]
# cluster_name = cluster-prod
#
# Parameters:
#   <kubectl_command> - The kubectl command to run on each cluster.
#                      Make sure to enclose it in quotes if it contains spaces or special characters.
kube_cmd_clusters() {
  local kubectl_cmd=( "$@" )
  local config_file="$HOME/.kube/clusters.conf"

  if [ ! -f "$config_file" ]; then
    echo "Error: Config file '$config_file' not found."
    return 1
  fi

  if [ -z "${kubectl_cmd[*]}" ]; then
    echo "Error: No command provided. Usage: kube_cmd_clusters <kubectl_command>"
    return 1
  fi

  while IFS='=' read -r key raw_cluster_name; do
    if [[ -n $key && -n $raw_cluster_name ]]; then
      cluster_name=$(echo "$raw_cluster_name" | tr -d '[:space:]')
      echo "Running command '$kubectl_cmd' on cluster '$cluster_name'"
      bash -c "kubectl --context='$cluster_name' $kubectl_cmd"
      echo
    fi
  done < "$config_file"
}


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

kube_get_resource_with_custom_column_namespace() {
  local recourceName="$1"

  if [[ -z "$recourceName" ]]; then
    echo "Usage: ${FUNCNAME[0]} <recourceName>"
  else
    kubectl get "$recourceName" --all-namespaces \
      -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace
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
  local namespace=${1:-$(kubectl config view --minify --output 'jsonpath={..namespace}')}
  local rs
  rs=$(kubectl get rs -n "$namespace" --no-headers | awk '{if ($2 + $3 + $4 == 0) print $1}')

  if [ -z "$rs" ]; then
    echo "No resources found to clean in $namespace namespace."
  else
    # shellcheck disable=SC2086
    kubectl delete rs $rs -n "$namespace"
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

kube_show_pods_total_by_namespace() {
  kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace'  | sort | uniq -c | sort -rn
}

kube_show_cronjobs_by_policy() {
  kubectl get cronjobs.batch --all-namespaces -o custom-columns="CronJob:.metadata.name,ConcurrencyPolicy:.spec.concurrencyPolicy"
}
