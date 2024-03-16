#!/usr/bin/env bash
# Functions to work with Vagrant

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

alias vagrant_list_avail_plugins="gem list --remote vagrant-"
