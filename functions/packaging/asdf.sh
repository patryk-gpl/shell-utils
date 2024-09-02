# Functions to work with asdf tool

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Function: asdf_install_plugins
#
# Description: Installs plugins for asdf version manager.
#
# Parameters:
#   - plugin1, plugin2, ...: Names of the plugins to be installed.
#
# Returns:
#   - 0: If the plugins are successfully installed.
#   - 1: If asdf is not installed or if no plugin names are provided.
#
# Usage: asdf_install_plugins plugin1 plugin2 ...
#
# Example:
#   asdf_install_plugins java nodejs
#
#   This will install the plugins 'java' and 'nodejs' using asdf.
asdf_install_plugins() {
  if ! command -v asdf &>/dev/null; then
    echo "asdf is not installed. Please install asdf first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Usage: asdf_install_plugins plugin1 plugin2 ..."
    echo "Please provide at least one plugin name."
    return 1
  fi

  for plugin in "$@"; do
    echo "Installing plugin: $plugin"
    if asdf plugin list | grep -q "^$plugin$"; then
      echo "Plugin $plugin is already installed. Skipping."
    else
      if asdf plugin add "$plugin"; then
        echo "Successfully added plugin: $plugin"
      else
        echo "Failed to add plugin: $plugin"
      fi
    fi
  done

  echo "Finished installing plugins."
}

# Function: asdf_install_latest
#
# Description: Installs the latest version of specified tools using asdf.
#
# Usage: asdf_install_latest tool1 tool2 ...
#
# Parameters:
#   - tool1, tool2, ...: Names of the tools to be installed.
#
# Returns:
#   - 0: If all specified tools have been processed successfully.
#   - 1: If asdf is not installed or if no tool name is provided.
#
# Notes:
#   - This function requires asdf to be installed.
#   - It checks if the plugin for each tool is installed and attempts to add it if not.
#   - It installs the latest version of each tool and sets it as global.
#   - If any step fails, it skips to the next tool.
#   - The progress and status of each tool installation is printed to the console.
asdf_install_latest() {
  if ! command -v asdf &>/dev/null; then
    echo "asdf is not installed. Please install asdf first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Usage: asdf_install_latest tool1 tool2 ..."
    echo "Please provide at least one tool name."
    return 1
  fi

  for tool in "$@"; do
    echo "Processing $tool..."
    if ! asdf plugin list | grep -q "^$tool$"; then
      echo "Plugin for $tool is not installed. Attempting to add..."
      if ! asdf plugin add "$tool"; then
        echo "Failed to add plugin for $tool. Skipping."
        continue
      fi
    fi

    echo "Installing latest version of $tool..."
    if latest_version=$(asdf latest "$tool"); then
      if asdf install "$tool" "$latest_version"; then
        echo "Successfully installed $tool $latest_version"
        echo "Setting $tool $latest_version as global..."
        if asdf global "$tool" "$latest_version"; then
          echo "$tool $latest_version is now set as global"
        else
          echo "Failed to set $tool $latest_version as global"
        fi
      else
        echo "Failed to install $tool $latest_version"
      fi
    else
      echo "Failed to determine latest version for $tool"
    fi

    echo "Finished processing $tool"
    echo "------------------------"
  done

  echo "All specified tools have been processed."
}

asdf_plugin_show_install_script() {
  if ! command -v asdf &>/dev/null; then
    echo "Error: asdf is not installed."
    return 1
  fi

  local plugin_name=$1
  if [[ -z $plugin_name ]]; then
    echo "Error: Plugin name is missing."
    echo "Available installed plugins:"
    asdf plugin list
    return 1
  fi

  local bin_path="$HOME/.asdf/plugins/$plugin_name/bin/install"

  if [[ -f $bin_path ]]; then
    echo "== Content of the install script for plugin '$plugin_name' =="
    if command -v bat &>/dev/null; then
      bat "$bin_path"
    else
      cat "$bin_path"
    fi
  else
    echo "Error: Install script for plugin '$plugin_name' does not exist."
    return 1
  fi
}
