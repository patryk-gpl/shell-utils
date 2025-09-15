#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Function: create_python_venv_with_uv
#
# Description:
#   Sets up a Python virtual environment using 'uv' if it does not already exist.
#   Watches the 'pyproject.toml' file for changes and updates dependencies
#   in the virtual environment based on 'uv.lock' when necessary.
#   Maintains a sentinel file to track dependency synchronization.
#   Ensures 'pre-commit' is installed globally, installs its hooks if present,
#   and exits with an error if 'uv' or 'pre-commit' is missing.
#
# Usage:
#   Call this function from your shell script to initialize and manage
#   a Python virtual environment with dependency synchronization and
#   pre-commit hook setup.
#
# Arguments:
#   None
#
# Requirements:
#   - 'uv' must be installed and available in PATH.
#   - 'pre-commit' must be installed globally.
#
# Effects:
#   - Creates a '.venv' directory if it does not exist.
#   - Installs dependencies using 'uv sync' when 'uv.lock' changes.
#   - Updates or creates a sentinel file at '.venv/uv_installed.sentinel'.
#   - Installs pre-commit hooks in the repository.
# -----------------------------------------------------------------------------
create_python_venv_with_uv() {
  for cmd in uv pre-commit; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "\033[31mERROR: '$cmd' must be installed globally. Please install it and try again.\033[0m"
      exit 1
    fi
  done

  # Create a venv, if not exist yet
  if [[ ! -d ".venv" ]]; then
    echo -e "\033[33mCreating virtualenv at .venv\033[0m"
    uv venv
    uv pip list
  fi

  # Watch the pyproject.toml file for changes
  watch_file pyproject.toml
  uv_sentinel=".venv/uv_installed.sentinel"

  if [[ ! -f "$uv_sentinel" || "uv.lock" -nt "$uv_sentinel" ]]; then
    echo -e "\033[33mSyncing dependencies with uv sync\033[0m"
    uv sync

    # Create or update the sentinel file
    echo -e "\033[33mUpdating sentinel lock file: $uv_sentinel\033[0m"
    touch "$uv_sentinel"
  fi

  echo -e "\033[32mUsing pre-commit $(pre-commit --version)\033[0m"
  pre-commit install >/dev/null
}

# Github issues:
# - Add possibility to react on file changes more granularly: https://github.com/direnv/direnv/issues/1194
