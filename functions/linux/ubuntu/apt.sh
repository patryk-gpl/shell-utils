# Functions to work with Ubuntu apt package manager

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

ubuntu_upgrade_all() {
  echo "Updating package lists..."
  sudo apt update

  echo "Upgrading installed packages..."
  sudo apt upgrade -y

  echo "Performing distribution upgrade..."
  sudo apt dist-upgrade -y

  echo "Removing unnecessary packages..."
  sudo apt autoremove -y

  echo "Cleaning up package cache..."
  sudo apt clean

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

apt_history_recent() {
  case "$1" in
    install)
      grep 'install ' /var/log/dpkg.log
      ;;
    upgrade | remove)
      grep "$1" /var/log/dpkg.log
      ;;
    rollback)
      grep upgrade /var/log/dpkg.log |
        grep "$2" -A10000000 |
        grep "$3" -B10000000 |
        awk '{print $4"="$5}'
      ;;
    all)
      cat /var/log/dpkg.log
      ;;
    *)
      echo "Usage: ${FUNCNAME[0]} <install|upgrade|remove|rollback|all> [package_name] [version]"
      ;;
  esac
}
