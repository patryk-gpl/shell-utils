# Functions to work with Kubernetes logs

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_logs_dump_from_pod_containers_with_filter() {
  local namespace=""
  local pod_name=""
  local filter=""

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n | --namespace)
        namespace="$2"
        shift
        ;;
      -p | --pod)
        pod_name="$2"
        shift
        ;;
      -f | --filter)
        filter="$2"
        shift
        ;;
      *)
        echo "Unknown parameter passed: $1"
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$pod_name" ]]; then
    echo "Usage: ${FUNCNAME[0]} -p|--pod <pod_name> [-n|--namespace <namespace>] [-f|--filter <filter>]"
    echo "Pod name is required. Namespace is optional (current namespace will be used if not specified)."
    return 1
  fi

  # If namespace is not provided, get the current namespace
  if [[ -z "$namespace" ]]; then
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    if [[ -z "$namespace" ]]; then
      echo "No namespace specified and unable to determine current namespace."
      return 1
    fi
    echo "Using current namespace: $namespace"
  fi

  local containers
  containers=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.spec.containers[*].name} {.spec.initContainers[*].name}' | xargs)

  if [[ -z "$containers" ]]; then
    echo "No containers found in pod $pod_name in namespace $namespace"
    return 1
  fi

  local -a read_params=("-r" "-a")
  if [[ $SHELL == *"zsh"* ]]; then
    read_params=("-r" "-A")
  fi
  IFS=' ' read -r "${read_params[@]}" container_array <<<"$containers"

  for container in "${container_array[@]}"; do
    echo -e "${GREEN}== Logs for container $container in pod $pod_name (namespace: $namespace) ==${RESET}"
    if [[ -n "$filter" ]]; then
      kubectl logs -n "$namespace" "$pod_name" -c "$container" | grep -E -i "$filter"
    else
      kubectl logs -n "$namespace" "$pod_name" -c "$container"
    fi
  done
}

kube_logs_dump_from_all_pods() {
  local namespace="$1"

  if [[ -z "$namespace" ]]; then
    echo "Usage: ${FUNCNAME[0]} <namespace>"
    return 1
  fi

  local pods
  pods=$(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name")

  local -a read_params=("-r" "-a")
  if [[ $SHELL == *"zsh"* ]]; then
    read_params=("-r" "-A")
  fi

  echo "Dumping logs for all pods in namespace $namespace..."
  while IFS= read -r pod; do
    echo "Dumping logs for pod $pod..."
    containers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name} {.spec.initContainers[*].name}' | xargs)

    # shellcheck disable=SC2162
    IFS=' ' read "${read_params[@]}" container_array <<<"$containers"

    for container in "${container_array[@]}"; do
      echo -e "${GREEN}== Logs for container $container in pod $pod ==${RESET}"
      kubectl logs -n "$namespace" "$pod" -c "$container" >"${namespace}_${pod}_${container}.log"
    done
  done <<<"$pods"
}
