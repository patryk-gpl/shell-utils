# Functions to work with Kubernetes replica sets

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

## Replica Sets

kube_rs_delete() {
  local namespace="$1"
  if [ -z "$namespace" ]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo "No namespace provided, using current context namespace: $namespace"
  else
    echo "Using namespace: $namespace"
  fi

  local rs
  rs=$(kubectl get rs -n "$namespace" --no-headers | awk '{if ($2 + $3 + $4 == 0) print $1}')

  if [ -z "$rs" ]; then
    echo "No resources found to clean in $namespace namespace."
  else
    # shellcheck disable=SC2086
    kubectl delete rs $rs -n "$namespace"
  fi
}

kube_rs_delete_in_all_namespaces() {
  for ns in $(kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}'); do
    if kubectl get rs -n "$ns" >/dev/null 2>&1; then
      kube_delete_replica_sets "$ns"
    else
      echo "No resources found to clean in $ns namespace."
    fi
  done
}
