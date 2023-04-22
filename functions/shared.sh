#!/usr/bin/env bash
####################################################################################################
# This script contains functions that are used by other functions defined in subdirectories.
####################################################################################################

# shellcheck disable=SC2034

# Prevent to execute the script directly, only sourced by other scripts is allowed
prevent_to_execute_directly() {
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is not meant to be executed directly."
    exit 1
  fi
}

# Colors ANSI escape codes
reset="\033[0m"
black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
white="\033[37m"

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
