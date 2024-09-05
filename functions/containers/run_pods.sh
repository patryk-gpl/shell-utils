if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

kube_run_pod_python() {
  local image_name="python"
  local image_tag="3.11-slim"
  local pod_name="python-pod"
  local username="pyuser"
  local force=false

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -f | --force)
        force=true
        shift
        ;;
      -i | --image)
        image_name="$2"
        shift 2
        ;;
      -t | --tag)
        image_tag="$2"
        shift 2
        ;;
      -n | --name)
        pod_name="$2"
        shift 2
        ;;
      -u | --user)
        username="$2"
        shift 2
        ;;
      -h | --help)
        echo "Usage: kube_run_pod_python [-f|--force] [-i|--image <image_name>] [-t|--tag <image_tag>] [-n|--name <pod_name>] [-u|--user <username>]"
        echo "  -f, --force   Force creation of new pod if it already exists"
        echo "  -i, --image   Specify the image name (default: python)"
        echo "  -t, --tag     Specify the image tag (default: 3.11-slim)"
        echo "  -n, --name    Specify the pod name (default: python-pod)"
        echo "  -u, --user    Specify the non-root username (default: pyuser)"
        return 0
        ;;
      *)
        echo "Unknown parameter passed: $1"
        return 1
        ;;
    esac
  done

  # Construct full image name
  local full_image_name="${image_name}:${image_tag}"

  if kubectl get pod "$pod_name" &>/dev/null; then
    if [ "$force" = true ]; then
      echo "Pod $pod_name already exists. Deleting it..."
      kubectl delete pod "$pod_name"
      sleep 5
    else
      echo "Pod $pod_name already exists. Use -f or --force to replace it."
      return 1
    fi
  fi

  echo "Creating new Python environment pod..."
  echo "Using image: $full_image_name"
  echo "Non-root username: $username"

  local yaml_template
  yaml_template=$(
    cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
spec:
  containers:
  - name: python
    image: $full_image_name
    command: ["/bin/bash", "-c"]
    args:
      - |
        set -e
        # Create non-root user
        groupadd -g 1000 $username
        useradd -u 1000 -g 1000 -m -s /bin/bash $username
        echo 'export PATH="/home/$username/.local/bin:$PATH"' >> /home/$username/.bashrc
        echo "PS1='\u@\h:\w\$ '" >> /home/$username/.bashrc

        # Set up pip for both root and non-root user
        pip install --upgrade pip
        su - $username -c "pip install --user --upgrade pip"

        echo "Environment setup complete. Running sleep loop..."
        while true; do sleep 30; done
    env:
    - name: HOME
      value: /root
    - name: PATH
      value: /usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF
  )

  echo "$yaml_template" | kubectl apply -f -

  echo "Waiting for pod to be ready..."
  if kubectl wait --for=condition=ready pod/"$pod_name" --timeout=60s; then
    echo "Python environment is ready."
    echo "Pod '$pod_name' is running with image: $full_image_name"
    echo "A non-root user '$username' is available."
    echo "Use 'kubectl exec -it $pod_name -- bash' to start a root shell in the pod."
    echo "Use 'kubectl exec -it $pod_name -- su - $username' to start a non-root user shell."
    echo "Use 'kubectl delete pod $pod_name' to remove the pod when you're done."
  else
    echo "Failed to create the pod. Please check for any error messages above."
  fi
}
