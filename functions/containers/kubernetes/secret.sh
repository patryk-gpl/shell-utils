#!/usr/bin/env bash
# Functions to work with Kubernetes secrets

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
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
