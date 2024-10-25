# Functions to work with Flux v2

flux_list_all_active_resources() {
  local flux_resources
  local namespace="$1"
  flux_resources=$(kubectl api-resources --verbs=list -o name | awk '/flux/' | paste -sd "," -)

  kubectl get "$flux_resources" -n "$namespace"
}
