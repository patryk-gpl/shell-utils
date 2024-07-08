#!/usr/bin/env bash
# Functions to work with ghq tool

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

cdq() {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide a directory name."
    return 1
  fi

  local dirs
  dirs=$(ghq list -p "$1")

  if [[ -z "$dirs" ]]; then
    echo "Error: No matching directories found for: $1"
    return 1
  fi

  if [[ -n $ZSH_VERSION ]]; then
    # shellcheck disable=SC2296
    local target_dirs=("${(@f)dirs}")
  else
    # shellcheck disable=SC2206
    local target_dirs=($dirs)
  fi

  if [ ${#target_dirs[@]} -eq 1 ]; then
    # shellcheck disable=SC2124
    local dir="${target_dirs[@]:0:1}"
    cd "$dir"
  else
    echo "Multiple matching directories found:"
    local i=1
    for dir in "${target_dirs[@]}"; do
      echo "$i: $dir"
      ((i++))
    done

    local selection
    echo -n "Select a directory (1-${#target_dirs[@]}): "
    read -r selection

    selection=$(echo "$selection" | tr -cd '[:digit:]')

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#target_dirs[@]}" ]; then
      echo "Error: Invalid selection."
      return 1
    fi

    # shellcheck disable=SC2124
    local selected_dir="${target_dirs[@]:$((selection-1)):1}"
    cd "$selected_dir" && echo "Changed to directory: $selected_dir"
  fi
}

ghq_tree() {
  local root_dir="${1:-~/$HOME}"

  if [ -d "$root_dir" ]; then
    tree -d "$root_dir/github.com/" -L 2
  else
    echo "Directory $root_dir does not exist."
  fi
}
