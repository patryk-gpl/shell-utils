####################################################################################################
# Functions to work with Nexus REST API
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

nexus_delete_all_files_from_raw_repo() {
  NEXUS_URL="${1:-$NEXUS_URL}"
  NEXUS_REPOSITORY="${2:-$NEXUS_REPOSITORY}"
  NEXUS_USER="${3:-$NEXUS_USER}"
  NEXUS_TOKEN="${4:-$NEXUS_TOKEN}"

  if [ -z "$NEXUS_URL" ] || [ -z "$NEXUS_REPOSITORY" ] || [ -z "$NEXUS_USER" ] || [ -z "$NEXUS_TOKEN" ]; then
    echo "Nexus URL, repository name, username or token is not set"
    echo "Usage: nexus_delete_all_files_from_raw_repo <nexus_url> <nexus_repository> <nexus_user> <nexus_token>"
    echo "You can also set NEXUS_URL, NEXUS_REPOSITORY, NEXUS_USER, and NEXUS_TOKEN environment variables"
    exit 1
  fi

  echo "Nexus URL: $NEXUS_URL, Repository name: $NEXUS_REPOSITORY, User: $NEXUS_USER, Token: $NEXUS_TOKEN"
  local token=""
  local total=0
  while :; do
    if [ -z "$token" ]; then
      response=$(curl -s -u "$NEXUS_USER:$NEXUS_TOKEN" "$NEXUS_URL/service/rest/v1/components?repository=$NEXUS_REPOSITORY")
    else
      response=$(curl -s -u "$NEXUS_USER:$NEXUS_TOKEN" -G -d "continuationToken=$token" "$NEXUS_URL/service/rest/v1/components?repository=$NEXUS_REPOSITORY")
    fi
    length=$(echo "$response" | jq -r '.items | length')
    if [ -z "$length" ]; then
      length=0
    fi
    total=$((total + length))

    component_ids=$(echo "$response" | jq -r '.items[].id')
    echo "$component_ids" | xargs -I {} echo "Deleting component with id: {}"
    echo "$component_ids" | xargs -I {} curl -u "$NEXUS_USER:$NEXUS_TOKEN" -X DELETE "$NEXUS_URL/service/rest/v1/components/{}"

    token=$(echo "$response" | jq -r '.continuationToken')
    if [ -z "$token" ]; then
      break
    fi
  done
  echo "Total components deleted: $total"
}
