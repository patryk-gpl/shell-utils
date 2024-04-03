#!/usr/bin/env bash
# Functions to work with SSH

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

ssh_connect_with_retry() {
  local host="$1"

  local TIMEOUT=10

  if [[ -z "$host" ]]; then
    echo "Error: Host not provided."
    return 1
  fi

  echo "Connecting to $host with retry. Command sleep $TIMEOUT seconds before retry.."
  while ! ssh "$host"; do
    sleep $TIMEOUT
    echo "Retrying connection..."
  done
}
