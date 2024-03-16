#!/usr/bin/env bash
# Functions to work with Git grep
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Search for a pattern in all commits, show the commit hash and the line number
git_grep_all_commits() {
  [ -z "$1" ] && {
    echo "Usage: git_grep_all_commits <pattern>" >&2
    return 1
  } || pattern="$1"

  commits=()
  while IFS= read -r line; do
    commits+=("$line")
  done < <(git rev-list --all)
  git grep -n "$pattern" "${commits[@]}"
  echo "Found ${#commits[@]} commits. Searching for pattern: $pattern"
}
