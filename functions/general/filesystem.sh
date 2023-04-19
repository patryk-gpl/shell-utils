#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with files and folders
####################################################################################################

####################################################################################################
# Copy folders recursively, excluding files and folders from a config file
# ~/.rsync.exclude should contain a list of files and folders to be excluded
#
# Example of ~/.rsync.exclude:
# .venv
# .terraform
# node_modules
# dist
# *.log
####################################################################################################
copy_dir() {
  src="$1"
  dest="$2"
  config="${3:-$HOME/.rsync.exclude}"

  if [[ ! -d "$src" || ! -d "$dest" ]]; then
    echo "Source or destination are missing. Aborting.."
    return 1
  fi

  rsync_opts=("-a")
  if [[ -f "$config" ]]; then
    rsync_opts+=("--exclude-from=$config")
  else
    echo "Config $config file is missing. No folders will be excluded from copy."
  fi

  echo "Running rsync with options: ${rsync_opts[*]}"
  rsync "${rsync_opts[@]}" "$src/" "$dest"
}
