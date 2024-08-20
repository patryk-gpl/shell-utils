if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Function: kube_network_ports_analysis
#
# Description: Analyzes the network ports of Kubernetes resources in the specified namespaces.
#
# Parameters:
#   - <namespace1> [namespace2] [namespace3] ...: Namespaces to analyze. At least one namespace must be provided.
#
# Returns:
#   - 0: If the analysis is successful.
#   - 1: If no namespaces are provided.
#
# Output:
#   - Creates a folder named "kube_network_ports" and generates the following files inside each namespace folder:
#     - "ingress_to_service_mapping.txt": Contains the mapping of Ingresses to backend services.
#     - "service_details.txt": Contains details about Services, including type, selector, and ports.
#     - "pod_details.txt": Contains details about Pods, including labels, containers, and node assignment.
#     - "network_policies.txt": Contains details about NetworkPolicies, including pod selectors, policy types, and ingress/egress rules.
#     - "endpoints.txt": Contains details about Endpoints, including subsets, addresses, and ports.
#   - Creates a summary file named "port_usage_summary.txt" that provides a summary of port usage across all namespaces.
#   - Zips all the generated files into a folder named "kube_network_ports.zip" and moves it to the parent directory.
#   - Removes the "kube_network_ports" folder.
kube_network_ports_analysis() {
  if [ $# -lt 1 ]; then
    echo "Usage: kube_network_ports_analysis <namespace1> [namespace2] [namespace3] ..."
    echo "Please provide at least one namespace."
    return 1
  fi

  local namespaces=("$@")
  local folder="kube_network_ports"

  mkdir -p "$folder"
  cd "$folder" || exit

  extract_port_info() {
    local resource_type=$1
    local resource_name=$2
    echo "Extracting port info for $resource_type: $resource_name"
    kubectl get "$resource_type" "$resource_name" -n "$namespace" -o json |
      jq -r '.spec.ports[]? | "\(.name // "unnamed") \(.port) \(.targetPort // .port)"' 2>/dev/null >>"${resource_type}_ports.txt"
  }

  for namespace in "${namespaces[@]}"; do
    echo "== Processing namespace: $namespace =="
    mkdir -p "$namespace"
    (
      cd "$namespace" || exit

      # Ingresses
      echo "Analyzing Ingresses..."
      kubectl get ingress -n "$namespace" -o json | jq -r '
        .items[] |
        "Ingress: \(.metadata.name)\n  Backend Services:" +
        (.spec.rules[]?.http.paths[]? | "    \(.path // "/"): \(.backend.service.name):\(.backend.service.port.number // .backend.service.port.name // "unknown")") // "  No rules defined"
      ' 2>/dev/null >"ingress_to_service_mapping.txt"

      # Services
      echo "Analyzing Services..."
      kubectl get svc -n "$namespace" -o json | jq -r '
        .items[] |
        "Service: \(.metadata.name)\n  Type: \(.spec.type)\n  Selector: \(.spec.selector | to_entries | map("\(.key)=\(.value)") | join(", ") // "None")\n  Ports:" +
        (.spec.ports[]? | "    \(.name // "unnamed"): \(.port) -> \(.targetPort // .port)") // "  No ports defined"
      ' 2>/dev/null >"service_details.txt"

      kubectl get svc -n "$namespace" -o name | cut -d'/' -f2 | while read -r service; do
        extract_port_info "service" "$service"
      done

      # Pods
      echo "Analyzing Pods..."
      kubectl get pods -n "$namespace" -o json | jq -r '
        .items[] |
        "Pod: \(.metadata.name)\n  Labels: \(.metadata.labels | to_entries | map("\(.key)=\(.value)") | join(", ") // "None")\n  Containers:" +
        (.spec.containers[]? | "    \(.name): \(.ports[]? | "\(.containerPort) (\(.protocol // "TCP"))" // "No ports")") +
        "\n  Node: \(.spec.nodeName // "Not scheduled")"
      ' 2>/dev/null >"pod_details.txt"

      # Network Policies
      echo "Analyzing NetworkPolicies..."
      kubectl get networkpolicies -n "$namespace" -o json | jq -r '
        .items[] |
        "NetworkPolicy: \(.metadata.name)\n  PodSelector: \(.spec.podSelector | to_entries | map("\(.key)=\(.value)") | join(", ") // "All pods")\n  PolicyTypes: \(.spec.policyTypes | join(", ") // "None")\n  Ingress Rules:" +
        (.spec.ingress[]? | "    From: \(.from[]? | .podSelector // .namespaceSelector // .ipBlock | to_entries | map("\(.key)=\(.value)") | join(", ") // "Any")\n    Ports: \(.ports[]? | "\(.port) (\(.protocol // "TCP"))" // "All ports")") +
        "\n  Egress Rules:" +
        (.spec.egress[]? | "    To: \(.to[]? | .podSelector // .namespaceSelector // .ipBlock | to_entries | map("\(.key)=\(.value)") | join(", ") // "Any")\n    Ports: \(.ports[]? | "\(.port) (\(.protocol // "TCP"))" // "All ports")")
      ' 2>/dev/null >"network_policies.txt"

      # Endpoints
      echo "Analyzing Endpoints..."
      kubectl get endpoints -n "$namespace" -o json | jq -r '
        .items[] |
        "Endpoint: \(.metadata.name)\n  Subsets:" +
        (.subsets[]? | "    Addresses: \(.addresses[]?.ip // "None")\n    Ports: \(.ports[]? | "\(.name // "unnamed"): \(.port) (\(.protocol // "TCP"))" // "No ports")")
      ' 2>/dev/null >"endpoints.txt"

    )
  done

  echo "Creating summary of port usage..."
  find . -name "*_ports.txt" -print0 | xargs -0 cat 2>/dev/null | sort | uniq -c | sort -nr >"port_usage_summary.txt"

  zip -rq $folder.zip ./*
  mv $folder.zip ..
  cd .. || exit
  rm -rf $folder

  echo "==="
  echo "Network analysis has been completed and zipped into $folder.zip"
  echo "This includes detailed information about Ingresses, Services, Pods, NetworkPolicies, and Endpoints, focusing on ports."
}

# Function: kube_network_resources_dump
#
# Description: This function is used to dump relevant Kubernetes resources for the specified namespaces.
# It creates a folder named "kube_network_resources" and saves the dumped resources in separate directories for each namespace.
# The dumped resources include ingresses, services, pods, network policies, endpoints, and CRDs related to networking.
# The function also generates YAML files for ingresses and services, and description files for deployments, statefulsets, daemonsets, cronjobs, jobs, and SparkApplications (if available).
#
# Parameters:
#   - $1 (string): The first parameter is the namespace for which the resources should be dumped. At least one namespace must be provided.
#   - $2, $3, ... (string): Additional parameters can be used to specify more namespaces.
#
# Returns:
#   - 0: If the function executes successfully.
#   - 1: If the function encounters an error or if no namespace is provided.
#
# Usage: kube_network_resources_dump <namespace1> [namespace2] [namespace3] ...
#
# Example:
#   kube_network_resources_dump my-namespace
#   kube_network_resources_dump namespace1 namespace2 namespace3
kube_network_resources_dump() {
  if [ $# -lt 1 ]; then
    echo "Usage: kube_network_resources_dump <namespace1> [namespace2] [namespace3] ..."
    echo "Please provide at least one namespace."
    return 1
  fi

  local namespaces=("$@")
  local folder="kube_network_resources"

  mkdir -p "$folder"
  cd "$folder" || exit

  for namespace in "${namespaces[@]}"; do
    echo "== Processing namespace: $namespace =="
    mkdir -p "$namespace"
    (
      cd "$namespace" || exit

      # Ingresses
      kubectl get ingress -n "$namespace" -o wide >"all_ingresses_${namespace}.txt"
      local ingresses
      ingresses=$(kubectl get ingress -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
      for ingress in $ingresses; do
        echo "Dumping YAML for ingress: $ingress"
        kubectl get ingress "$ingress" -n "$namespace" -o yaml >"ingress-${ingress}.yaml"
        local backend_services
        backend_services=$(kubectl get ingress "$ingress" -n "$namespace" -o jsonpath='{.spec.rules[*].http.paths[*].backend.service.name}')
        echo "Ingress $ingress routes to services: $backend_services" >>"ingress_to_service_mapping.txt"
      done

      # Services
      kubectl get svc -n "$namespace" -o wide >"all_services_${namespace}.txt"
      local services
      services=$(kubectl get services -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
      for service in $services; do
        echo "Dumping YAML for service: $service"
        kubectl get service "$service" -n "$namespace" -o yaml >"service-${service}.yaml"
        local selector
        selector=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.spec.selector}')
        echo "Service $service selects pods with labels: $selector" >>"service_to_pod_mapping.txt"
      done

      # Dump descriptions for resources with containers
      dump_resource_description() {
        local resource_type=$1
        local resource_name=$2
        echo "Dumping description for $resource_type: $resource_name"
        kubectl describe "$resource_type" "$resource_name" -n "$namespace" >"${resource_type}-${resource_name}-description.txt"
      }

      echo "Get Pods"
      kubectl get pods -n "$namespace" -o wide >"all_pods_${namespace}.txt"

      echo "Get Deployments"
      kubectl get deployments -n "$namespace" -o wide >"all_deployments_${namespace}.txt"
      kubectl get deployments -n "$namespace" -o name | cut -d'/' -f2 | while read -r deployment; do
        dump_resource_description "deployment" "$deployment"
      done

      echo "Get StatefulSets"
      kubectl get statefulsets -n "$namespace" -o wide >"all_statefulsets_${namespace}.txt"
      kubectl get statefulsets -n "$namespace" -o name | cut -d'/' -f2 | while read -r statefulset; do
        dump_resource_description "statefulset" "$statefulset"
      done

      echo "Get DaemonSets"
      kubectl get daemonsets -n "$namespace" -o wide >"all_daemonsets_${namespace}.txt"
      kubectl get daemonsets -n "$namespace" -o name | cut -d'/' -f2 | while read -r daemonset; do
        dump_resource_description "daemonset" "$daemonset"
      done

      echo "Get CronJobs"
      kubectl get cronjobs -n "$namespace" -o wide >"all_cronjobs_${namespace}.txt"
      kubectl get cronjobs -n "$namespace" -o name | cut -d'/' -f2 | while read -r cronjob; do
        dump_resource_description "cronjob" "$cronjob"
      done

      echo "Get Jobs"
      kubectl get jobs -n "$namespace" -o wide >"all_jobs_${namespace}.txt"
      kubectl get jobs -n "$namespace" -o name | cut -d'/' -f2 | while read -r job; do
        dump_resource_description "job" "$job"
      done

      # Dump descriptions for SparkApplications
      if kubectl api-resources | grep -q sparkapplications; then
        echo "Dumping SparkApplications"
        kubectl get sparkapplications -n "$namespace" -o wide >"all_sparkapplications_${namespace}.txt"

        # Get all SparkApplications that are not in COMPLETED or FAILED state
        active_sparkapps=$(kubectl get sparkapplications -n "$namespace" \
          --no-headers \
          -o custom-columns=":metadata.name,:status.applicationState.state" |
          awk '$2 != "COMPLETED" && $2 != "FAILED" {print $1}')

        if [ -n "$active_sparkapps" ]; then
          echo "$active_sparkapps" | while read -r sparkapp; do
            dump_resource_description "sparkapplication" "$sparkapp"
          done
        else
          echo "No active SparkApplications found in namespace: $namespace"
        fi
      else
        echo "SparkApplication resource not found in the cluster. Skipping."
      fi

      # Network Policies
      echo "Dumping NetworkPolicies for namespace: $namespace"
      kubectl get networkpolicies -n "$namespace" -o yaml >"network_policies_${namespace}.yaml"

      # Endpoints
      echo "Dumping Endpoints for namespace: $namespace"
      kubectl get endpoints -n "$namespace" -o yaml >"endpoints_${namespace}.yaml"

      # Custom Resource Definitions related to networking (e.g., Istio, Cilium)
      kubectl get crd -o name | grep -iE 'network|security|policy' | cut -d'/' -f2 | while read -r crd; do
        if kubectl get crd "$crd" -o jsonpath='{.spec.scope}' | grep -q "Namespaced"; then
          echo "Fetching $crd resources from all namespaces"
          kubectl get "$crd" --all-namespaces -o yaml >>"network_related_resources.yaml"
        else
          echo "Fetching cluster-scoped $crd resources"
          kubectl get "$crd" -o yaml >>"network_related_resources.yaml"
        fi
      done
    )
  done

  zip -rq $folder.zip ./*
  mv $folder.zip ..
  cd .. || exit
  rm -rf $folder

  echo "==="
  echo "All relevant Kubernetes resources have been dumped and zipped into kube_network_resources.zip"
  echo "This includes ingresses, services, pods, network policies, endpoints, CRDS related to networking."
}
