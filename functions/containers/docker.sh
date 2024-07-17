#!/usr/bin/env bash
# Functions to work with Docker

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

# List Docker authentication configurations
docker_auth_list() {
  if [[ -f ~/.docker/config.json ]]; then
    jq -r '.auths | keys []' ~/.docker/config.json
  else
    echo "No Docker authentication configurations found"
  fi
}

docker_image_remove_with_prefix_or_tag() {
  local prefix_or_tag="$1"

  if [ -z "$prefix_or_tag" ]; then
    echo "Usage: $0 <prefix_or_tag>"
    echo "Prefix or tag is required"
    return 1
  fi
  docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "^$prefix_or_tag|:$prefix_or_tag$" | xargs -I {} docker rmi {}
}

# Return status of Docker Engine daemon
docker_daemon_started() {
  if docker info >/dev/null 2>&1; then
    echo "Docker is up and running."
  else
    echo "Docker is not running."
  fi
}

# Are we running inside a Docker container?
docker_container_active() {
  if grep -q '^/docker/' /proc/1/cgroup; then
    echo "Running inside Docker container"
  else
    echo "Not running inside Docker container"
  fi
}

docker_container_remove() {
  local container_name=$1

  if [ -z "$container_name" ]; then
    echo "Error: No container name provided."
    echo "Usage: docker_container_remove <container_name>"
    return 1
  fi

  echo "Stopping container: $container_name..."
  docker stop "$container_name" >/dev/null || echo "Container $container_name stopped.."

  echo "Deleting container: $container_name..."
  docker rm "$container_name" >/dev/null || echo "Container $container_name removed.."

  echo "Container $container_name has been stopped and deleted."
}

# Show Docker image labels
docker_image_labels() {
  if [[ -z "$1" ]]; then
    echo "Missing docker image name"
    return
  fi
  docker inspect --format '{{ range $k,$v:=.Config.Labels }}{{ $k }}={{ println $v}}{{end}}' "$1"
}

# Show latest Docker container ID
docker_latest_container_id() {
  docker ps --last 1 -q
}

# Docker prune all containers, images, volumes and networks without asking for confirmation
docker_prune_all_force() {
  echo "Pruning all Docker containers, images, volumes and networks..."
  read -p "Are you sure? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune --all --force --volumes
  fi
}

# Remove all dangling Docker containers, images, volumes and networks
docker_prune_dangling_objects() {
  objects=(container image volume network)
  for object in "${objects[@]}"; do
    echo "Removing dangling $object (if any)..."
    docker "$object" prune -f
  done
}

# List Docker images sorted by size
docker_image_ls_by_size() {
  docker image ls --format '{{.Size}}\t{{.Repository}}:{{.Tag}}' | sort -hr
}

docker_container_ip() {
  container_id=${1:-$(docker_latest_container_id)}
  if "$container_id"; then
    echo "Missing container ID"
    return
  fi

  container_ip=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' "$container_id")
  container_name=$(docker inspect --format '{{.Name}}' "$container_id")
  if [ -n "$container_ip" ]; then
    echo "Container $container_name has IP: $container_ip"
  else
    echo "Container $container_name has no IP address assigned"
  fi
}

docker_tags_remove_all() {
  if [ -z "$1" ]; then
    echo "Error: Image name not provided."
    return 1
  fi

  local image_name="$1"
  local tags
  tags=$(docker image ls --format '{{.Repository}}:{{.Tag}}' | grep "$image_name")

  for tag in $tags; do
    docker image rm "$tag"
  done
}

docker_registry_list_tags() {
  local repository_image=$1

  if [ -z "$repository_image" ]; then
    echo "Usage: docker_registry_list_tags <repository/image>"
    return 1
  fi

  local json_output sorted_output
  json_output=$(docker run --rm quay.io/skopeo/stable list-tags docker://"$repository_image")
  sorted_output=$(echo "$json_output" | jq '.Tags |= sort')
  echo "$sorted_output"
}
