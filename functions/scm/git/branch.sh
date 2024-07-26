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
