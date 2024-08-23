if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

pip_patch_env_use_system_store_certs() {
  pip install --trusted-host files.pythonhosted.org pip_system_certs
}
