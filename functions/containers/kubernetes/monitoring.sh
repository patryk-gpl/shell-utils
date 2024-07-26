# Functions to work with Kubernetes cluster global operations

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

alias kube_events_get_all="kubectl get events --sort-by=.metadata.creationTimestamp"
alias kube_events_get_with_warn="kubectl get events --field-selector type=Warning --sort-by=.metadata.creationTimestamp"

alias kube_metric_server_status="kubectl get --raw '/apis/metrics.k8s.io/v1beta1/nodes' | jq ."
