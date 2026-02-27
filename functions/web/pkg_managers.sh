pnpm2bun_migrate() {
  if [[ $# -eq 1 ]] && [[ "$1" =~ ^(-h|--help)$ ]]; then
    _pnpm2bun_show_help
    return 0
  fi

  local -a packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    _pnpm2bun_show_help >&2
    return 1
  fi

  _check_cmd "pnpm" || return 1
  _check_cmd "bun" || return 1

  local pkg
  local failed_count=0

  for pkg in "${packages[@]}"; do
    _pnpm2bun_migrate_package "$pkg" || ((failed_count++))
  done

  if [[ $failed_count -gt 0 ]]; then
    echo "Error: $failed_count package(s) failed to migrate." >&2
    return 1
  fi
}

_pnpm2bun_show_help() {
  cat <<'EOF'
migrate packages from pnpm to bun

Usage: pnpm2bun_migrate <package-name> [package-name ...]

Description:
  Uninstalls one or more global packages from pnpm and installs them globally via bun.

Arguments:
  <package-name>  Package name to migrate (required, multiple allowed)

Options:
  -h, --help      Show this help message

Examples:
  pnpm2bun_migrate lodash
  pnpm2bun_migrate lodash axios express

Dependencies:
  - pnpm (must be installed and in PATH)
  - bun (must be installed and in PATH)
EOF
}

_pnpm2bun_migrate_package() {
  local pkg="$1"

  echo "Migrating '$pkg': uninstalling from pnpm..."
  if ! pnpm remove -g "$pkg"; then
    echo "Error: pnpm failed to uninstall '$pkg'." >&2
    return 1
  fi

  echo "Installing '$pkg' via bun..."
  if ! bun add -g "$pkg"; then
    echo "Warning: bun failed to install '$pkg'." >&2
    return 1
  fi
}

_check_cmd() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is not installed or not in PATH." >&2
    return 1
  fi
}
