curl_ip_info() {
  if [[ -z "$1" ]]; then
    echo "Usage: curl_ip_info <IP_ADDRESS>"
    return 1
  fi
  curl -s "https://ipinfo.io/$1" | jq .
}
