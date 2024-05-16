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

kube_secret_dump_keys_to_stdout() {
  local namespace=$1
  local secret_name=$2

  if [[ -z $secret_name || -z $namespace ]]; then
    echo "Usage: kube_secret_decode_all_keys <namespace> <secret-name>"
    return 1
  fi

  local secret_json
  secret_json=$(kubectl get secret "$secret_name" -n "$namespace" -o json)
  local keys
  keys="$(echo "$secret_json" | jq -r '.data | keys[]')"

  for key in $keys; do
    local value
    value=$(echo "$secret_json" | jq -r --arg key "$key" '.data[$key]' | base64 --decode | tr -d '\0')

    is_binary_string="$(printf '%s' "$value" | file -b --mime - | cut -d';' -f1)"
    if [[ "$is_binary_string" == 'application/octet-stream' ]]; then
      echo "$key: (binary data). Base64 encoded: $(echo "$value" | base64)"
    else
      echo "$key: $value"
    fi
  done
}

kube_secret_dump_keys_to_file() {
  local namespace=$1
  local secret_name=$2

  if [[ -z $secret_name || -z $namespace ]]; then
    echo "Usage: kube_secret_decode_all_keys <namespace> <secret-name>"
    return 1
  fi

  local secret_json
  secret_json=$(kubectl get secret "$secret_name" -n "$namespace" -o json)
  local keys
  keys="$(echo "$secret_json" | jq -r '.data | keys[]')"

  for key in $keys; do
    local value
    value=$(echo "$secret_json" | jq -r --arg key "$key" '.data[$key]')

    echo "Dumping $key to file"
    echo "$value" | base64 -d >"$key"
  done
}
