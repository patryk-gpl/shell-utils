#!/usr/bin/env bash
####################################################################################################
# Functions to work with Azure CLI
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

az_extension_update_all() {
  az extension list --query "[].name" --output tsv | while read -r extension; do echo "Updating az extension $extension" ; az extension update --name "$extension" 2>&1 | grep -v "Use --debug for more information"; done
}
