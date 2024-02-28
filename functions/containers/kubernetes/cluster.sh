#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Kubernetes cluster global operations
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

## Namespaces
alias kube_get_ns_sorted_by_name="kubectl get ns --sort-by={.metadata.name}"

kube_ns_current() {
  kubectl config view --minify --output 'jsonpath={..namespace}'
}

## Nodes
kube_show_container_runtime_version() {
  kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' | sort | uniq -c
}
