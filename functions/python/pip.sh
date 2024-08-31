if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

# Function: pip_patch_env_use_system_store_certs
#
# Description:
#   This function installs the 'pip_system_certs' package using pip. It also sets the 'files.pythonhosted.org' as a trusted host.
#
# Usage:
#   pip_patch_env_use_system_store_certs
#
# Returns:
#   None
pip_patch_env_use_system_store_certs() {
  pip install --trusted-host files.pythonhosted.org pip_system_certs
}
