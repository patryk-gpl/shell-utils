# Checks the public IP address of the current machine.
# This function retrieves and displays the public IP address by querying an external service.
#
# Usage:
#   network_check_my_ip
#
# Example:
#   $ network_check_my_ip
#   Your public IP address is: 203.0.113.42
network_check_my_ip() {
  local services=(
    "ifconfig.me"
    "api.ipify.org"
    "icanhazip.com"
    "checkip.amazonaws.com"
    "ipinfo.io/ip"
    "ident.me"
    "ipecho.net/plain"
    "wtfismyip.com/text"
    "ip.tyk.nu"
    "myip.dnsomatic.com"
    "ifconfig.co"
    "ipaddr.site"
  )

  for service in "${services[@]}"; do
    echo "Checking IP using $service..."
    if ip=$(curl -s -m 5 "$service"); then
      echo "Your IP: $ip"
      return 0
    else
      echo "Failed to get IP from $service"
    fi
    echo
  done

  echo "Failed to retrieve IP from all services."
  return 1
}
