#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

function git_reflog_expire() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git reflog expire --expire=now --all
  else
    echo "Error: Not in a git repository."
  fi
}
