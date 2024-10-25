kube_run_pod_python() {
  local python_version="3.11"
  local pod_name="python-${python_version//./}-pod"
  local force=false
  local username="pyuser"

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -f | --force)
        force=true
        shift
        ;;
      -v | --version)
        python_version="$2"
        pod_name="python-${python_version//./}-pod"
        shift 2
        ;;
      -h | --help)
        echo "Usage: kube_run_pod_python [-f|--force] [-v|--version <python_version>]"
        echo "  -f, --force   Force creation of new pod if it already exists"
        echo "  -v, --version Specify Python version (default: 3.11)"
        return 0
        ;;
      *)
        echo "Unknown parameter passed: $1"
        return 1
        ;;
    esac
  done

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

  echo "Creating new Python $python_version environment pod..."

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
    image: python:$python_version-slim
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
    echo "Python $python_version environment is ready."
    echo "Pod is running as root user, but a non-root user '$username' is available."
    echo "Use 'kubectl exec -it $pod_name -- bash' to start a root shell in the pod."
    echo "Use 'kubectl exec -it $pod_name -- su - $username' to start a non-root user shell."
    echo "Use 'kubectl delete pod $pod_name' to remove the pod when you're done."
  else
    echo "Failed to create the pod. Please check for any error messages above."
  fi
}
