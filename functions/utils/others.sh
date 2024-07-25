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

# Function: extract_block
# Description: Extracts a block of text from a file based on start and end patterns.
# Parameters:
#   - file: The file to extract the block from.
#   - start_pattern: The pattern that marks the start of the block.
#   - end_pattern: The pattern that marks the end of the block.
# Usage: extract_block <file> <start_pattern> <end_pattern>
# Example: extract_block file.yaml '# Source: release/charts/opensearch/templates/poddisruptionbudget.yaml' '^---'
# Returns:
#   - 0: If the block is successfully extracted.
#   - 1: If there is an error or the block cannot be found.
extract_block() {
  if [ $# -ne 3 ]; then
    echo "Usage: extract_block <file> <start_pattern> <end_pattern>" >&2
    echo "Example: extract_block file.yaml '# Source: netreveal/charts/opensearch/templates/poddisruptionbudget.yaml' '^---'" >&2
    return 1
  fi

  local file="$1"
  local start_pattern="$2"
  local end_pattern="$3"

  if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found." >&2
    return 1
  fi

  awk -v start="$start_pattern" -v end="$end_pattern" '
  BEGIN { printing = 0; }
  $0 ~ start { printing = 1; next; }
  $0 ~ end { if (printing) exit; }
  printing == 1 { print; }
  ' "$file"
}
