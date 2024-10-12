#!/usr/bin/env bash
# This script checks if there are any installed Homebrew casks or formulae
# that have corresponding plugins available in asdf.
#
# Steps:
# 1. Retrieve the list of all available asdf plugins and store them in an array.
# 2. Loop through the installed Homebrew casks and formulae.
# 3. For each installed item, check if there is a matching plugin in the asdf plugin list.
# 4. If a match is found, print the type (cask or formula) and the item name.

# Main script
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "This script is only supported on MacOS."
  exit 1
fi

# Retrieve the list of all available asdf plugins
IFS=$'\n' read -rd '' -a asdf_plugins <<<"$(asdf plugin-list-all)"

# Loop through installed brew items
for type in casks formulae; do
  for item in $(brew ls --$type); do
    # Check if the item has a matching plugin in asdf
    if [[ " ${asdf_plugins[*]} " == *" $item "* ]]; then
      echo "Brew ${type^} has matching asdf plugin: $item"
    fi
  done
done
