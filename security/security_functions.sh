#!/bin/bash

# Function to fetch SSL certificate from a server
fetch_ssl_cert() {
  url=${1:-}
  output_dir=${2:-certs}

  if [ -z "$url" ]; then echo "Usage: $0 <url>" && return 1; fi
  if ! which openssl >/dev/null; then echo "openssl not found" && return 1; fi
  if [ ! -d "$output_dir" ]; then
    echo "Creating directory $output_dir"
    mkdir -p "$output_dir";
  fi


  certificate=$(echo | openssl s_client -showcerts -servername "$url" -connect "$url":443 2>/dev/null \
  | openssl x509 -outform PEM)

  if [ -z "$certificate" ]; then
    echo "Unable to obtain SSL certificate from $url"
    return 1
  fi

  if [ -f "${output_dir}/${url}.pem" ]; then
    mv "${output_dir}/${url}.pem" "${output_dir}/${url}.pem.$(date +%F_%H%M%S)"
  fi

  echo "$certificate" > "${output_dir}/${url}.pem"
  echo "SSL certificate saved to ${output_dir}/${url}.pem"
}
