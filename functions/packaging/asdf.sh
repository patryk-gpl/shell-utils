#!/usr/bin/env bash
# Functions to work with asdf tool

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

function asdf_plugin_show_install_script() {
  if ! command -v asdf &>/dev/null; then
    echo "Error: asdf is not installed."
    return 1
  fi

  local plugin_name=$1
  if [[ -z $plugin_name ]]; then
    echo "Error: Plugin name is missing."
    echo "Available installed plugins:"
    asdf plugin list
    return 1
  fi

  local bin_path="$HOME/.asdf/plugins/$plugin_name/bin/install"

  if [[ -f $bin_path ]]; then
    echo "== Content of the install script for plugin '$plugin_name' =="
    if command -v bat &>/dev/null; then
      bat "$bin_path"
    else
      cat "$bin_path"
    fi
  else
    echo "Error: Install script for plugin '$plugin_name' does not exist."
    return 1
  fi
}
