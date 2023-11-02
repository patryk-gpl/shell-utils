#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Docker
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

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
  docker system prune --all --force --volumes
}

# Remove all dangling Docker containers, images, volumes and networks
docker_clean_all() {
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
