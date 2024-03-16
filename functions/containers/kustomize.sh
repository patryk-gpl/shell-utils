#!/usr/bin/env bash
# Functions to work with kustomize

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

kust_apply() {
  kustomize build | kubectl apply -f -
}

kust_delete() {
  kustomize build | kubectl delete -f -
}
