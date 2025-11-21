pypi_server_start() {
  if ! pypi-server --version &>/dev/null; then
    echo "pypi-server is not installed. Install with pipx or uv tool..."
    return 1
  fi
  local dir="$HOME/local-pypi"
  mkdir -p "$dir"
  echo "Starting pypi-server on port 8080 serving $dir"
  pypi-server run -p 8080 "$dir"
}

pypi_server_stop() {
  local pid
  pid=$(pgrep -f "pypi-server -p 8080")

  if [ -n "$pid" ]; then
    kill "$pid"
    echo "pypi-server stopped."
  else
    echo "pypi-server is not running."
  fi
}

pypi_name_check() {
  # 1. Internal helper for help text
  _cpn_usage() {
    cat <<EOF
Usage: pypi_name_check [OPTIONS] <package_name>

Description:
    Checks if a package name is available on both the main PyPI index
    and the TestPyPI index using the JSON API.

Options:
    -h, --help    Show this help message and exit.
    -v, --verbose Show the specific URLs being checked.

Output:
    Returns colored status indicating if the name is:
    - AVAILABLE (404 Not Found)
    - TAKEN     (200 OK)
    - ERROR     (Other HTTP status)

Example:
    pypi_name_check my-cool-tools
EOF
  }

  # 2. Internal helper for the logic
  _cpn_check_status() {
    local repo_label="$1"
    local json_url="$2"
    local verbose="$3"
    local http_code
    local c_reset="\033[0m"
    local c_green="\033[32m"
    local c_red="\033[31m"
    local c_bold="\033[1m"
    local c_dim="\033[2m"

    # If verbose, print the URL being checked
    if [[ "$verbose" == "true" ]]; then
      printf "  %s Checking URL: %s\n" "$c_dim" "$json_url"
      printf "%s" "$c_reset"
    fi

    printf "  %-12s ... " "${repo_label}"

    # We use GET (-L to follow redirects) instead of HEAD to avoid
    # "soft 404" issues or proxy caching weirdness.
    # -s: Silent
    # -o /dev/null: Discard the JSON body
    # -w: Write out the HTTP code
    http_code=$(curl -s -o /dev/null -L -w "%{http_code}" "$json_url")

    if [[ "$http_code" == "404" ]]; then
      printf "${c_green}%s${c_reset}\n" "AVAILABLE"
      return 0
    elif [[ "$http_code" == "200" ]]; then
      printf "${c_red}%s${c_reset}\n" "TAKEN"
      return 1
    else
      printf "${c_bold}ERROR (%s)${c_reset}\n" "$http_code"
      return 2
    fi
  }

  local package_name=""
  local verbose="false"

  # 3. Argument Parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        _cpn_usage
        return 0
        ;;
      -v | --verbose)
        verbose="true"
        ;;
      *)
        if [[ -z "$package_name" ]]; then
          package_name="$1"
        else
          printf "Error: Too many arguments provided.\n" >&2
          _cpn_usage
          return 1
        fi
        ;;
    esac
    shift
  done

  # 4. Validation
  if [[ -z "$package_name" ]]; then
    printf "Error: Missing package name.\n" >&2
    _cpn_usage
    return 1
  fi

  printf "Checking availability for: \033[1m%s\033[0m\n" "$package_name"

  # 5. Execute Checks using the JSON API
  # Pattern: https://pypi.org/pypi/<name>/json

  _cpn_check_status "[PyPI]" \
    "https://pypi.org/pypi/${package_name}/json" \
    "$verbose"

  _cpn_check_status "[TestPyPI]" \
    "https://test.pypi.org/pypi/${package_name}/json" \
    "$verbose"
}
