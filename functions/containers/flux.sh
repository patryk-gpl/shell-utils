#!/usr/bin/env bash
# This file contains functions to work with Flux v2

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

flux_list_all_active_resources() {
  local flux_resources
  local namespace="$1"
  flux_resources=$(kubectl api-resources --verbs=list -o name | awk '/flux/' | paste -sd "," -)

  kubectl get "$flux_resources" -n "$namespace"
}
