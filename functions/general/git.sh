#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Git repositories
####################################################################################################

PARENT_SHARED_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)/shared.sh"

# shellcheck source=shared.sh
source "$PARENT_SHARED_SCRIPT"

_git_branch_show_timestamps() {
  local color="$1"
  local label="$2"

  if [ "$label" == "remote" ]; then
    local ref="refs/remotes"
  elif [ "$label" == "local" ]; then
    local ref="refs/heads"
  else
    echo "Invalid label: $label. Aborting.."
    return 1
  fi

  echo -e "${yellow}== $label branches ==${reset}"
  git for-each-ref --sort=-committerdate $ref --format='%(refname:short) %(committerdate:relative)' | while read ref date; do
    result=$(git show --format="%ci %cr" "$ref" -- | head -n 1)
    echo -e "${color}$result $ref${reset}"
  done
}

git_branch_show_remote_timestamp() {
  git_branch_show_timestamps "${red}" "remote"
}

git_branch_show_local_timestamp() {
  git_branch_show_timestamps "${green}" "local"
}

git_branch_show_all_timestamp() {
  git_branch_show_local_timestamp
  git_branch_show_remote_timestamp
}

# This function will show the local and remote branch head commit hashes.
git_current_branch_heads() {
  echo "Local branch head: $(git rev-parse --verify HEAD)"
  echo "Remote branch head: $(git rev-parse --verify 'HEAD@{upstream}')"
}

# Search for a pattern in the Git history
git_history_search() {
  [ -z "$1" ] && {
    echo "Missing pattern. Aborting.."
    return
  } || pattern="$1"

  git log --all -S"$pattern" --oneline |
    while read -r commit; do git show "${commit:0:7}"; done
}

# Search for a pattern in all commits, show the commit hash and the line number
git_grep_all_commits() {
  [ -z "$1" ] && {
    echo "Missing pattern. Aborting.."
    return
  } || pattern="$1"

  echo "Checking Git history for pattern: $pattern"
  mapfile -t commits < <(git rev-list --all)
  git grep -n "$pattern" "${commits[@]}"
}

# Show folder name and its size, sort the result
git_folder_size() {
  git_dir=${1:-"."}
  [ ! -d "$git_dir" ] || [ ! -f "$git_dir/.git" ] && {
    echo "Source directory is missing or not a Git folder. Aborting.."
    return 1
  }

  for dir in "$git_dir"/*; do
    if [ -d "$dir" ]; then
      if [ -d "$dir/.git" ]; then
        size=$(du -sh "$dir" | awk '{print $1}')
        echo "$size - $dir"
        if [ -f "$dir/.meta" ]; then
          git_folder_size "$dir"
        fi
      else
        git_folder_size "$dir"
      fi
    fi
  done | sort -h
}

# Clone a Git repository with depth 1 (shallow clone)
git_clone_shallow() {
  [ -z "$1" ] && {
    echo "Missing URL. Aborting.." >&2
    return 1
  } || url="$1"

  if [ -z "$2" ]; then
    git clone --depth 1 "$url"
  else
    git clone --depth 1 "$url" "$2"
  fi

}

# Run 'git gc' command on all Git repositories recursively, starting from the current directory if no argument is provided
git_gc_recursively() {
  dir=${1:-.}
  echo "Running 'git gc' command on directories containing '.git' starting from $dir recursively"
  find "$dir" -type d -name ".git" -execdir git gc {} \;
}
