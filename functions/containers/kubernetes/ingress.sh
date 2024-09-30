# Generates host entries for Kubernetes ingresses.
#
# This function retrieves the ingress information from the current Kubernetes context
# and generates host entries in the format "IP HOSTNAME". The output can be used to
# update the /etc/hosts file or for other purposes where host resolution is needed.
#
# Prerequisites:
# - kubectl must be installed and configured to access the desired Kubernetes cluster.
#
# Usage:
#   kube_ingress_generate_hosts_entries
#
# Output:
# - Prints host entries to stdout in the format "IP HOSTNAME".
# - If no ingresses are found, prints an error message to stderr.
#
# Error Handling:
# - If kubectl is not installed or not in the PATH, prints an error message to stderr and returns 1.
# - If kubectl fails to retrieve ingress information, prints an error message to stderr and returns 1.
# - If no ingresses are found, prints an error message to stderr and returns 1.
kube_ingress_generate_hosts_entries() {
  if ! ingress_output=$(kubectl get ing 2>&1); then
    echo "Error: Failed to get ingress information. kubectl get ing returned:" >&2
    echo "$ingress_output" >&2
    return 1
  fi

  if ! echo "$ingress_output" | grep -q -v "No resources found"; then
    echo "No ingresses found in the current context" >&2
    return 1
  fi

  echo "# Kubernetes ingress hosts"
  echo "$ingress_output" | awk '
    NR > 1 {
        ip = $4;
        split($3, hosts, ",");
        for (i in hosts) {
            if (hosts[i] != "") {
                print ip " " hosts[i]
            }
        }
    }
    ' | sort -u
}

kube_ingress_get_context_paths() {
  if ! ingress_output=$(kubectl get ingress -o json 2>&1); then
    echo "Error: Failed to get ingress information. kubectl get ingress returned:" >&2
    echo "$ingress_output" >&2
    return 1
  fi

  if [ "$(echo "$ingress_output" | jq '.items | length')" -eq 0 ]; then
    echo "No ingresses found in the current context" >&2
    return 1
  fi

  echo "$ingress_output" | jq -r '
        .items[] |
        .spec.rules[] |
        select(.host != null) |
        .host as $host |
        if .http.paths then
            .http.paths[] |
            if .path then
                "\($host) \(.path)"
            else
                "\($host) /"
            end
        else
            "\($host) /"
        end
    ' | sort -u
}
