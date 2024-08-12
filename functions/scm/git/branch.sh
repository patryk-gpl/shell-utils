# Functions to work with Git branch
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

_git_branch_show_timestamps() {
  local label="$1"

  if [[ "$label" == "remote" ]]; then
    local ref="refs/remotes"
  elif [[ "$label" == "local" ]]; then
    local ref="refs/heads"
  else
    echo "Invalid label: $label. Aborting.."
    return 1
  fi

  echo -e "${YELLOW}== $label branches ==${RESET}"
  git for-each-ref --sort=-committerdate $ref --format='%(refname:short) %(committerdate:relative)' | while IFS= read -r branch timestamp; do
    branch=$(echo "$branch" | cut -f1 -d ' ')
    result=$(git show --format="%ci %cr" "$branch" -- | head -n 1)
    echo -e "$result $branch $timestamp"
  done
}

# Main
git_branch_show_remote_timestamp() {
  _git_branch_show_timestamps "remote"
}

git_branch_show_local_timestamp() {
  _git_branch_show_timestamps "local"
}

git_branch_show_all_timestamp() {
  git_branch_show_local_timestamp
  git_branch_show_remote_timestamp
}

git_branch_list_heads() {
  local local_head remote_head
  local_head=$(git rev-parse --verify HEAD)
  remote_head=$(git rev-parse --verify 'HEAD@{upstream}')
  if [[ "$local_head" == "$remote_head" ]]; then
    echo "Local and remote heads are the same: $local_head"
  else
    echo "Local head: $local_head"
    echo "Remote head: $remote_head"
  fi
}

git_branch_find_upstream() {
  local feature_branch="$1"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  if [ -z "$feature_branch" ]; then
    feature_branch=$(git rev-parse --abbrev-ref HEAD)

    echo "No feature branch provided for verification."
    echo "Using the current branch: $feature_branch"
  elif ! git rev-parse --verify "$feature_branch" >/dev/null 2>&1; then
    echo "Error: Branch '$feature_branch' does not exist." >&2
    return 1
  fi

  echo "Trying to fetch all changes from the remote.."
  if ! git fetch --all --quiet; then
    echo "Error: Unable to fetch from remote" >&2
    return 1
  fi

  # List all branches (including remote branches) and their merge bases with the feature branch
  local branches
  branches=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/)

  local best_branch
  local best_distance=-1

  for branch in $branches; do
    if [ "$branch" != "$feature_branch" ] && ! [[ "$branch" =~ /$feature_branch$ ]]; then
      # Find the merge base between the branch and the feature branch
      local merge_base
      merge_base=$(git merge-base "$branch" "$feature_branch")

      # Skip if there's no merge base
      if [ -z "$merge_base" ]; then
        continue
      fi

      # Compute the distance from the merge base to the feature branch
      local distance
      distance=$(git rev-list --count "$merge_base..$feature_branch")

      # Check if this is the best (shortest distance) so far
      if [ "$best_distance" -lt 0 ] || [ "$distance" -lt "$best_distance" ]; then
        best_distance=$distance
        best_branch=$branch
      fi
    fi
  done

  if [ -n "$best_branch" ]; then
    echo "The upstream branch seems to be: $best_branch"
    return 0
  else
    echo "No upstream branch found for '$feature_branch'." >&2
    return 1
  fi
}
