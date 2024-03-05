#!/usr/bin/env bash
# This file contains functions to work with trivy scanner

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

trivy_scan_local_docker_images() {
  _is_tool_installed trivy || return 1

  docker images --format "{{.Repository}}:{{.Tag}}" \
    | grep "^$prefix" \
    | xargs -I {} bash -c 'echo "Scanning image: {}"; trivy image --scanners misconfig {}'
}
