if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

pypi_setup_local_registry() {
  if [[ ! -d "$HOME/.virtualenvs" ]]; then
    mkdir -p "$HOME/.virtualenvs"
  fi

  local venv_dir="$HOME/.virtualenvs/pypiserver"
  echo "Creating and activating virtual environment at $venv_dir..."
  python3 -m venv "$venv_dir"
  # shellcheck disable=SC1091
  source "$venv_dir/bin/activate"
  echo "Virtual environment activated."

  pip install --upgrade pip
  echo "pip upgraded."

  # Install pypiserver within the virtual environment
  pip install pypiserver
  echo "pypiserver installed."

  # Create a directory for packages
  local package_dir="$HOME/packages"
  if mkdir -p "$package_dir"; then
    cd "$package_dir" || {
      echo "Failed to change to package directory"
      return 1
    }
  else
    echo "Failed to create access package directory"
    return 1
  fi

  # Start the pypiserver in the background within the virtual environment
  echo "Starting pypiserver on http://localhost:8080..."
  pypi-server run -p 8080 -P . -a . --log-file "$venv_dir/pypiserver.log" "$package_dir" &
  local server_pid=$!
  echo "pypiserver started with PID $server_pid."

  # Configure pip within the virtual environment to use the local server
  local pip_conf="$venv_dir/pip.conf"
  mkdir -p "$(dirname "$pip_conf")" && touch "$pip_conf"
  echo "[global]" >"$pip_conf"
  echo "index-url = http://localhost:8080/simple/" >>"$pip_conf"
  echo "Configured pip to use local PyPi server."

  # Configure poetry to use the local server within the virtual environment if available
  if command -v poetry >/dev/null; then
    echo "Configuring poetry..."
    poetry config virtualenvs.in-project true
    poetry config repositories.local http://localhost:8080
    echo "Configured poetry to use local PyPi server."
  else
    echo "Poetry not found. Please install Poetry to use this function."
  fi

  # Instructions for testing
  cat <<EOF
Local PyPi registry setup complete.
To publish a package with poetry, use:
  poetry build
  poetry publish --repository local
To install a package with pip, ensure the virtual environment is active and use:
  pip install <package-name>
To stop the local PyPi server, run:
  kill $server_pid
EOF

  # Deactivate virtual environment
  deactivate
  echo "Virtual environment deactivated."
}
