#!/usr/bin/env bash

run_container() {
  local mode=""
  local name=""
  local image=""
  local ports=()
  local volumes=()
  local other_args=()
  local k8s_namespace=""
  local dry_run=false

  # Parse arguments
  while (($#)); do
    case $1 in
      --mode=*) mode="${1#*=}" ;;
      --name=*) name="${1#*=}" ;;
      --image=*) image="${1#*=}" ;;
      --dry-run) dry_run=true ;;
      -p | --port | -v | --volume)
        if [[ -n $2 && $2 != -* ]]; then
          if [[ $1 == -p || $1 == --port ]]; then
            ports+=("$2")
          else
            volumes+=("$2")
          fi
          shift
        else
          echo "Error: Argument for $1 is missing" >&2
          return 1
        fi
        ;;
      *) other_args+=("$1") ;;
    esac
    shift
  done

  # Display help if no mode is provided
  if [[ -z $mode ]]; then
    echo "Usage: run_container --mode=[docker|kubernetes] --name=<container_name> --image=<image_name> [-p <port>] [-v <volume>] [--dry-run]"
    echo
    echo "Options:"
    echo "  --mode              Specify 'docker' for local run or 'kubernetes' for cluster deployment"
    echo "  --name              Set the name for the container or deployment"
    echo "  --image             Specify the Docker image to use"
    echo "  -p, --port          Map a port (can be used multiple times)"
    echo "  -v, --volume        Mount a volume (can be used multiple times)"
    echo "  --dry-run           Print the commands without executing them"
    echo
    echo "Example:"
    echo "  run_container --mode=docker --name=firefox --image=jlesage/firefox -p 5800:5800 -v /docker/appdata/firefox:/config:rw"
    return 0
  fi

  # Validate required parameters
  if [[ -z $name || -z $image ]]; then
    echo "Error: --name and --image are required parameters." >&2
    return 1
  fi

  # Run in Docker mode
  if [[ $mode == "docker" ]]; then
    local docker_cmd="docker run -d --name=$name ${ports[@]/#/-p } ${volumes[@]/#/-v } ${other_args[*]} $image"
    if $dry_run; then
      echo "Dry run: $docker_cmd"
    else
      if ! eval "$docker_cmd"; then
        echo "Error: Failed to start Docker container" >&2
        return 1
      fi
      echo "Docker container '$name' started successfully"
    fi

  # Deploy to Kubernetes
  elif [[ $mode == "kubernetes" ]]; then
    # Check if kubectl is available
    if ! command -v kubectl &>/dev/null; then
      echo "Error: kubectl is not installed or not in PATH" >&2
      return 1
    fi

    # Get the current namespace from kubectl context
    k8s_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    [[ -z $k8s_namespace ]] && k8s_namespace="default"

    # Create a temporary YAML file for the Kubernetes deployment
    local temp_yaml
    temp_yaml=$(mktemp)

    # shellcheck disable=SC2064
    trap "rm -f '$temp_yaml'" EXIT

    cat <<EOF >"$temp_yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $k8s_namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
    spec:
      containers:
      - name: $name
        image: $image
        ports:
$(printf -- '        - containerPort: %s\n' "${ports[@]/#*:/}")
        volumeMounts:
$(for v in "${volumes[@]}"; do
      mount_path=${v#*:}
      mount_path=${mount_path%:*}
      printf -- '        - name: vol-%s\n          mountPath: %s\n' "${v%%:*//}" "$mount_path"
    done)
      volumes:
$(for v in "${volumes[@]}"; do
      host_path=${v%%:*}
      printf -- '      - name: vol-%s\n        hostPath:\n          path: %s\n' "${host_path//\//-}" "$host_path"
    done)
EOF

    if $dry_run; then
      echo "Dry run: kubectl apply -f $temp_yaml"
      cat "$temp_yaml"
    else
      if ! kubectl apply -f "$temp_yaml"; then
        echo "Error: Failed to apply Kubernetes deployment" >&2
        return 1
      fi
      echo "Kubernetes deployment '$name' applied successfully"

      echo "Waiting for deployment to be ready..."
      if ! kubectl rollout status deployment/"$name" -n "$k8s_namespace"; then
        echo "Error: Deployment did not become ready in time" >&2
        return 1
      fi
      echo "Deployment '$name' is ready"
    fi
  else
    echo "Error: Invalid mode. Use 'docker' or 'kubernetes'." >&2
    return 1
  fi
}
