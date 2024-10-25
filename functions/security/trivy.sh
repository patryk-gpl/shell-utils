# Functions to work with trivy scanner

trivy_scan_local_docker_images() {
  is_installed trivy || return 1
  local prefix=${1:-}
  if [[ -z "$prefix" ]]; then
    echo "Usage: ${FUNCNAME[0]} <image_prefix>"
    return 1
  fi
  docker images --format "{{.Repository}}:{{.Tag}}" |
    grep "^$prefix" |
    xargs -I {} bash -c 'echo "Scanning image: {}"; trivy image --scanners misconfig {}'
}
