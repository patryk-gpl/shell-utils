# Functions to work with Kubernetes pods

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_pods_by_status() {
  local namespace="" status="" delete_flag=false OPTIND

  show_help() {
    echo "Usage: kube_pod_show_pod_by_status [-n NAMESPACE] [-s STATUS] [-d] [-h]"
    echo
    echo "Options:"
    echo "  -n NAMESPACE  Specify the Kubernetes namespace (default: current namespace)"
    echo "  -s STATUS     Specify the pod status to filter (init, running, completed, failed)"
    echo "  -d            Delete the pods instead of showing them"
    echo "  -h            Display this help message"
    echo
    echo "Example:"
    echo "  kube_pod_show_pod_by_status -n my-namespace -s running"
    echo "  kube_pod_show_pod_by_status -s completed -d"
  }

  # Parse arguments
  while getopts ":n:s:dh" opt; do
    case ${opt} in
      n)
        namespace=$OPTARG
        ;;
      s)
        status=$OPTARG
        ;;
      d)
        delete_flag=true
        ;;
      h)
        show_help
        return 0
        ;;
      \?)
        echo "Invalid Option: -$OPTARG" 1>&2
        show_help
        return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        show_help
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  # Show help if no arguments provided
  if [[ -z "$namespace" ]] && [[ -z "$status" ]] && [[ "$delete_flag" == false ]]; then
    show_help
    return 0
  fi

  # If no namespace is provided, use the current namespace
  if [[ -z "$namespace" ]]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    # If still empty, default to "default" namespace
    namespace=${namespace:-default}
  fi

  # Validate and normalize status
  if [[ -z "$status" ]]; then
    echo "Error: Status must be provided with -s flag" >&2
    return 1
  fi

  case ${status,,} in
    init | pending)
      status="Pending"
      ;;
    running)
      status="Running"
      ;;
    completed | succeeded)
      status="Succeeded"
      ;;
    failed)
      status="Failed"
      ;;
    *)
      echo "Invalid status. Please use one of: init, running, completed, failed" >&2
      return 1
      ;;
  esac

  # Get pods with the specified status
  local pods
  pods=$(kubectl get pods -n "$namespace" --field-selector=status.phase="$status" -o name)

  if [[ -z "$pods" ]]; then
    echo "No pods found with status '$status' in namespace '$namespace'"
    return 0
  fi

  # Show or delete pods
  if $delete_flag; then
    echo "Deleting pods with status '$status' in namespace '$namespace':"
    echo "$pods" | xargs kubectl delete -n "$namespace"
  else
    echo "Pods with status '$status' in namespace '$namespace':"
    echo "$pods" | xargs kubectl get -n "$namespace"
  fi
}

# List all images used in the current namespace
kube_pods_list_image_names_per_namespace() {
  local namespace=${1}

  if [[ -z "$namespace" ]]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo "No namespace provided. Using the current active namespace: $namespace"
  fi

  kubectl get pods -n "$namespace" -o=jsonpath="{range .items[*].spec.containers[*]}{.image}{'\n'}{end}" "$@" | sort -u
}

kube_pods_list_unique_image_names_all_namespaces() {
  kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[:space:]' '\n' | sort | uniq
}

kube_pods_get_cpu_request_limits_details() {
  kubectl get pods -A -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests.cpu}{"\n"}{end}'
}

kube_pods_get_memory_request_limits_details() {
  kubectl get pods -A -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests.memory}{"\n"}{end}'
}

kube_pods_get_memory_request_limits_summary() {
  kubectl get pods -A -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests.memory}{"\n"}{end}' |
    awk '{for(i=2; i<=NF; i++) if($i ~ /Mi$/) {sub(/Mi$/, "", $i); mem+=$i} else if($i ~ /Gi$/) {sub(/Gi$/, "", $i); mem+=$i*1024} else if($i ~ /Ki$/) {sub(/Ki$/, "", $i); mem+=$i/1024} else {mem+=$i}} END {print "Total memory requests: " mem "Mi"}'
}

kube_pods_get_cpu_request_limits_summary() {
  kubectl get pods -A -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.requests.cpu}{"\n"}{end}' |
    awk '{for(i=2; i<=NF; i++) if($i ~ /m$/) {sub(/m$/, "", $i); cpu+=($i/1000)} else {cpu+=$i}} END {print "Total CPU requests: " cpu}'
}

kube_pods_get_cpu_and_memory_requests_limits_summary() {
  kube_pods_get_cpu_request_limits_summary
  kube_pods_get_memory_request_limits_summary
}

kube_pods_describe_all() {
  namespace=$1
  if [ -z "$namespace" ]; then
    echo "Usage: kube_pods_describe_all <namespace>"
    return 1
  fi

  local filename="podsDescribeAll-${namespace}.log"
  echo "== Processing pod descriptions for namespace $namespace ==" | tee "$filename"
  pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}')

  for pod in $pods; do
    echo "Describe pod $pod in namespace $namespace"
    echo "========================================" >>"$filename"
    kubectl describe pod "$pod" -n "$namespace" >>"$filename"
  done
}

kube_pods_delete_all() {
  local namespace="$1"
  if [[ -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace>"
  else
    kubectl delete pods --all -n "$namespace"
  fi
}

kube_pods_get_by_age() {
  local namespace=${1:-default}
  kubectl get pod --namespace "$namespace" --sort-by=.metadata.creationTimestamp
}

kube_pods_get_termination_reason() {
  reason=$1
  kubectl get pod "$reason" -o go-template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"
}

kube_pods_get_failed() {
  kubectl get pods --field-selector=status.phase=Failed "$@"
}

kube_pods_show_total_by_namespace() {
  kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace' | sort | uniq -c | sort -rn
}
