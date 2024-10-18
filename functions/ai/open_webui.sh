open_webui_manager() {
  local container_name="${OPEN_WEBUI_CONTAINER_NAME:-open-webui}"
  local image_name="${OPEN_WEBUI_IMAGE_NAME:-ghcr.io/open-webui/open-webui:latest}"
  local volume_name="${OPEN_WEBUI_VOLUME_NAME:-open-webui}"
  local port="${OPEN_WEBUI_PORT:-3000:8080}"

  show_help() {
    echo "Usage: open_webui_manager [OPTION]"
    echo "Manage the open-webui Docker container"
    echo
    echo "Options:"
    echo "  start    Start the container"
    echo "  stop     Stop the container"
    echo "  restart  Restart the container"
    echo "  update   Update to the latest image and restart"
    echo "  status   Show the container status"
    echo "  logs     Show the container logs"
    echo "  help     Display this help message"
  }

  start_container() {
    echo "Starting $container_name..."
    docker run -d -p "$port" --add-host=host.docker.internal:host-gateway \
      -v "$volume_name:/app/backend/data" --name "$container_name" \
      --restart always "$image_name"
  }

  stop_container() {
    echo "Stopping $container_name..."
    docker stop "$container_name" >/dev/null || echo "Container not running"
    docker rm "$container_name" >/dev/null || echo "Container not found"
  }

  update_container() {
    echo "Updating $container_name..."
    stop_container
    docker pull "$image_name"
    start_container
  }

  show_status() {
    echo "Status of $container_name:"
    docker ps -a --filter name="$container_name"
  }

  show_logs() {
    echo "Logs of $container_name:"
    docker logs "$container_name"
  }

  case "$1" in
    start)
      start_container
      ;;
    stop)
      stop_container
      ;;
    restart)
      stop_container
      start_container
      ;;
    update)
      update_container
      ;;
    status)
      show_status
      ;;
    logs)
      show_logs
      ;;
    help | *)
      show_help
      ;;
  esac
}
