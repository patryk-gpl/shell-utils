taplo_check_uv_global() {
  if ! command -v "uvx" &>/dev/null; then
    printf 'Error: %s is not installed. Please install it to use this function.\n' "uvx" >&2
    return 1
  fi

  local schema="https://raw.githubusercontent.com/astral-sh/uv/main/uv.schema.json"
  local file_path="${1:-$HOME/.config/uv/config.toml}"

  if [[ -z "$file_path" ]]; then
    printf 'Error: No file path provided. Please provide a file path to check against the schema.\n' >&2
    return 1
  fi
  echo "Checking $file_path against schema: $schema"
  uvx taplo check --schema "$schema" "$file_path"
}
