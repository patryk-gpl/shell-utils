#!/usr/bin/env bash
# This file contains functions to work with Minikube

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

alias minikube_show_k8s_versions="minikube config defaults kubernetes-version"

minikube_reset() {
  minikube delete --all
  minikube start
}
