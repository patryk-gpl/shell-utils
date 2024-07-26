# Functions to work with SSH

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

ssh_connect_with_retry() {
  local host="$1"
  local timeout=5

  if [[ -z "$host" ]]; then
    echo "Error: Host not provided."
    return 1
  fi

  echo "Connecting to $host with retry. Command sleep $timeout seconds before retry.."
  while ! ssh "$host"; do
    sleep $timeout
    echo "Retrying connection..."
  done
}

ssh_output_test() {
  local remote_host="$1"
  local command="${2:-true}"
  local timeout="${3:-5}"

  if [ $# -lt 1 ]; then
    echo "Usage: ssh_output_test <remote_host> [command] [timeout]"
    echo "  remote_host: The SSH host to connect to"
    echo "  command: The command to run (default: 'true')"
    echo "  timeout: Timeout in seconds (default: 5)"
    return 1
  fi

  echo "Testing SSH connection to $remote_host..."
  echo "Command: $command"
  echo "Timeout: $timeout seconds"
  echo "---"

  output=$(timeout "$timeout" ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no "$remote_host" "$command" 2>&1)
  exit_code=$?

  if [ $exit_code -eq 124 ]; then
    echo "Error: SSH connection timed out after $timeout seconds."
    return 1
  elif [ $exit_code -ne 0 ]; then
    echo "Error: SSH command failed with exit code $exit_code."
    echo "Output:"
    echo "$output"
    return 1
  fi

  if [ -z "$output" ]; then
    echo "Success: No output received."
    return 0
  else
    echo "Warning: Received unexpected output:"
    echo "$output"
    return 2
  fi
}
