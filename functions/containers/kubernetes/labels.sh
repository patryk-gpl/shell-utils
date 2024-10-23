kube_pods_get_label_selectors() {
  local namespace=""
  local show_help=0

  show_usage() {
    cat <<EOF
Usage: kube_pods_get_label_selectors [-n NAMESPACE] [-h]

Display pod names and their label selectors in the specified or current namespace.

Options:
  -n NAMESPACE   Specify the namespace (optional)
  -h             Show this help message

Output format:
  Name: <pod_name>, Label selectors: <selector1>,<selector2>,...

If no namespace is specified, the current namespace will be used.
EOF
  }

  # Reset getopts
  OPTIND=1

  while getopts ":n:h" opt; do
    case ${opt} in
      n)
        namespace=$OPTARG
        ;;
      h)
        show_help=1
        ;;
      \?)
        echo "Invalid option: $OPTARG" 1>&2
        show_usage
        return 1
        ;;
      :)
        echo "Invalid option: $OPTARG requires an argument" 1>&2
        show_usage
        return 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ $show_help -eq 1 ]; then
    show_usage
    return 0
  fi

  local kubectl_args=()
  if [ -n "$namespace" ]; then
    kubectl_args+=("-n" "$namespace")
  fi

  kubectl get pods "${kubectl_args[@]}" -o json | jq -r '.items[] | "Name: \(.metadata.name), Label selectors: \(.metadata.labels | to_entries | map("\(.key)=\(.value)") | join(","))"'
}
