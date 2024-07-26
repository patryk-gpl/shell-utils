# Functions to work with Git repositories

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Show folder name and its size, sort the result
git_folder_size() {
  git_dir=${1:-"."}
  [ ! -d "$git_dir" ] || [ ! -f "$git_dir/.git" ] && {
    echo "Error: Source directory is missing or is not a valid Git repository. Aborting." >&2
    echo "Usage: git_folder_size <directory>" >&2
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

git_get_repo_urls_recursive() {
  if [[ "$#" -eq "0" ]]; then
    echo "Error: Root directory not provided."
    return 1
  fi

  local root_dir="$1"
  local output_file="git_repo_list.txt"

  traverse_directories() {
    local dir="$1"
    if git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
      remote=$(git -C "$dir" remote)
      remote_url=$(git -C "$dir" remote get-url "$remote" 2>/dev/null)
      exit_code=$?
      if [[ $exit_code -eq 0 ]]; then
        echo "$remote_url" >>"$output_file"
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

  traverse_directories "$root_dir" >"$output_file"

  echo -e "\n== List of retrieved repository URLs stored in: $output_file =="
}

git_cmd_recursive() {
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
