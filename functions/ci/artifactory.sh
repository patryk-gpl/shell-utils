if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

artifactory_show_version_details() {
  local url=$1
  local user=$2
  local password=$3

  if [[ -z $url || -z $user || -z $password ]]; then
    echo "Usage: artifactory_show_version_details <artifactory_url> <username> <password>" >&2
    return 1
  fi

  local api_url="${url%/}/artifactory/api/system/version"

  local response
  response=$(curl -s -u "${user}:${password}" "${api_url}")

  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to connect to Artifactory" >&2
    return 1
  fi

  if [[ -z $response ]]; then
    echo "Error: Received empty response from Artifactory" >&2
    return 1
  fi

  if command -v jq >/dev/null 2>&1; then
    echo "Artifactory Version Details:"
    echo "$response" | jq '.'
  else
    echo "Warning: jq is not installed. Displaying raw JSON response:" >&2
    echo "$response"
  fi
}

artifactory_list_artifacts() {
  local url=$1
  local user=$2
  local password=$3
  local registry_name=$4
  local prefix=$5

  if [[ -z $url || -z $user || -z $password || -z $registry_name ]]; then
    echo "Usage: artifactory_list_artifacts <artifactory_url> <username> <password> <registry_name> [prefix]" >&2
    return 1
  else
    echo "Artifactory URL: $url"
    echo "Username: $user"
    echo "Password: ********"
    echo "Registry Name: $registry_name"
    echo "Prefix: $prefix"
  fi

  local api_url="${url%/}/artifactory/${registry_name}"
  local response
  response=$(curl -s -u "${user}:${password}" "${api_url}")

  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to connect to Artifactory" >&2
    return 1
  fi

  if command -v jq >/dev/null 2>&1; then
    if [[ -n $prefix ]]; then
      echo "$response" | jq -r ".children[] | select(.uri | startswith(\"/${prefix}\")) | .uri" | sed 's/^\///'
    else
      echo "$response" | jq -r '.children[].uri' | sed 's/^\///'
    fi
  else
    echo "Error: jq is not installed. Please install jq to parse JSON responses." >&2
    return 1
  fi
}
