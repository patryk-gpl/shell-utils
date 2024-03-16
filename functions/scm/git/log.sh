#!/usr/bin/env bash
# Functions to work with Git log
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Search for a pattern in the Git history
git_log_history_search() {
  [ -z "$1" ] && {
    echo "Syntax: git_log_history_search <pattern>"
    return
  } || pattern="$1"

  git log --all -S"$pattern" --oneline |
    while read -r commit; do git show "${commit:0:7}"; done
}
