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

show_message_with_different_colours() {
  echo -e "${RED}This is red text${RESET}"
  echo -e "${GREEN}This is green text${RESET}"
  echo -e "${YELLOW}This is yellow text${RESET}"
  echo -e "${BLUE}This is blue text${RESET}"
  echo -e "${MAGENTA}This is magenta text${RESET}"
  echo -e "${CYAN}This is cyan text${RESET}"
  echo -e "${WHITE}This is white text${RESET}"
}

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

# Check if tools are installed in the system
# Usage: is_installed [-v] tool1 tool2 ...
# Options:
#   -v  Verbose mode: print status for each tool
# Returns: Number of missing tools (0 if all are installed)
is_installed() {
  local verbose=false
  local missing=0
  local tools=()

  # Parse options
  while [[ "$1" == -* ]]; do
    case "$1" in
      -v | --verbose)
        verbose=true
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  tools=("$@")

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      if [[ "$verbose" == true ]]; then
        echo "Error: $tool is not installed" >&2
      fi
      ((missing++))
    elif [[ "$verbose" == true ]]; then
      echo "OK: $tool is installed"
    fi
  done

  if [[ $missing -gt 0 && "$verbose" == false ]]; then
    echo "Error: Some required tools are not installed" >&2
  fi

  return $missing
}
