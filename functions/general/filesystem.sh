#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with files and folders
####################################################################################################

source "$(dirname "$(dirname "$0")")/shared.sh"
prevent_to_execute_directly

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
rsync_copy_dir() {
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

# Create a tar archive of files matching a pattern recursively
tar_backup_file_recursively() {
  pattern=$1
  archive_name=$2
  path=${3:-.}
  if [[ -z "$pattern" || -z "$archive_name" ]]; then
    echo "Pattern or archive name is missing. Aborting.."
    return 1
  fi
  find "$path" -type f -name "$pattern" -exec tar -czvf "$archive_name" {} +
}
