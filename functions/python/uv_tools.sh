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

uv_venv_from_requirements() {
  if [[ $# -gt 1 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    cat <<EOF
uv_venv_from_requirements - Create a Python virtual environment in .venv and install requirements using uv.

Usage:
  uv_venv_from_requirements [requirements_file]

Arguments:
  [requirements_file]   Optional path to requirements.txt file (default: ./requirements.txt)

This function always creates the virtual environment in the .venv directory in the current working directory.
EOF
    return 0
  fi

  local venv_dir=".venv"
  local requirements_file

  if [[ $# -eq 0 ]]; then
    requirements_file="requirements.txt"
  else
    requirements_file="$1"
  fi

  if [[ ! -f "$requirements_file" ]]; then
    printf 'Error: requirements file "%s" does not exist in the current directory or as specified.\n' "$requirements_file" >&2
    return 1
  fi

  if [[ -d "$venv_dir" ]]; then
    printf 'Warning: virtual environment directory "%s" already exists. Reusing it.\n' "$venv_dir" >&2
  else
    if ! uv venv "$venv_dir"; then
      printf 'Error: Failed to create virtual environment in %s\n' "$venv_dir" >&2
      return 1
    fi
  fi

  if ! uv pip install -r "$requirements_file"; then
    printf 'Error: Failed to install packages from %s using uv pip\n' "$requirements_file" >&2
    return 1
  fi

  printf 'Virtual environment setup complete in %s\n' "$venv_dir"
  return 0
}
