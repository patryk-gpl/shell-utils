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
