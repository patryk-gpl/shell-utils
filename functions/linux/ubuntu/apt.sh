#!/usr/bin/env bash
# This file contains functions to work with Ubuntu apt package manager

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

apt_history_recent(){
  case "$1" in
    install)
          grep 'install ' /var/log/dpkg.log
          ;;
    upgrade|remove)
          grep "$1" /var/log/dpkg.log
          ;;
    rollback)
          grep upgrade /var/log/dpkg.log | \
              grep "$2" -A10000000 | \
              grep "$3" -B10000000 | \
              awk '{print $4"="$5}'
          ;;
    all)
          cat /var/log/dpkg.log
          ;;
    *)
          echo "Usage: ${FUNCNAME[0]} <install|upgrade|remove|rollback|all> [package_name] [version]"
esac
}
