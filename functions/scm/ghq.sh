#!/usr/bin/env bash
# This file contains functions to work with ghq tool

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

    local target_dir
    target_dir="$(ghq list -p "$1")"

    if [ -d "$target_dir" ]; then
        cd "$target_dir" || return
    else
        echo "Error: Directory does not exist: $1"
        return 1
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
