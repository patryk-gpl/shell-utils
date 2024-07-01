#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_config_get_contexts() {
  echo "Available Kubernetes contexts:"
  kubectl config get-contexts -o name | sort | sed 's/^/  /'
}
