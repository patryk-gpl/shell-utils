#!/usr/bin/env bash
# Functions to work with shfmt

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

shfmt_format_shell_scripts() {
  local dir="$1"
  if [ -z "$dir" ]; then
    echo "Usage: shfmt_format_shell_scripts <dir>"
    return 1
  fi

  find "$dir" -name "*.sh" -exec shfmt -i 2 -ci -w {} \;
}
