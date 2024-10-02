kube_svc_get_ports() {
  local namespace=""

  show_help() {
    echo "Usage: kube_svc_get_ports [-n NAMESPACE]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace   Specify the namespace (default: current namespace)"
    echo "  -h, --help        Show this help message"
  }

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n | --namespace)
        namespace="$2"
        shift 2
        ;;
      -h | --help)
        show_help
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        return 1
        ;;
    esac
  done

  if [[ -n "$namespace" ]]; then
    if ! kubectl get namespace "$namespace" &>/dev/null; then
      echo "Error: Namespace '$namespace' does not exist."
      show_help
      return 1
    fi
  else
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    if [[ -z "$namespace" ]]; then
      namespace="default"
    fi
  fi

  kubectl get services -n "$namespace" -o custom-columns=NAME:.metadata.name,PORTS:.spec.ports[*].port,TARGET_PORTS:.spec.ports[*].targetPort
}

kube_ingress_get_pods_port_map() {
  local namespace

  if [ -z "$1" ]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    if [ -z "$namespace" ]; then
      echo "Error: No namespace provided and unable to determine current namespace."
      echo "Usage: kube_ingress_get_pods_port_map [namespace]"
      return 1
    fi
    echo "No namespace provided. Using current namespace: $namespace"
  else
    namespace="$1"
  fi

  echo "Ingress to Pod Port Mapping for namespace: $namespace"
  echo "----------------------------------------------------"

  kubectl get ingress -n "$namespace" -o name | while read -r ingress; do
    ingress_name=$(echo "$ingress" | cut -d'/' -f2)
    echo "Ingress: $ingress_name"

    kubectl get "$ingress" -n "$namespace" -o jsonpath='{range .spec.rules[*].http.paths[*].backend.service}{.name}{"\n"}{end}' | sort -u | while read -r service; do
      [[ -z "$service" ]] && continue
      echo "  Service: $service"

      service_data=$(kubectl get service "$service" -n "$namespace" -o json)
      target_ports=$(echo "$service_data" | jq -r '.spec.ports[].targetPort')
      selector=$(echo "$service_data" | jq -r '.spec.selector | to_entries | map("\(.key)=\(.value)") | join(",")')

      echo "    Selector: $selector"

      kubectl get pods -n "$namespace" -l "$selector" -o name | while read -r pod; do
        pod_name=$(echo "$pod" | cut -d'/' -f2)
        echo "    Pod: $pod_name"

        for target_port in $target_ports; do
          if [[ "$target_port" =~ ^[0-9]+$ ]]; then
            echo "      Port: $target_port"
          else
            container_port=$(kubectl get "$pod" -n "$namespace" -o jsonpath="{.spec.containers[*].ports[?(@.name==\"$target_port\")].containerPort}")
            [[ -n "$container_port" ]] && echo "      Port: $container_port (named: $target_port)" || echo "      Port: Not found for name $target_port"
          fi
        done
      done
      echo ""
    done
    echo ""
  done
}
