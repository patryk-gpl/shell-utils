# Functions to work with SSL/TLS certificates

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

_tls_check_function_params() {
  local cert_file=${1:-}

  if [ -z "$cert_file" ]; then
    echo "Usage: $0 <cert_file.pem>"
    return 1
  fi

  if [ ! -f "$cert_file" ]; then
    echo "File $cert_file not found"
    return 1
  fi
}

# Main functions

# Function: tls_import_root_ca_certs
#
# Description: This function imports root CA certificates from a source directory and updates the CA certificates on the system.
#
# Parameters:
#   - source_dir: The directory containing the .crt files to import. Default is /mnt/c/Users/$USERNAME/certs
#
# Returns:
#   - 0: If the root CA certificates are successfully imported and updated.
#   - 1: If there is an error during the import or update process.
#
# Supported distributions:
#   - Debian/Ubuntu
#   - CentOS/RHEL/Fedora
#
# Usage:
#   tls_import_root_ca_certs [source_dir]
#
# Example:
#   tls_import_root_ca_certs /path/to/certificates
#
tls_import_root_ca_certs() {
  local source_dir="${1:-/mnt/c/Users/$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r')/certs}"
  local dest_dir
  local update_cmd

  # Determine the correct destination directory and update command based on the distribution
  if [ -f /etc/debian_version ]; then
    dest_dir="/usr/local/share/ca-certificates"
    update_cmd="update-ca-certificates"
  elif [ -f /etc/redhat-release ]; then
    dest_dir="/etc/pki/ca-trust/source/anchors"
    update_cmd="update-ca-trust extract"
  else
    echo "Unsupported distribution. This script works on Debian/Ubuntu or CentOS/RHEL/Fedora."
    return 1
  fi

  if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory $source_dir does not exist."
    echo "Syntax: tls_import_root_ca_certs [source_dir]"
    echo "  source_dir: The directory containing the .crt files to import. Default is /mnt/c/Users/$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r')/certs"
    return 1
  fi

  # Check if there are any .crt files in the source directory
  if ! find "$source_dir" -maxdepth 1 -name "*.crt" -print -quit | grep -q .; then
    echo "Error: No .crt files found in $source_dir"
    return 1
  fi

  sudo mkdir -p "$dest_dir"

  # Copy all .crt files from the source directory to the destination
  echo "Copying certificates from $source_dir to $dest_dir"
  if ! sudo cp "$source_dir"/*.crt "$dest_dir"/; then
    echo "Error: Failed to copy certificates from $source_dir to $dest_dir"
    return 1
  fi

  # Update the CA certificates
  echo "Updating CA certificates..."
  if ! sudo "$update_cmd"; then
    echo "Error: Failed to update CA certificates"
    return 1
  fi

  echo "Root CA certificates have been successfully imported and updated."
}

tls_fetch_fullchain() {
  local host=${1:-}
  local port=${2:-443}
  is_installed openssl awk || return 1

  if [ -z "$host" ]; then
    echo "Usage: $0 <host> [<port=443>]"
    return 1
  fi
  local output_file="chained_${host}_${port}.pem"

  openssl s_client -showcerts -connect "$host:$port" </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' >"$output_file"

  echo "SSL certificate saved to $output_file"
  echo "Number of saved certificates in the chain: $(grep -c 'BEGIN CERTIFICATE' "$output_file")"
}

tls_fetch_cert() {
  local host=${1:-}
  local port=${2:-443}
  is_installed openssl || return 1

  if [ -z "$host" ]; then
    echo "Usage: $0 <host> [<port=443>]"
    return 1
  fi

  echo "Fetching SSL certificate from host=$host, port=$port"
  local certificate
  certificate=$(echo | openssl s_client -showcerts -servername "$host" -connect "$host":"$port" 2>/dev/null |
    openssl x509 -outform PEM)

  if [ -z "$certificate" ]; then
    echo "Unable to obtain SSL certificate from $host"
    return 1
  fi

  local file_path="${host}_${port}.pem"
  echo "$certificate" >"$file_path"
  echo "SSL certificate saved to $file_path"
}

tls_fetch_cert_details() {
  local host=${1:-}
  local port=${2:-443}
  is_installed openssl || return 1

  if [ -z "$host" ]; then
    echo "Usage: $0 <host> [<port=443>]"
    return 1
  fi

  openssl s_client -showcerts -connect "$host:$port" </dev/null 2>/dev/null | openssl x509 -noout -text
}

tls_show_local_cert_headers() {
  local cert_file="$1"
  is_installed openssl awk || return 1
  _tls_check_function_params "$cert_file" || return 1

  echo "== $cert_file =="
  openssl x509 -in "$cert_file" -text -noout |
    grep -E 'Signature Algorithm:|Subject:|Issuer:|Not Before|Not After|Public Key Algorithm:|Public-Key:|DNS:' |
    awk '!a[$0]++'
}

tls_check_local_cert_validity() {
  local cert_file="$1"
  is_installed openssl || return 1
  _tls_check_function_params "$cert_file" || return 1

  local day_in_seconds=86400
  if openssl x509 -in "$cert_file" -checkend "$day_in_seconds" -noout; then
    echo "Certificate is still valid"
  else
    echo "Certificate has expired or will expire soon"
  fi
}

tls_is_local_ca_cert() {
  local cert_file="$1"
  is_installed openssl || return 1
  _tls_check_function_params "$cert_file" || return 1

  if openssl x509 -in "$cert_file" -text -noout | grep -q 'CA:TRUE'; then
    echo "Certificate is a CA certificate"
  else
    echo "Certificate is not a CA certificate"
  fi
}

tls_create_self_signed_cert_files() {
  local domain=${1:-}
  [ -z "$domain" ] && {
    echo "Usage: $0 <domain> [<cn_name>] [<country>] [<state>] [<city>] [<organization>] [<unit>]"
    return 1
  }

  local cn_name=${2:-}
  local country=${3:-}
  local state=${4:-}
  local city=${5:-}
  local organization=${6:-}
  local unit=${7:-}

  if [ -z "$cn_name" ]; then
    cn_name="example.com"
    country="PL"
    state="mazowieckie"
    city="Warsaw"
    organization="IT Organization"
    unit="Engineering"

    echo "CN attributes not provided. Using default values for CN attributes:"
    echo "CN Name: $cn_name, Country: $country, State: $state, City: $city, Organization: $organization, Unit: $unit"

    echo -n "CN attributes are missing. Do you want to use default values? (Y/n): "
    read -r choice
    case "$choice" in
      n | N)
        echo "Please provide CN attributes"
        echo -n "Enter CN Name: "
        read -r choice
        cn_name=${choice:-$cn_name}
        echo -n "Enter Country: "
        read -r choice
        country=${choice:-$country}
        echo -n "Enter State: "
        read -r choice
        state=${choice:-$state}
        echo -n "Enter City: "
        read -r choice
        city=${choice:-$city}
        echo -n "Enter Organization: "
        read -r choice
        organization=${choice:-$organization}
        echo -n "Enter Unit: "
        read -r choice
        unit=${choice:-$unit}
        ;;
    esac
  fi

  is_installed openssl || return 1

  echo "Generating self-signed certificate for domain: $domain"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$domain".key -out "$domain".crt \
    -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$unit/CN=$cn_name"

  echo "Self-signed certificate generated:"
  echo "Key file: $domain.key"
  echo "Certificate file: $domain.crt"

  echo "Verifying the generated certificate:"
  openssl x509 -noout -text -in "$domain.crt"
}

tls_split_chained_cert_and_keys_into_files() {
  local orig_file=$1
  if [ -z "$orig_file" ]; then
    echo "Usage: $0 <cert_file.pem>"
    return 1
  fi
  local base_name

  base_name=$(basename "$orig_file" .crt)
  awk -v base_name="$base_name" '
  BEGIN {c=0; k=0; out=""}
  /-----BEGIN CERTIFICATE-----/ {
    if (out != "") close(out);
    c++;
    out=base_name "_" c ".crt";
  }
  /-----BEGIN PRIVATE KEY-----/ {
    if (out != "") close(out);
    k++;
    out=base_name "_" k ".key";
  }
  /-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ {
    if (out != "") print >out;
  }
  /-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/ {
    if (out != "") print >out;
  }' "$orig_file"

  for file in "$base_name"_*.crt; do
    echo "Certificate file $file header:"
    openssl x509 -noout -subject -issuer -dates -fingerprint -in "$file"
    openssl x509 -noout -fingerprint -sha256 -in "$file"
    echo
  done

  for file in "$base_name"_*.key; do
    echo "Private key file $file:"
    openssl rsa -noout -text -in "$file"
    echo
  done
}

tls_verify_key_matches_cert() {
  local cert_file="$1"
  local key_file="$2"
  _tls_check_function_params "$cert_file" || return 1

  if [ -z "$key_file" ]; then
    echo "Usage: <cert_file.pem> <key_file.pem>"
    return 1
  fi

  if [ ! -f "$key_file" ]; then
    echo "File $key_file not found"
    return 1
  fi

  is_installed openssl || return 1
  if openssl x509 -noout -modulus -in "$cert_file" | openssl md5; then
    echo "Certificate modulus:"
    openssl x509 -noout -modulus -in "$cert_file" | openssl md5
    echo
  fi

  if openssl rsa -noout -modulus -in "$key_file" | openssl md5; then
    echo "Private key modulus:"
    openssl rsa -noout -modulus -in "$key_file" | openssl md5
    echo
  fi

  if openssl x509 -noout -modulus -in "$cert_file" | openssl md5 | grep -q "$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)"; then
    echo -e "${GREEN}Certificate and private key match${RESET}"
  else
    echo -e "${RED}Certificate and private key do not match${RESET}"
  fi
}
