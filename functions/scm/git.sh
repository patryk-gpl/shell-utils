#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with Git repositories
####################################################################################################

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Helper functions
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

  echo -e "${YELLOW}== $label branches ==${RESET}"
  git for-each-ref --sort=-committerdate $ref --format='%(refname:short) %(committerdate:relative)' | while read -r ref; do
    result=$(git show --format="%ci %cr" "$ref" -- | head -n 1)
    echo -e "${color}$result $ref${RESET}"
  done
}

# Main
git_branch_show_remote_timestamp() {
  _git_branch_show_timestamps "${RED}" "remote"
}

git_branch_show_local_timestamp() {
  _git_branch_show_timestamps "${GREEN}" "local"
}

git_branch_show_all_timestamp() {
  git_branch_show_local_timestamp
  git_branch_show_remote_timestamp
}

git_create_and_push_tag() {
    local tag=$1
    local remote
    remote=$(git remote)

    if git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null; then
        echo "Local tag '$tag' already exists. Overwriting it."
        git tag -f "$tag"
    else
        echo "Creating local tag '$tag'."
        git tag "$tag"
    fi

    if git ls-remote --tags "$remote" "refs/tags/$tag" | grep -q "$tag"; then
        echo "Remote tag '$tag' already exists. Overwriting it."
        git push --force "$remote" "$tag"
    else
        echo "Pushing local tag '$tag' to remote '$remote'."
        git push "$remote" "$tag"
    fi
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


git_get_repo_urls_recursive() {
    if [[ "$#" -eq "0" ]]; then
        echo "Error: Root directory not provided."
        return 1
    fi

    local root_dir="$1"
    local output_file="git_repo_list.txt"

    traverse_directories() {
        local dir="$1"
        if git -C "$dir" rev-parse --is-inside-work-tree &> /dev/null; then
            remote=$(git -C "$dir" remote)
            remote_url=$(git -C "$dir" remote get-url "$remote" 2>/dev/null)
            exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                echo "$remote_url" >> "$output_file"
            else
                echo "Error retrieving remote origin URL for: $dir" >&2
            fi

            if [[ -f "$dir/.meta" ]]; then
                for item in "$dir"/*; do
                    if [[ -d "$item" ]]; then
                        traverse_directories "$item"
                    fi
                done
            fi
        else
            for item in "$dir"/*; do
                if [[ -d "$item" ]]; then
                    traverse_directories "$item"
                fi
            done
        fi
    }

    traverse_directories "$root_dir" > "$output_file"

    echo -e "\n== List of retrieved repository URLs stored in: $output_file =="
}

function git_cmd_recursive {
  local git_command=("$@")
  local parent_dir
  local git_dir

  if [ ${#git_command[@]} -eq 0 ]; then
    git_command=("pull")
  fi

  while IFS= read -r -d '' git_dir; do
    parent_dir=$(dirname "$git_dir")
    echo "== $parent_dir =="
    (cd "$parent_dir" && git "${git_command[@]}")
  done < <(find . -name ".git" -type d -print0)
}
