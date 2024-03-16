#!/usr/bin/env bash
# Functions to work with Kubernetes cluster installed as addons
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_metrics_server_api_raw_info() {
  kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq .
}
