#!/usr/bin/env bash
# This script contains functions that are used by other functions defined in subdirectories.

# shellcheck disable=SC2034
# Prevent to execute the script directly, only sourced by other scripts is allowed
prevent_to_execute_directly() {
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is not meant to be executed directly."
    exit 1
  fi
}

# Colors ANSI escape codes
RESET="\033[0m"
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Return the OS type
find_os_type() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "linux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "mac"
  elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "windows"
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Check if a tool is installed in the system
_is_tool_installed() {
  tools=("$@")
  for tool in "${tools[@]}"; do
    if ! which "$tool" >/dev/null; then
      echo -e "${RED}Error: ${RESET} $tool is not installed"
      return 1
    fi
  done
}
