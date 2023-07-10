#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with kustomize
####################################################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
prevent_to_execute_directly

kust_apply() {
  kustomize build | kubectl apply -f -
}

kust_delete() {
  kustomize build | kubectl delete -f -
}
