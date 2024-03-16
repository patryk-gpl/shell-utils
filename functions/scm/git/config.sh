#!/usr/bin/env bash
# Functions to work with Git config
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# shellcheck disable=SC2086
git_config_show_attribute() {
  local attribute="$1"
  if [[ -z "$attribute" ]]; then
    echo "config attribute is required."
    return 1
  fi

  local configs=("global" "local" "system")

  echo "== Checking attribute: $attribute =="
  for config in "${configs[@]}"; do
    echo -n "${config} Configuration: "
    if git config --${config} --get "$attribute" >/dev/null 2>&1; then
      git config --${config} --get "$attribute"
    else
      echo "Attribute not found."
    fi
  done
}
