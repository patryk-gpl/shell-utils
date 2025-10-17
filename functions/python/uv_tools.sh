#!/usr/bin/env bash
# Helpers for uv tool management

# uv_tools_reinstall_missing
# - Calls `uv tool list`, finds tools whose environments are missing, and
#   reinstalls them using `uv tool install <tool> --reinstall`.
# - The function prints status (SUCCESS/FAIL) after each install attempt.
uv_tools_reinstall_missing() {
  local output

  if ! output="$(uv tool list 2>&1)"; then
    printf 'Error: running "uv tool list" failed:\n%s\n' "$output" >&2
    return 1
  fi

  # Echo the original uv output for visibility
  printf '%s\n' "$output"

  # Extract missing tool names from lines like:
  local -a missing
  # Use single-quoted field separator to avoid shell backtick parsing issues
  missing=()
  while IFS= read -r tool; do
    missing+=("$tool")
  done < <(printf '%s\n' "$output" | awk -F'`' '/warning: Tool .* environment not found/ {print $2}')

  if [ "${#missing[@]}" -eq 0 ]; then
    echo "No missing tools found."
    return 0
  fi

  local tool
  for tool in "${missing[@]}"; do
    printf '\nReinstalling tool: %s\n' "$tool"

    if uv tool install "$tool" --reinstall; then
      printf 'SUCCESS: %s reinstalled.\n' "$tool"
    else
      printf 'FAIL: %s failed to reinstall.\n' "$tool" >&2
    fi
  done

  return 0
}
