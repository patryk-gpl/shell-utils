#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Kubernetes
####################################################################################################

source "$(dirname "$(dirname "$0")")/shared.sh"
prevent_to_execute_directly

# Show the current namespace name
kube_ns_current() {
  kubectl config view --minify --output 'jsonpath={..namespace}'
}

# List all images used in the current namespace
kube_image_list_names_from_pods() {
  namespace=${1:-$(kube_ns_current)}

  kubectl get pods -n "$namespace" -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" | sort -u
}

# List all images used in all namespaces
kube_image_list_names_from_pods_all_namespaces() {
  kubectl get pods -A -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" | sort -u
}
