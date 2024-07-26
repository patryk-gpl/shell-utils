# Functions to work with files and folders

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

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
  folder=${3:-.}
  if [[ -z "$pattern" || -z "$archive_name" ]]; then
    echo "Pattern or archive name is missing. Aborting.."
    return 1
  fi
  find "$folder" -type f -name "$pattern" -exec tar -czvf "$archive_name" {} +
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
    tree -f --noreport "$root_dir"
    echo
    echo "Content of all files from the folder and sub-folders: "
    find "$root_dir" -type f -exec sh -c 'echo "Filename: $1"; cat "$1"; echo "===END-OF-FILE==="' _ {} \;
  } >"$output_file"

  echo "Dump stored under $output_file"
}

download_file() {
  local url="$1"
  local dest_folder="$2"

  if [[ -z "$url" ]]; then
    echo "Usage: download_file <URL> [destination_folder]"
    echo "Downloads a file from the provided URL and saves it with the original filename."
    echo "If a destination folder is provided, the file will be saved there."
    return 1
  fi

  local filename
  filename=$(basename "$url")

  # Remove query string from filename, if present
  filename=${filename%%\?*}

  # Decode URL-encoded characters in the filename
  filename=$(printf '%b' "${filename//%/\\x}")

  local dest_path
  if [[ -n "$dest_folder" ]]; then
    # Create destination folder if it doesn't exist
    mkdir -p "$dest_folder"
    dest_path="$dest_folder/$filename"
  else
    dest_path="$filename"
  fi

  if command -v wget &>/dev/null; then
    wget -O "$dest_path" "$url"
  elif command -v curl &>/dev/null; then
    curl -L -o "$dest_path" "$url"
  else
    echo "Error: Neither wget nor curl is available. Please install one of them."
    return 1
  fi

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    echo "File downloaded successfully: $dest_path"
  else
    echo "Error: Failed to download the file."
    return 1
  fi
}
