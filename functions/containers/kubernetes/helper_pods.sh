# Functions to work with Kubernetes pods that contain utility functions

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_pod_run_curl() {
  kubectl run curl --image=curlimages/curl --restart=Never -- sleep infinity

  echo "Entering curl pod. To exit, type 'exit'."
  kubectl exec -it curl -- /bin/sh
}

kube_pod_run_net_tools() {
  local hostNetworkEnabled=$1
  local container_name="net-tools"

  if [[ -z "$hostNetworkEnabled" ]]; then
    echo "Running net_tools pod without host network enabled."
    kubectl run "$container_name" --rm -i --tty --image nicolaka/netshoot -- /bin/bash
    return
  fi

  echo "Running net_tools pod with host network enabled."
  kubectl run "$container_name" --rm -i --tty --overrides='{"spec": {"hostNetwork": true}}' --image nicolaka/netshoot -- /bin/bash
}
