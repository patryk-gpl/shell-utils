#!/usr/bin/env bash
#####################################################################################
# Syntax: sudo /path/etc_hosts_updater.sh <ip1> <hostname1> [<ip2> <hostname2> ...]
#####################################################################################

# NAME
#     wsl_update_etc_hosts - Persistently update /etc/hosts in WSL 2
#
# SYNOPSIS
#     sudo wsl_update_etc_hosts <ip1> <hostname1> [<ip2> <hostname2> ...]
#
# DESCRIPTION
#     The wsl_update_etc_hosts function allows users to add custom host entries
#     to the /etc/hosts file in WSL 2 (Windows Subsystem for Linux 2) that persist
#     across restarts. It creates a startup script that updates the /etc/hosts file
#     each time WSL starts, ensuring that custom entries are always present.
#
# OPTIONS
#     <ip>        The IP address for the host entry.
#     <hostname>  The hostname associated with the IP address.
#
#     Multiple IP-hostname pairs can be specified.
#
# USAGE
#     To use this function, you need to run it with sudo privileges:
#     sudo wsl_update_etc_hosts 192.168.1.100 myserver.local 10.0.0.1 another.server
#
# NOTES
#     - This function must be run with sudo or as root.
#     - Changes will take effect after restarting WSL.
#     - To apply changes immediately without restarting WSL, run the generated
#       startup script manually:
#       sudo /etc/wsl-startup.sh
#
# FILES
#     /etc/wsl-startup.sh  The generated startup script that updates /etc/hosts
#     /etc/wsl.conf        WSL configuration file, modified to run the startup script
#
# EXAMPLES
#     1. Add a single host entry:
#        sudo wsl_update_etc_hosts 192.168.1.100 myserver.local
#
#     2. Add multiple host entries:
#        sudo wsl_update_etc_hosts 192.168.1.100 myserver.local 10.0.0.1 another.server
#
# EXIT STATUS
#     0   Success
#     1   Error (invalid input, insufficient permissions, etc.)
wsl_update_etc_hosts() {
  local wsl_startup_script="/etc/wsl-startup.sh"
  local wsl_conf="/etc/wsl.conf"

  # Check if any arguments were provided
  if [ $# -eq 0 ]; then
    echo "Error: No IP and hostname pairs provided."
    echo "Usage: wsl_update_etc_hosts <ip1> <hostname1> [<ip2> <hostname2> ...]"
    return 1
  fi

  # Create or update the WSL startup script
  cat >"$wsl_startup_script" <<EOL
#!/bin/bash
# This script updates /etc/hosts with custom entries
EOL

  # Process input arguments
  while [[ $# -gt 0 ]]; do
    local ip="$1"
    local hostname="$2"
    if [[ -z "$ip" || -z "$hostname" ]]; then
      echo "Error: Invalid input. Please provide IP and hostname pairs."
      return 1
    fi
    echo "echo \"$ip $hostname\" | tee -a /etc/hosts > /dev/null" >>"$wsl_startup_script"
    shift 2
  done

  # Make the startup script executable
  chmod +x "$wsl_startup_script"

  # Ensure the WSL config file exists and has the correct boot command
  if [ ! -f "$wsl_conf" ]; then
    echo "[boot]" >"$wsl_conf"
    echo "command = $wsl_startup_script" >>"$wsl_conf"
  else
    if ! grep -q "\[boot\]" "$wsl_conf"; then
      echo -e "\n[boot]" >>"$wsl_conf"
    fi
    if ! grep -q "command = $wsl_startup_script" "$wsl_conf"; then
      sed -i '/\[boot\]/a command = '"$wsl_startup_script" "$wsl_conf"
    fi
  fi

  echo "Custom /etc/hosts entries have been set up to persist across WSL restarts."
  echo "Changes will take effect after restarting WSL."
  echo "To apply changes immediately, run: $wsl_startup_script"
}

# Check if running with root permissions
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo or as root."
  exit 1
fi

# Call the function with all provided arguments
wsl_update_etc_hosts "$@"
