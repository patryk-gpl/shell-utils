# Function: poetry_disable_package_mode
#
# Description: Disables the package mode in a pyproject.toml file for Poetry.
#
# Parameters:
#   - file (optional): The path to the pyproject.toml file. If not provided, it defaults to "pyproject.toml" in the current directory.
# Returns:
#   - 0: If the package mode is successfully disabled.
#   - 1: If there is an error or the pyproject.toml file is not found.
#
# Usage: poetry_disable_package_mode [path/pyproject.toml]
#
# Example:
#   poetry_disable_package_mode
#   poetry_disable_package_mode /path/to/pyproject.toml
poetry_disable_package_mode() {
  local file="${1:-pyproject.toml}"
  local temp_file="${file}.tmp"
  local section="[tool.poetry]"
  local setting="package-mode = false"

  if [ ! -f "$file" ]; then
    echo "Error: $file not found."
    echo "Syntax: poetry_disable_package_mode [path/pyproject.toml]"
    return 1
  fi

  if ! grep -q '^\[tool\.poetry\]' "$file"; then
    echo "Error: [tool.poetry] section not found in $file."
    return 1
  fi

  # Process the file
  awk -v section="$section" -v setting="$setting" '
    BEGIN { in_section = 0; setting_added = 0; }
    {
        if ($0 ~ "^\\[.*\\]") {
            if (in_section == 1 && setting_added == 0) {
                print setting
            }
            in_section = ($0 == section) ? 1 : 0
            setting_added = 0
        } else if (in_section == 1 && $0 ~ "^package-mode\\s*=") {
            if ($0 != setting) {
                print setting
                setting_added = 1
                next
            } else {
                setting_added = 1
            }
        } else if (in_section == 1 && setting_added == 0 && NF == 0) {
            print setting
            setting_added = 1
        }
        print $0
    }
    END {
        if (in_section == 1 && setting_added == 0) {
            print setting
        }
    }
    ' "$file" >"$temp_file"

  # Check if the file has changed
  if cmp -s "$file" "$temp_file"; then
    rm "$temp_file"
    echo "No changes needed. '$setting' is already correctly set in $file."
  else
    mv "$temp_file" "$file"
    echo "Successfully added or updated '$setting' in $file."
  fi
}

poetry() {
  if [[ "$1" == "init" ]]; then
    shift # Remove 'init' from the arguments

    local custom_name="Patryk Kubiak"
    local custom_email="Patryk.Kubiak@gmail.com"
    local repo_url
    local use_custom=false

    if builtin command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      repo_url=$(git config --get remote.origin.url)
      if [[ $repo_url == *"github.com"* ]]; then
        use_custom=true
      fi
    fi

    if $use_custom; then
      echo "GitHub repository detected. Using custom author details:"
      echo "Name: $custom_name, Email: $custom_email"
      POETRY_NAME="$custom_name" POETRY_EMAIL="$custom_email" builtin command poetry init "$@"
    else
      echo "Non-GitHub repository or no repository detected. Using default Poetry settings."
      builtin command poetry init "$@"
    fi
  else
    builtin command poetry "$@"
  fi
}
