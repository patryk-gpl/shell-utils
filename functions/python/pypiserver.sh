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
