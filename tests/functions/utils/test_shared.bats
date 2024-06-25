#!/usr/bin/env bats

repo_root=$(git rev-parse --show-toplevel)

load "$repo_root/functions/shared.sh"

# Mock command -v for testing purposes
command_v() {
  case "$1" in
    existing_tool) return 0 ;;
    non_existing_tool) return 1 ;;
    *)
      echo "Unexpected argument to mock command_v: $1" >&2
      return 1
      ;;
  esac
}

# Override the real command -v with our mock
command() {
  if [ "$1" = "-v" ]; then
    command_v "$2"
  else
    command_v "$1"
  fi
}

@test "is_installed with single existing tool" {
  run is_installed existing_tool
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "is_installed with single non-existing tool" {
  run is_installed non_existing_tool
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Some required tools are not installed"* ]]
}

@test "is_installed with multiple existing tools" {
  run is_installed existing_tool existing_tool
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "is_installed with multiple tools, one non-existing" {
  run is_installed existing_tool non_existing_tool
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Some required tools are not installed"* ]]
}

@test "is_installed verbose mode with existing tool" {
  run is_installed -v existing_tool
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK: existing_tool is installed"* ]]
}

@test "is_installed verbose mode with non-existing tool" {
  run is_installed -v non_existing_tool
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: non_existing_tool is not installed"* ]]
}

@test "is_installed verbose mode with multiple tools" {
  run is_installed -v existing_tool non_existing_tool
  [ "$status" -eq 1 ]
  [[ "$output" == *"OK: existing_tool is installed"* ]]
  [[ "$output" == *"Error: non_existing_tool is not installed"* ]]
}

@test "is_installed with unknown option" {
  run is_installed --unknown-option tool
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --unknown-option"* ]]
}
