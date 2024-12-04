if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

pip_patch_env_use_system_store_certs() {
  pip install --trusted-host files.pythonhosted.org pip_system_certs
}

pip_show_pkg_details() {
  local verbose=false
  local json_output=false
  local path_only=false
  local check_deps=false

  read -r -d '' USAGE <<EOF
pip_show_pkg_details - Display detailed information about Python packages installed via pip or pipx

Usage: pip_show_pkg_details [OPTIONS] <package_name>

Options:
    -h, --help              Show this help message
    -v, --verbose          Enable verbose output
    -d, --dependencies     Show package dependencies
    -p, --path-only        Show only package installation path
    -j, --json             Output in JSON format

Examples:
    pip_show_pkg_details requests          # Basic info
    pip_show_pkg_details -v pytest         # Verbose info
    pip_show_pkg_details -d pandas         # Show dependencies
    pip_show_pkg_details -j flask          # JSON output

Environment:
    PYTHON_PATH            Override Python path

Exit codes:
    0  Success
    1  Package not found
    2  Invalid arguments
EOF

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        printf "%s\n" "$USAGE"
        return 0
        ;;
      -v | --verbose) verbose=true ;;
      -d | --dependencies) check_deps=true ;;
      -p | --path-only) path_only=true ;;
      -j | --json) json_output=true ;;
      -*)
        printf "\033[31mError: Unknown option %s\033[0m\n" "$1"
        return 2
        ;;
      *)
        package="$1"
        ;;
    esac
    shift
  done

  if [ -z "$package" ]; then
    printf "\033[31mError: Package name required\033[0m\n"
    printf "\nRun 'pip_show_pkg_details --help' for usage\n"
    return 2
  fi

  local version location install_type dependencies python_version

  if ! command -v pip >/dev/null 2>&1; then
    printf "\033[31mError: pip is not installed\033[0m\n"
    return 1
  fi

  if pip show "$package" >/dev/null 2>&1; then
    version=$(pip show "$package" | grep '^Version:' | cut -d ' ' -f 2)
    location=$(pip show "$package" | grep '^Location:' | cut -d ' ' -f 2)
    install_type="pip"
    [ "$check_deps" = true ] && dependencies=$(pip show "$package" | grep -A100 '^Requires:' | grep -v '^Requires:' | grep -v '^$' | head -n1)
  elif command -v pipx >/dev/null 2>&1 && pipx list | grep -q "$package"; then
    version=$(pipx list | grep "$package" | cut -d ' ' -f 2 | tr -d '()')
    location=$(pipx list | grep "$package" | awk '{print $NF}')
    install_type="pipx"
    [ "$check_deps" = true ] && dependencies=$(pipx runpip "$package" freeze | grep -v "^$package==")
  else
    printf "\033[31mError: Package '%s' not found via pip or pipx\033[0m\n" "$package"
    return 1
  fi

  if [ "$path_only" = true ]; then
    printf "%s\n" "$location"
    return 0
  fi

  if [ "$json_output" = true ]; then
    printf '{\n'
    printf '  "python_version": "%s",\n' "$python_version"
    printf '  "package": "%s",\n' "$package"
    printf '  "version": "%s",\n' "$version"
    printf '  "install_type": "%s",\n' "$install_type"
    printf '  "location": "%s"' "$location"
    [ "$check_deps" = true ] && printf ',\n  "dependencies": "%s"' "$dependencies"
    printf '\n}\n'
    return 0
  fi

  printf "\033[1;34mPython Version:\033[0m %s\n" "$python_version"
  printf "\033[1;34mPackage:\033[0m %s\n" "$package"
  printf "\033[1;34mVersion:\033[0m %s\n" "$version"
  printf "\033[1;34mInstalled via:\033[0m %s\n" "$install_type"
  printf "\033[1;34mLocation:\033[0m %s\n" "$location"

  [ "$check_deps" = true ] && printf "\033[1;34mDependencies:\033[0m %s\n" "$dependencies"

  if [ "$verbose" = true ] && [ -d "$location/$package" ]; then
    printf "\n\033[1;34mPackage files:\033[0m\n"
    ls -la "$location/$package"
  fi

  return 0
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
