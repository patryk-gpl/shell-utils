if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Helper function to export a GPG key
_export_gpg_key() {
  local type="$1"
  local output_dir="$2"

  local key_id="D5B5760DAE881A77D30D3C2BEC9DE6EAF150DA18"
  local file_suffix="${type}key.asc"

  # Determine GPG command based on key type
  if [ "$type" = "public" ]; then
    gpg --export --armor "$key_id" >"$output_dir/$file_suffix"
  elif [ "$type" = "private" ]; then
    gpg --export-secret-keys --armor "$key_id" >"$output_dir/$file_suffix"
  else
    echo "Invalid key type specified: $type"
    return 1
  fi

  echo "$type key exported to $output_dir/$file_suffix"
}

gpg_export_public_key() {
  local output_dir="${2:-$HOME}"
  _export_gpg_key "public" "$output_dir"
}

gpg_export_private_key() {
  local output_dir="${2:-$HOME}"
  _export_gpg_key "private" "$output_dir"
}
