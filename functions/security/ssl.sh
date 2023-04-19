#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with SSL certificates
####################################################################################################

_is_openssl_installed() {
  if ! which openssl >/dev/null; then echo "openssl not found" && return 1; fi
}

_ssl_parse_cert_file() {
  cert_file=${1:-}
  if [ -z "$cert_file" ]; then
    echo "Usage: $0 <cert_file.pem>"
    return 1
  fi

  _is_openssl_installed
  if [ ! -f "$cert_file" ]; then
    echo "File $cert_file not found"
    return 1
  fi
}

# Main functions

# Function to fetch SSL certificate from a server
ssl_fetch_cert() {
  url=${1:-}
  port=${2:-443}
  output_dir=${3:-certs}

  if [ -z "$url" ]; then
    echo "Usage: $0 <url> [<port=443>] [<output_dir=certs>]"
    return 1
  fi
  _is_openssl_installed

  if [ ! -d "$output_dir" ]; then
    echo "Creating directory $output_dir"
    mkdir -p "$output_dir"
  fi

  certificate=$(echo | openssl s_client -showcerts -servername "$url" -connect "$url":"$port" 2>/dev/null |
    openssl x509 -outform PEM)

  if [ -z "$certificate" ]; then
    echo "Unable to obtain SSL certificate from $url"
    return 1
  fi

  file_path="${output_dir}/${url}_${port}.pem"
  if [ -f "$file_path" ]; then
    mv "$file_path" "$file_path.$(date +%F_%H%M%S)"
  fi

  echo "$certificate" >"$file_path"
  echo "SSL certificate saved to $file_path"
}

ssl_show_cert_details() {
  _ssl_parse_cert_file "$1" || return 1
  openssl x509 -in "$1" -text -noout
}

ssl_show_cert_headers() {
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
  _is_openssl_installed

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$domain".key -out "$domain".crt
}
