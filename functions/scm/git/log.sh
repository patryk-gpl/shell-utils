#!/usr/bin/env bash
# Functions to work with Git log
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Search for a pattern in the Git history
git_log_history_search() {
  [ -z "$1" ] && {
    echo "Syntax: git_log_history_search <pattern>"
    return
  } || pattern="$1"

  git log --all -S"$pattern" --oneline |
    while read -r commit; do git show "${commit:0:7}"; done
}

# Function to list files and their counts based on different diff formats in a Git repository.
# This function retrieves the files for each diff format (A, C, D, M, R, T, U, X, B) using the `git log` command,
# counts the number of files for each format, and displays the files along with their counts.
# It also provides a summary report showing the count of files for each diff format and the total number of files affected.
git_log_list_file_stats() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a Git repository"
    return 1
  fi

  declare -A counters
  local diff_formats="ACDMRTUXB"

  for format in $(echo $diff_formats | grep -o .); do
    counters[$format]=0
  done

  # Function to get files for each diff format
  get_files() {
    git log --all --pretty=format: --name-only --diff-filter="$1" | sort -u
  }

  # Count files for each diff format and display them
  for format in $(echo $diff_formats | grep -o .); do
    files=$(get_files "$format")
    count=$(echo "$files" | grep -vc '^$')
    counters[$format]=$count

    if [[ $count -gt 0 ]]; then
      echo "Files with diff-filter=$format:"
      echo "$files"
      echo "Total: $count"
      echo
    fi
  done

  echo "Summary Report:"
  echo "---------------"
  for format in $(echo $diff_formats | grep -o .); do
    case $format in
      A) desc="Added files (A)" ;;
      C) desc="Copied files (C)" ;;
      D) desc="Deleted files (D)" ;;
      M) desc="Modified files (M)" ;;
      R) desc="Renamed files (R)" ;;
      T) desc="Type-changed files (T)" ;;
      U) desc="Unmerged files (U)" ;;
      X) desc="Unknown files (X)" ;;
      B) desc="Broken pair files (B)" ;;
    esac
    echo "${desc}: ${counters[$format]}"
  done

  total=0
  for count in "${counters[@]}"; do
    ((total += count))
  done
  echo "Total files affected: $total"
}
