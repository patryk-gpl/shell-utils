#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

git_history_cleanup() {
  if ! command -v git-filter-repo &>/dev/null; then
    echo "git-filter-repo could not be found. Please install it first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "You need to provide at least one file or directory pattern to remove. E.g., '*.jks' '*.zip'"
    return 1
  fi

  patterns=("$@")

  paths_to_remove=""
  for pattern in "${patterns[@]}"; do
    paths_to_remove="$paths_to_remove --path-glob '$pattern'"
  done

  eval "git filter-repo --invert-paths $paths_to_remove"
}

git_history_shrink_storage_size() {
  echo "=> Running reflog expire..."
  git reflog expire --expire=now --all

  echo "=> Running garbage collection..."
  git gc --aggressive --prune=all

  echo "=> Running repack..."
  git repack -ad --depth=250 --window=250

  echo "=> Remove all remote branches that no longer exist locally..."
  git remote prune origin

  echo "=> Verify the integrity of the repository..."
  git fsck --full

  echo "=> Optimization complete. <="
}
