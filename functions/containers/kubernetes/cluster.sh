# Functions to work with Kubernetes cluster global operations

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

## Namespaces
alias kube_get_ns_sorted_by_name="kubectl get ns --sort-by={.metadata.name}"

kube_ns_current() {
  kubectl config view --minify --output 'jsonpath={..namespace}'
}

## Nodes
kube_show_container_runtime_version() {
  kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}' | sort | uniq -c
}

kube_cluster_get_ips() {
  internal_ip=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  if [ -z "$internal_ip" ]; then
    internal_ip="Not available"
  fi

  external_url=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)
  if [ -z "$external_url" ]; then
    external_url="Not available"
    external_ip="Not available"
  else
    external_ip=$(echo "$external_url" | sed -e 's|^[^/]*//||' -e 's|:.*$||')
  fi

  echo "Kubernetes Cluster IPs:"
  echo "  Internal IP: $internal_ip"
  echo "  External URL: $external_url"
  echo "  External IP: $external_ip"
}
