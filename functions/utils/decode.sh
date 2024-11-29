decode_base64_url() {
  # Replace URL-safe characters with standard Base64 characters.
  local input=$1
  input=${input//-/+}
  input=${input//_/\/}

  # Pad with '=' if necessary
  local mod4=$((${#input} % 4))
  if ((mod4 != 0)); then
    input="${input}$(printf '%0.s=' $(seq $((4 - mod4))))"
  fi

  echo "$input" | base64 -d 2>/dev/null
}

decode_jwt() {
  if [[ -z "$1" ]]; then
    echo -e "Usage: decode_jwt <jwt>\nSplits and decodes a JSON Web Token."
    return
  fi

  local jwt=$1
  local delimiter_count

  delimiter_count=$(grep -o '\.' <<<"$jwt" | wc -l)
  if [[ "$delimiter_count" -ne 2 ]]; then
    echo "Error: Invalid JWT format. A JWT must contain exactly two dots."
    return 1
  fi

  IFS='.' read -r header payload signature <<<"$jwt"
  if [[ -z "$header" || -z "$payload" || -z "$signature" ]]; then
    echo "Error: JWT parts cannot be empty."
    return 1
  fi

  echo "Header:"
  decode_base64_url "$header" | jq .

  echo "Payload:"
  decode_base64_url "$payload" | jq .

  echo "Signature (Base64Url):"
  echo "$signature"
}

decode_base64() {
  local input="$1"
  local decoded="$input"
  local temp

  if [ -z "$input" ]; then
    echo "Error: input is empty." >&2
    return 1
  fi

  while true; do
    if temp=$(echo -n "$decoded" | base64 -d 2>/dev/null) && [ -n "$temp" ]; then
      if [ "$temp" = "$decoded" ]; then
        break
      fi

      if echo -n "$temp" | LC_ALL=C grep -q '[^[:print:][:space:]]'; then
        break
      fi

      decoded="$temp"
    else
      break
    fi
  done

  printf '%s' "$decoded"
  printf '\n'
}
