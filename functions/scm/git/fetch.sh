if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

git_fetch_custom_origin() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: git_fetch_custom_origin <remote_name> <branch_name>"
    echo "Example: git_fetch_custom_origin upstream feature/new-feature"
    return 1
  fi

  remote_name="$1"
  branch_name="$2"

  # Check if remote exists
  if ! git remote | grep -q "^${remote_name}$"; then
    echo "Remote '${remote_name}' does not exist. Please provide the URL to add it:"
    read -r remote_url
    if [ -z "$remote_url" ]; then
      echo "No URL provided. Aborting."
      return 1
    fi
    if ! git remote add "$remote_name" "$remote_url"; then
      echo "Failed to add remote '${remote_name}'. Aborting."
      return 1
    fi
    echo "Remote '${remote_name}' added successfully."
  fi

  # Check if the branch exists locally
  if git rev-parse --verify --quiet "$branch_name" >/dev/null; then
    echo "Branch '${branch_name}' exists locally. Updating it from remote '${remote_name}'..."
    if git checkout "$branch_name"; then
      if git pull "$remote_name" "$branch_name"; then
        echo "Successfully updated local branch '${branch_name}' from remote '${remote_name}'."
      else
        echo "Failed to update local branch '${branch_name}' from remote '${remote_name}'."
        return 1
      fi
    else
      echo "Failed to checkout existing local branch '${branch_name}'. Aborting."
      return 1
    fi
  else
    # Branch doesn't exist locally, fetch it from remote
    echo "Fetching branch '${branch_name}' from remote '${remote_name}'..."
    if git fetch "$remote_name" "${branch_name}:${branch_name}"; then
      if git checkout "$branch_name"; then
        echo "Successfully fetched and checked out '${branch_name}' from '${remote_name}'."
      else
        echo "Failed to checkout newly fetched branch '${branch_name}'. Aborting."
        return 1
      fi
    else
      echo "Failed to fetch branch '${branch_name}' from remote '${remote_name}'."
      echo "Possible reasons:"
      echo "1. The branch does not exist on the remote."
      echo "2. Network issues preventing connection to the remote."
      echo "3. Insufficient permissions to access the remote or branch."
      echo ""
      echo "Attempting to list remote branches..."
      if git ls-remote --heads "$remote_name"; then
        echo "These are the available branches on the remote."
        echo "Please check if '${branch_name}' is listed above."
      else
        echo "Unable to list remote branches. There might be connectivity or permission issues."
      fi
      return 1
    fi
  fi
}
