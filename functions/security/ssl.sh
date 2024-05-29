#!/usr/bin/env bash
# Functions to work with SSL certificates

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

_ssl_parse_cert_file() {
  cert_file=${1:-}
  if [ -z "$cert_file" ]; then
    echo "Usage: $0 <cert_file.pem>"
    return 1
  fi

  is_installed openssl || return 1
  if [ ! -f "$cert_file" ]; then
    echo "File $cert_file not found"
    return 1
  fi
}

# Main functions

ssl_fetch_fullchain() {
  is_installed openssl awk || return 1
  local url=${1:-}

  if [ -z "$url" ]; then
    echo "Usage: $0 <url> [<output_file=url.pem>]"
    return 1
  fi
  output_file="$url.pem"

  openssl s_client -showcerts -connect "$url" </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' >"$output_file"

  echo "SSL certificate saved to $output_file"
  echo "Number of saved certificate in the chain: $(grep -c 'BEGIN CERTIFICATE' "$output_file")"
}

# Function to fetch SSL certificate from a server
ssl_fetch_cert() {
  is_installed openssl || return 1

  local url=${1:-}
  local port=${2:-443}

  if [ -z "$url" ]; then
    echo "Usage: $0 <url> [<port=443>]"
    return 1
  fi

  echo "Fetching SSL certificate from url=$url, port=$port"
  certificate=$(echo | openssl s_client -showcerts -servername "$url" -connect "$url":"$port" 2>/dev/null |
    openssl x509 -outform PEM)

  if [ -z "$certificate" ]; then
    echo "Unable to obtain SSL certificate from $url"
    return 1
  fi

  file_path="${url}_${port}.pem"
  echo "$certificate" >"$file_path"
  echo "SSL certificate saved to $file_path"
}

ssl_show_cert_details() {
  local url=${1:-}
  local port=${2:-443}

  if [ -z "$url" ]; then
    echo "Usage: $0 <url> [<port=443>]"
    return 1
  fi

  openssl s_client -showcerts -connect "$url:$port" </dev/null 2>/dev/null | openssl x509 -noout -text
}

ssl_show_cert_headers() {
  is_installed openssl awk || return 1
  _ssl_parse_cert_file "$1" || return 1

  echo "== $1 =="
  openssl x509 -in "$1" -text -noout |
    grep -E 'Signature Algorithm:|Subject:|Issuer:|Not Before|Not After|Public Key Algorithm:|Public-Key:|DNS:' |
    awk '!a[$0]++'
}

ssl_check_cert_validity() {
  _ssl_parse_cert_file "$1" || return 1

  day_in_seconds=86400
  if openssl x509 -in "$1" -checkend "$day_in_seconds" -noout; then
    echo "Certificate is still valid"
  else
    echo "Certificate has expired or will expire soon"
  fi
}

ssl_check_cert_ca() {
  _ssl_parse_cert_file "$1" || return 1

  if openssl x509 -in "$1" -text -noout | grep -q 'CA:TRUE'; then
    echo "Certificate is a CA certificate"
  else
    echo "Certificate is not a CA certificate"
  fi
}

ssl_create_self_signed_cert() {
  domain=${1:-}
  if [ -z "$domain" ]; then
    echo "Usage: $0 <domain>"
    return 1
  fi
  is_installed openssl || return 1

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$domain".key -out "$domain".crt
}
