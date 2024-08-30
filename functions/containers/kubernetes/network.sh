if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_network_analysis() {
  if [ $# -lt 1 ]; then
    echo "Usage: kube_network_analysis <namespace1> [namespace2] [namespace3] ..."
    echo "Please provide at least one namespace."
    return 1
  fi

  local namespaces=("$@")
  local base_folder="kube_network_analysis"
  local ports_folder="$base_folder/ports"
  local resources_folder="$base_folder/resources"

  mkdir -p "$ports_folder" "$resources_folder"

  extract_port_info() {
    local namespace=$1
    local resource_type=$2
    local resource_name=$3
    echo "Extracting port info for $resource_type: $resource_name"
    kubectl get "$resource_type" "$resource_name" -n "$namespace" -o json |
      jq -r '.spec.ports[]? | "\(.name // "unnamed") \(.port) \(.targetPort // .port)"' 2>/dev/null >>"$ports_folder/${namespace}/${resource_type}_ports.txt"
  }

  process_service() {
    local namespace=$1
    local service=$2
    local selector
    selector=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.spec.selector}')

    if [ -n "$selector" ]; then
      local formatted_selector
      formatted_selector=$(echo "$selector" | jq -r 'to_entries | map("\(.key)=\(.value)") | join(", ")')
      echo "Service $service selects pods with labels: $formatted_selector" >>"$ports_folder/${namespace}/service_to_pod_mapping.txt"
    else
      echo "Service $service has no selector" >>"$ports_folder/${namespace}/service_to_pod_mapping.txt"
    fi

    extract_port_info "$namespace" "service" "$service"
  }

  for namespace in "${namespaces[@]}"; do
    echo "== Processing namespace: $namespace =="
    mkdir -p "$ports_folder/$namespace" "$resources_folder/$namespace"

    # Ingresses
    kubectl get ingress -n "$namespace" -o json | jq -r '
            .items[] |
            "Ingress: \(.metadata.name)\n  Backend Services:" +
            (.spec.rules[]?.http.paths[]? | "    \(.path // "/"): \(.backend.service.name):\(.backend.service.port.number // .backend.service.port.name // "unknown")") // "  No rules defined"
        ' 2>/dev/null >"$ports_folder/${namespace}/ingress_to_service_mapping.txt"

    # Services
    kubectl get svc -n "$namespace" -o wide >"$resources_folder/${namespace}/all_services.txt"
    local services
    services=$(kubectl get services -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
    for service in $services; do
      process_service "$namespace" "$service"
    done

    # Pods
    kubectl get pods -n "$namespace" -o json | jq -r '
            .items[] |
            "Pod: \(.metadata.name)\n  Labels: \(.metadata.labels | to_entries | map("\(.key)=\(.value)") | join(", ") // "None")\n  Containers:" +
            (.spec.containers[]? | "    \(.name): \(.ports[]? | "\(.containerPort) (\(.protocol // "TCP"))" // "No ports")") +
            "\n  Node: \(.spec.nodeName // "Not scheduled")"
        ' 2>/dev/null >"$ports_folder/${namespace}/pod_details.txt"

    # Network Policies
    kubectl get networkpolicies -n "$namespace" -o json | jq -r '
            .items[] |
            "NetworkPolicy: \(.metadata.name)\n  PodSelector: \(.spec.podSelector | to_entries | map("\(.key)=\(.value)") | join(", ") // "All pods")\n  PolicyTypes: \(.spec.policyTypes | join(", ") // "None")\n  Ingress Rules:" +
            (.spec.ingress[]? | "    From: \(.from[]? | .podSelector // .namespaceSelector // .ipBlock | to_entries | map("\(.key)=\(.value)") | join(", ") // "Any")\n    Ports: \(.ports[]? | "\(.port) (\(.protocol // "TCP"))" // "All ports")") +
            "\n  Egress Rules:" +
            (.spec.egress[]? | "    To: \(.to[]? | .podSelector // .namespaceSelector // .ipBlock | to_entries | map("\(.key)=\(.value)") | join(", ") // "Any")\n    Ports: \(.ports[]? | "\(.port) (\(.protocol // "TCP"))" // "All ports")")
        ' 2>/dev/null >"$ports_folder/${namespace}/network_policies.txt"

    # Endpoints
    kubectl get endpoints -n "$namespace" -o json | jq -r '
            .items[] |
            "Endpoint: \(.metadata.name)\n  Subsets:" +
            (.subsets[]? | "    Addresses: \(.addresses[]?.ip // "None")\n    Ports: \(.ports[]? | "\(.name // "unnamed"): \(.port) (\(.protocol // "TCP"))" // "No ports")")
        ' 2>/dev/null >"$ports_folder/${namespace}/endpoints.txt"

    # Resource Dumping
    for resource in ingress svc pods deployments statefulsets daemonsets cronjobs jobs; do
      kubectl get "$resource" -n "$namespace" -o yaml >"$resources_folder/${namespace}/all_${resource}.yaml"
    done

    # Network Policies
    kubectl get networkpolicies -n "$namespace" -o yaml >"$resources_folder/${namespace}/network_policies.yaml"

    # Endpoints
    kubectl get endpoints -n "$namespace" -o yaml >"$resources_folder/${namespace}/endpoints.yaml"

    # SparkApplications (if available)
    if kubectl api-resources | grep -q sparkapplications; then
      kubectl get sparkapplications -n "$namespace" -o yaml >"$resources_folder/${namespace}/all_sparkapplications.yaml"
    fi
  done

  # Custom Resource Definitions related to networking
  kubectl get crd -o name | grep -iE 'network|security|policy' | cut -d'/' -f2 | while read -r crd; do
    if kubectl get crd "$crd" -o jsonpath='{.spec.scope}' | grep -q "Namespaced"; then
      kubectl get "$crd" --all-namespaces -o yaml >>"$resources_folder/network_related_resources.yaml"
    else
      kubectl get "$crd" -o yaml >>"$resources_folder/network_related_resources.yaml"
    fi
  done

  echo "Creating summary of port usage..."
  find "$ports_folder" -name "*_ports.txt" -print0 | xargs -0 cat 2>/dev/null | sort | uniq -c | sort -nr >"$base_folder/port_usage_summary.txt"

  zip -rq "$base_folder.zip" "$base_folder"
  rm -rf "$base_folder"

  echo "==="
  echo "Network analysis and resource dumping has been completed and zipped into $base_folder.zip"
  echo "This includes detailed information about Ingresses, Services, Pods, NetworkPolicies, Endpoints, and other relevant resources."
}
