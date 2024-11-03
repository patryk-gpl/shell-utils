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

gpg_encrypt_with_passphrase() {
  local input_file="$1"
  local output_file="${2:-$input_file.gpg}"

  if [[ -z "$input_file" ]]; then
    echo "Usage: gpg_encrypt_with_passphrase <input_file> [output_file]"
    return 1
  fi

  if gpg --symmetric --cipher-algo AES256 --output "$output_file" "$input_file"; then
    echo "File encrypted successfully: $output_file"
  else
    echo "Encryption failed."
    return 1
  fi
}

gpg_search_key() {
  local key_id="$1"
  shift

  local timeout=10
  local default_keyservers=(
    "keyserver.ubuntu.com"
    "keys.openpgp.org"
    "pgp.mit.edu"
    "keyserver.pgp.com"
    "pgp.key-server.io"
  )

  # Combine default keyservers with any provided as arguments
  local all_keyservers=("${default_keyservers[@]}" "$@")

  if [ -z "$key_id" ]; then
    echo "Usage: gpg_search <key_id> [additional_keyserver1] [additional_keyserver2] ..."
    return 1
  fi

  echo "Searching for key: $key_id"
  echo "Keyservers to be queried: ${all_keyservers[*]}"
  echo "-------------------------------------------"

  for server in "${all_keyservers[@]}"; do
    echo "Searching on $server..."
    if timeout $timeout gpg --keyserver "$server" --keyid-format LONG --locate-keys "$key_id" 2>&1; then
      echo "Key found on $server"
      return 0
    else
      if [ $? -eq 124 ]; then
        echo "Connection to $server timed out after $timeout seconds"
      elif grep -q "keyserver receive failed: No data" /dev/tty; then
        echo "No data received from $server"
      elif grep -q "keyserver receive failed: Server indicated a failure" /dev/tty; then
        echo "Server $server indicated a failure"
      elif grep -q "network error" /dev/tty; then
        echo "Network error occurred while connecting to $server"
      else
        echo "Key not found on $server"
      fi
    fi
    echo "-------------------------------------------"
  done

  echo "Key not found on any of the specified keyservers."
  return 1
}
