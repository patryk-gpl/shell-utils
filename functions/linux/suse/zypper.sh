if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

suse_upgrade_all() {
  echo "Refreshing repositories..."
  sudo zypper refresh

  echo "Updating all packages..."
  sudo zypper update -y

  echo "Performing distribution upgrade..."
  sudo zypper dup -y

  echo "Cleaning up package cache..."
  sudo zypper clean -a

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
