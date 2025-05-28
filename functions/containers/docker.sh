# Functions to work with Docker

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

docker_update_creds() {
  local user=""
  local token=""
  local legacy_encoded_creds=""
  local docker_config="${HOME}/.docker/config.json"

  # Define color codes
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local BLUE='\033[0;34m'
  local NC='\033[0m' # No Color

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)
        if [[ -z "$2" || "$2" == --* ]]; then
          echo -e "${RED}Error: Missing value for --user${NC}"
          return 1
        fi
        user="$2"
        shift 2
        ;;
      --token)
        if [[ -z "$2" || "$2" == --* ]]; then
          echo -e "${RED}Error: Missing value for --token${NC}"
          return 1
        fi
        token="$2"
        shift 2
        ;;
      --legacy-encoded-creds)
        if [[ -z "$2" || "$2" == --* ]]; then
          echo -e "${RED}Error: Missing value for --legacy-encoded-creds${NC}"
          return 1
        fi
        legacy_encoded_creds="$2"
        shift 2
        ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo -e "${YELLOW}Usage: docker_update_creds --user <username> --token <token> --legacy-encoded-creds <encoded_creds>${NC}"
        return 1
        ;;
    esac
  done

  if [[ -z "$user" || -z "$token" || -z "$legacy_encoded_creds" ]]; then
    echo -e "${RED}Error: All arguments are required${NC}"
    echo -e "${YELLOW}Usage: docker_update_creds --user <username> --token <token> --legacy-encoded-creds <encoded_creds>${NC}"
    return 1
  fi

  if [[ ! -f "$docker_config" ]]; then
    echo -e "${RED}Error: Docker config file not found at $docker_config${NC}"
    echo -e "${YELLOW}Please run 'docker login' first to create the config file${NC}"
    return 1
  fi

  local backup_file
  backup_file="${docker_config}.$(date +%Y%m%d%H%M%S).bak"
  cp "$docker_config" "$backup_file" || {
    echo -e "${RED}Error: Failed to create backup file${NC}"
    return 1
  }
  echo -e "${BLUE}Created backup of Docker config file at $backup_file${NC}"

  local new_encoded_creds
  new_encoded_creds=$(echo -n "${user}:${token}" | base64 | tr -d '\n')

  local count
  count=$(grep -o "$legacy_encoded_creds" "$docker_config" | wc -l)

  if [ "$count" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Could not find legacy credentials in Docker config file${NC}"
    echo -e "${YELLOW}No changes were made to Docker config${NC}"
    return 1
  fi

  local tmp_file="${docker_config}.tmp"
  sed "s/${legacy_encoded_creds}/${new_encoded_creds}/g" "$docker_config" >"$tmp_file" &&
    mv "$tmp_file" "$docker_config"

  # Verify the replacement
  local new_count
  new_count=$(grep -o "$new_encoded_creds" "$docker_config" | wc -l)

  if [ "$new_count" -ge "$count" ]; then
    echo -e "${GREEN}Successfully updated Docker credentials:${NC}"
    echo -e "  ${BLUE}Found:${NC} $count occurrences of legacy credentials"
    echo -e "  ${GREEN}Updated:${NC} $new_count credential entries"
    if [ "$new_count" -gt "$count" ]; then
      echo -e "  ${YELLOW}Note:${NC} Additional matches might be due to previously updated credentials"
    fi
  else
    echo -e "${RED}Warning: Replacement verification failed${NC}"
    echo -e "${RED}Expected at least $count replacements, but found only $new_count${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    cp "$backup_file" "$docker_config"
    return 1
  fi
}

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

  docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}" | grep -E "^$prefix_or_tag|:$prefix_or_tag:" | while read -r line; do
    IFS=':' read -r repo tag id <<<"$line"
    if [ "$tag" = "<none>" ]; then
      image="$id"
    else
      image="$repo:$tag"
    fi
    if [ -n "$image" ]; then
      echo "Removing image: $image"
      docker rmi "$image" || echo "Failed to remove image: $image"
    fi
  done
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
