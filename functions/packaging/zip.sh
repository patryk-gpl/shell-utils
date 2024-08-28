if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Function: 7zip_archive_with_password
#
# Description:
#   This function creates a password-protected 7zip archive of a specified folder.
#
# Parameters:
#   - $1: The path to the folder to be archived (mandatory).
#   - $2: Output filename (optional)
#
# Usage:
#   7zip_archive_with_password <path_to_folder> [output_filename]
#
# Returns:
#   - 0: If the archive is created successfully.
#   - 1: If there is an error during the archive creation process.
#
# Dependencies:
#   - 7zip: The 7zip utility must be installed to use this function.
#
# Example:
#   7zip_archive_with_password /path/to/folder
#   7zip_archive_with_password /path/to/folder data.zip
#
#   This will create a password-protected 7zip archive of the specified folder.
7zip_archive_with_password() {
  local exclude_list=()
  local auto_exclude=true

  # Function to show usage
  show_usage() {
    cat <<EOF
Usage: 7zip_archive_with_password [-e <list_of_folders_or_files>] [-n] <path_to_folder> [output_filename]

Options:
  -e, --exclude   Comma-separated list of folders or files to exclude
  -n, --no-auto   Disable automatic exclusion of common development folders (.git, .direnv, .venv)

Examples:
  7zip_archive_with_password -e "node_modules,dist" /path/to/folder
  7zip_archive_with_password -n /path/to/folder custom_output.7z

Notes:
  - When using the -e or --exclude option, provide a comma-separated list of filenames or directory names to exclude from the archive.
  - By default, .git, .direnv, and .venv folders are automatically excluded. Use -n to disable this.
  - If the output filename is not provided, a default name will be generated based on the source directory and the current timestamp.
EOF
  }

  # Parse options
  while [[ $# -gt 0 ]]; do
    case $1 in
      -e | --exclude)
        if [[ -n $2 ]] && [[ $2 != -* ]]; then
          IFS=',' read -r -a user_exclude_list <<<"$2"
          exclude_list+=("${user_exclude_list[@]}")
          shift 2
        else
          echo "Error: --exclude requires a non-empty argument."
          show_usage
          return 1
        fi
        ;;
      -n | --no-auto)
        auto_exclude=false
        shift
        ;;
      -*)
        echo "Unknown option $1"
        show_usage
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  # Check remaining arguments
  if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
    show_usage
    return 1
  fi

  if ! command -v 7z >/dev/null 2>&1; then
    echo "Error: 7zip is not installed. Please install 7zip to use this function."
    return 1
  fi

  local source_dir="$1"
  if [[ ! -d $source_dir ]]; then
    echo "Error: '$source_dir' is not a valid directory"
    return 1
  fi

  local archive_name
  if [[ -n $2 ]]; then
    archive_name="$2"
  else
    archive_name="$(basename "$source_dir")_$(date +%Y%m%d_%H%M%S).7z"
  fi

  # Ensure the archive name ends with .7z
  [[ "$archive_name" != *.7z ]] && archive_name="${archive_name}.7z"

  # Prompt for password
  echo "Enter password for encryption:"
  read -r -s password

  if [[ -z $password ]]; then
    echo "Error: Password cannot be empty"
    return 1
  fi

  # Add automatic exclusions if enabled
  if $auto_exclude; then
    exclude_list+=(".git" ".direnv" ".venv")
  fi

  # Prepare the exclude options for 7z
  local exclude_opts=()
  for exclude in "${exclude_list[@]}"; do
    exclude_opts+=("-xr!*/${exclude}" "-xr!${exclude}")
  done

  # Use the password with 7z
  if 7z a -mhe=on -p"$password" "${exclude_opts[@]}" "$archive_name" "$source_dir"; then
    echo "Archive created successfully: $archive_name"
  else
    echo "Error creating archive"
    return 1
  fi
}

# Function: archive_extract
# Description: Extracts the contents of an archive file.
# Parameters:
#   - archive_file: The path to the archive file to be extracted.
# Returns:
#   - 0 if the extraction is successful.
#   - 1 if there is an error during the extraction process.
# Dependencies:
#   - unzip: Used to extract zip and jar files.
#   - jar (JDK): Used to extract jar files.
#   - 7z: Used to extract zip and jar files.
#   - zip: Used to extract zip files.
archive_extract() {
  if [ $# -eq 0 ]; then
    echo "Usage: archive_extract <archive_file>"
    return 1
  fi

  local archive_file="$1"

  if [ ! -f "$archive_file" ]; then
    echo "Error: File '$archive_file' not found."
    return 1
  fi

  local file_extension="${archive_file##*.}"

  case "$file_extension" in
    zip | jar)
      if command -v unzip >/dev/null 2>&1; then
        echo "Using unzip to extract $archive_file"
        unzip "$archive_file"
      elif [ "$file_extension" = "jar" ] && command -v jar >/dev/null 2>&1; then
        echo "Using jar to extract $archive_file"
        jar xf "$archive_file"
      elif command -v 7z >/dev/null 2>&1; then
        echo "Using 7z to extract $archive_file"
        7z x "$archive_file"
      elif command -v zip >/dev/null 2>&1; then
        echo "Using zip to extract $archive_file"
        zip -d "$archive_file"
      else
        echo "Error: No suitable tool found to extract the archive."
        echo "Please install unzip, jar (JDK), 7z, or zip."
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported file extension: .$file_extension"
      return 1
      ;;
  esac
}

# Function: archive_view
# Description: This function is used to view the contents of an archive file.
# Parameters:
#   - archive_file: The path to the archive file.
# Returns:
#   - 0: If the archive file is successfully viewed.
#   - 1: If there is an error viewing the archive file.
# Usage: archive_view <archive_file>
archive_view() {
  if [ $# -eq 0 ]; then
    echo "Usage: archive_view <archive_file>"
    return 1
  fi

  local archive_file="$1"

  if [ ! -f "$archive_file" ]; then
    echo "Error: File '$archive_file' not found."
    return 1
  fi

  local file_extension="${archive_file##*.}"

  case "$file_extension" in
    zip | jar)
      if command -v unzip >/dev/null 2>&1; then
        echo "Using unzip to view contents of $archive_file"
        unzip -l "$archive_file"
      elif [ "$file_extension" = "jar" ] && command -v jar >/dev/null 2>&1; then
        echo "Using jar to view contents of $archive_file"
        jar tf "$archive_file"
      elif command -v 7z >/dev/null 2>&1; then
        echo "Using 7z to view contents of $archive_file"
        7z l "$archive_file"
      elif command -v zipinfo >/dev/null 2>&1; then
        echo "Using zipinfo to view contents of $archive_file"
        zipinfo -1 "$archive_file"
      else
        echo "Error: No suitable tool found to view archive contents."
        echo "Please install unzip, jar (JDK), 7z, or zipinfo."
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported file extension: .$file_extension"
      return 1
      ;;
  esac
}

alias jar_view=archive_view
alias jar_extract=archive_extract
