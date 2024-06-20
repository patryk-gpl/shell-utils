#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Extracts a specific function from a given file.
#
# Usage: extract_function <filename> <func_name>
#
# Parameters:
#   - filename: The name of the file to extract the function from.
#   - func_name: The name of the function to extract.
#
# Returns:
#   - The content of the specified function from the file.
#   - Returns an error message if the file or function is not found.
#
# Example usage:
#   extract_function "script.sh" "my_function"
extract_function() {
  local filename=$1
  local func_name=$2

  if [[ -z "$filename" || -z "$func_name" ]]; then
    echo "Usage: extract_function <filename> <func_name>"
    return 1
  fi

  if [[ ! -f "$filename" ]]; then
    echo "File '$filename' not found."
    return 1
  fi

  awk -v func_name="$func_name" '
  $0 ~ "^(function )?" func_name "\\(" {
    in_function = 1
  }
  in_function {
    print
  }
  /^}/ && in_function {
    in_function = 0
    exit
  }
  ' "$filename"
}
