if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

pip_patch_env_use_system_store_certs() {
  pip install --trusted-host files.pythonhosted.org pip_system_certs
}

pip_package_version_check() {
  local debug_mode=0
  local pkg_name=""

  local help_text="Usage: pip_package_version_check [options] <package_name>
Options:
  -d, --debug    Enable debug mode
  -h, --help     Display this help message"

  for arg in "$@"; do
    case $arg in
      -d | --debug)
        debug_mode=1
        ;;
      -h | --help)
        echo "$help_text"
        return 0
        ;;
      *)
        if [[ -z "$pkg_name" ]]; then
          pkg_name="$arg"
        else
          echo "Error: Multiple package names specified."
          echo "$help_text"
          return 1
        fi
        ;;
    esac
  done

  if [[ -z "$pkg_name" ]]; then
    echo "Error: Package name is required."
    echo "$help_text"
    return 1
  fi

  [[ $debug_mode -eq 1 ]] && echo "Package name: $pkg_name"

  local pip_version
  pip_version=$(pip --version | awk '{print $2}')
  [[ $debug_mode -eq 1 ]] && echo "Pip version: $pip_version"

  local pip_version_parsed
  pip_version_parsed=$(echo "$pip_version" | awk -F. '{ printf("%d%02d%02d", $1, $2, $3); }')
  [[ $debug_mode -eq 1 ]] && echo "Parsed pip version: $pip_version_parsed"

  local pip_21_2=210200
  local pip_09_0=90000

  if ((pip_version_parsed >= pip_21_2)); then
    [[ $debug_mode -eq 1 ]] && echo "Using: pip index versions $pkg_name"
    pip index versions "$pkg_name"
  elif ((pip_version_parsed >= pip_09_0)); then
    [[ $debug_mode -eq 1 ]] && echo "Listing available versions for $pkg_name:"
    pip install "$pkg_name==" 2>&1 | grep -oP '(?<=from\s+versions:\s).*(?=\n)' || echo "No versions found or command failed."
  else
    [[ $debug_mode -eq 1 ]] && echo "Using: pip install $pkg_name==blork"
    pip install "$pkg_name==blork"
  fi
}
