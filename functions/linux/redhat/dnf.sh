if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

redhat_linux_upgrade_all() {
  echo "Updating package lists..."
  sudo dnf check-update

  echo "Upgrading all packages..."
  sudo dnf upgrade -y

  echo "Cleaning up package cache..."
  sudo dnf clean all

  if [ -f /var/run/reboot-required ]; then
    echo "A system reboot is required to complete the upgrade."
    read -p "Do you want to reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Rebooting the system..."
      sudo reboot
    else
      echo "Please remember to reboot your system later to complete the upgrade."
    fi
  else
    echo "Upgrade completed successfully. No reboot required."
  fi
}

alias centos_linux_upgrade_all="redhat_linux_upgrade_all"
