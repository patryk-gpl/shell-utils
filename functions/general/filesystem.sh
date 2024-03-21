#!/usr/bin/env bash
# Functions to work with files and folders

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Convert tabs to spaces in a file and print the number of tabs converted
convert_tabs_to_spaces() {
  local file=$1
  if [[ -f $file ]]; then
    beforeTabs=$(grep $'\t' -o "$file" | wc -l | tr -d '[:space:]')
    expand -t 2 "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    echo "Number of tabs converted to spaces in $file: $beforeTabs"
  else
    echo "File $file does not exist."
  fi
}

# Copy folders recursively, excluding files and folders from a config file
# ~/.rsync.exclude should contain a list of files and folders to be excluded
#
# Example of ~/.rsync.exclude:
# .venv
# .terraform
# node_modules
# dist
# *.log
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

# Collect and save a list of files into a single file
file_dump_content() {
  if [[ -z $1 ]]; then
    echo "Error: Root directory not provided."
    return 1
  fi

  local root_dir=$1
  local output_file=${2:-out.log}

  {
    echo "Folder structure: "
    tree -f  --noreport "$root_dir"
    echo
    echo "Content of all files from the folder and sub-folders: "
    find "$root_dir" -type f -exec sh -c 'echo "Filename: $1"; cat "$1"; echo' _ {} \;
    echo "Wait for the next prompt. Confirm with DONE."
  } > "$output_file"
}
