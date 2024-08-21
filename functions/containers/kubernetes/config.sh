if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

kube_config_get_contexts() {
  echo "Available Kubernetes contexts:"
  kubectl config get-contexts -o name | sort | sed 's/^/  /'
}

kube_config_switch_context() {
  echo "Current context:"
  kubectl config current-context
  echo -e "\nAvailable contexts:"

  local contexts=()
  while IFS= read -r context; do
    contexts+=("$context")
  done < <(kubectl config get-contexts -o name)

  for i in "${!contexts[@]}"; do
    echo "$((i + 1)). ${contexts[i]}"
  done

  read -rp "Enter the number or name of the context you want to switch to: " selection

  if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -le "${#contexts[@]}" ] && [ "$selection" -gt 0 ]; then
    # If input is a valid number, use it as an index
    selected_context="${contexts[$((selection - 1))]}"
  else
    # Otherwise, treat the input as a context name
    selected_context="$selection"
  fi

  if kubectl config use-context "$selected_context" &>/dev/null; then
    echo "Successfully switched to context: $selected_context"
  else
    echo "Failed to switch context. '$selected_context' might not be a valid context."
  fi
}

kube_config_switch_namespace() {
  local current_context
  current_context=$(kubectl config current-context)
  local current_namespace
  current_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')

  echo "Current context: $current_context"
  echo "Current namespace: ${current_namespace:-default}"
  echo -e "\nAvailable namespaces:"

  local namespaces=()
  while IFS= read -r namespace; do
    namespaces+=("$namespace")
  done < <(kubectl get namespaces -o name | cut -d'/' -f2)

  for i in "${!namespaces[@]}"; do
    echo "$((i + 1)). ${namespaces[i]}"
  done

  local selection
  read -rp "Enter the number or name of the namespace you want to switch to: " selection

  local selected_namespace
  if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -le "${#namespaces[@]}" ] && [ "$selection" -gt 0 ]; then
    # If input is a valid number, use it as an index
    selected_namespace="${namespaces[$((selection - 1))]}"
  else
    # Otherwise, treat the input as a namespace name
    selected_namespace="$selection"
  fi

  if kubectl config set-context --current --namespace="$selected_namespace" &>/dev/null; then
    echo "Successfully switched to namespace: $selected_namespace"
  else
    echo "Failed to switch namespace. '$selected_namespace' might not be a valid namespace."
  fi
}
