github_verify_connection() {
  local repo_url="$1"
  local host="github.com"
  local port_https=443
  local port_ssh=22

  if [[ -z "$repo_url" ]]; then
    echo "Error: No valid URL provided."
    return 1
  fi

  echo "Repository URL: $repo_url"

  _validate_dns "$host" || return 1
  _validate_port "$host" "$port_https" "HTTPS" || return 1

  echo "Verifying HTTPS connection to $repo_url..."
  if git ls-remote "$repo_url" &>/dev/null; then
    echo "HTTPS connection successful to $repo_url."
  else
    echo "HTTPS connection failed to $repo_url."
  fi

  local ssh_url="${repo_url/https:\/\/github.com\//git@github.com:}"
  ssh_url="${ssh_url%.git}.git"

  echo "Derived SSH URL: $ssh_url"
  _validate_port "$host" "$port_ssh" "SSH" || return 1

  echo "Verifying SSH connection to $ssh_url..."
  if git ls-remote "$ssh_url" &>/dev/null; then
    echo "SSH connection successful to $ssh_url."
  else
    echo "SSH connection failed to $ssh_url. Ensure your SSH key is added to your GitHub account."
  fi
}

_validate_dns() {
  local host="$1"
  if nslookup "$host" >/dev/null 2>&1; then
    echo "DNS lookup for $host successful."
  else
    echo "DNS lookup for $host failed. Check your DNS settings."
    return 1
  fi
}

_validate_port() {
  local host="$1"
  local port="$2"
  local protocol="$3"
  if nc -z "$host" "$port" >/dev/null 2>&1; then
    echo "Port $port for $protocol is open on $host."
  else
    echo "Port $port for $protocol is closed on $host. Check your internet connection or firewall settings."
    return 1
  fi
}
