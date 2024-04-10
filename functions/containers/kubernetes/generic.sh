#!/usr/bin/env bash
# Functions to work with Kubernetes (generic)

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

_kube_get_namespace() {
  local namespace="$1"
  if [ -z "$namespace" ]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo "No namespace provided, using current context namespace: $namespace"
  else
    echo "Using namespace: $namespace"
  fi
}

## Generic
kube_resources_get_all() {
  local namespace && namespace=$(_kube_get_namespace "$1")
  shift

  echo "== Show all resources created in namespace: $namespace"
  kubectl api-resources --verbs=list --namespaced -o name |
    xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$namespace" "$@"
}

## Run command on multiple namespace at once within the same cluster
kube_cmd_run_in_multiple_namespaces() {
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

kube_resource_get_by_name_in_all_namespaces() {
  local recourceName="$1"

  if [[ -z "$recourceName" ]]; then
    echo "Usage: ${FUNCNAME[0]} <recourceName>"
  else
    kubectl get "$recourceName" --all-namespaces \
      -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace
  fi
}

# kube_cmd_clusters - Run the same command on different Kubernetes clusters.
#
# Usage: kube_cmd_clusters <kubectl_command>
#
# Allow running the provided kubectl_command on multiple Kubernetes clusters.
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
kube_cmd_run_in_multiple_clusters() {
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
