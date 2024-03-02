#!/usr/bin/env bash
# This file contains functions to work with the environment

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

envrc_archive_all() {
  if [[ $# -eq 0 ]]; then
    echo "Error: Root directory not provided."
    return 1
  fi

  local root_dir="$1"
  local output_file="envrc_files.tar.gz"

  find "$root_dir" -name ".envrc" -print0 | tar -czvf "$output_file" --null -T -

  echo "Archive created: $output_file"
}

envrc_enable_all() {
  if [[ $# -eq 0 ]]; then
    echo "Error: Root directory not provided."
    return 1
  fi

  local root_dir="$1"

  while IFS= read -r subdir; do
    if [[ -d "$subdir/.git" && -f "$subdir/.envrc" ]]; then
      echo "Enabling .envrc for: $subdir"
      (cd "$subdir" && direnv allow)
    fi
  done < <(find "$root_dir" -type d)
}
