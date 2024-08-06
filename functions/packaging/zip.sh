if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

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
