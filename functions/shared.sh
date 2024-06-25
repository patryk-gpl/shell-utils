#!/usr/bin/env bash
# This script contains functions that are used by other functions defined in sub-folders.

# shellcheck disable=SC2034
# Prevent to execute the script directly, only sourced by other scripts is allowed
prevent_to_execute_directly() {
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is not meant to be executed directly."
    exit 1
  fi
}

# Check if the script has already been sourced
if [ -z "${_SHARED_SH_SOURCED_+x}" ]; then
  # Colors ANSI escape codes
  readonly RESET="\033[0m"
  readonly BLACK="\033[30m"
  readonly RED="\033[31m"
  readonly GREEN="\033[32m"
  readonly YELLOW="\033[33m"
  readonly BLUE="\033[34m"
  readonly MAGENTA="\033[35m"
  readonly CYAN="\033[36m"
  readonly WHITE="\033[37m"

  # Set the flag to indicate the script has been sourced
  readonly _SHARED_SH_SOURCED_=1

  # Return the OS type
  find_os_type() {
    case "$OSTYPE" in
      linux-gnu*) echo "linux" ;;
      darwin*) echo "mac" ;;
      cygwin | msys | win32) echo "windows" ;;
      freebsd*) echo "freebsd" ;;
      *) echo "unknown" ;;
    esac
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
fi
