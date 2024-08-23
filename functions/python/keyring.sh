if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

keyring_is_installed() {
  if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo "Python is not installed."
    return 1
  fi

  PYTHON_CMD=$(command -v python3 || command -v python)

  if $PYTHON_CMD -c "import keyring" &>/dev/null; then
    echo "keyring is installed."
    return 0
  else
    echo "keyring is not installed."
    return 1
  fi
}