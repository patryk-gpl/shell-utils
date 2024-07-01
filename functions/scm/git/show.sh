#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

# Function to copy files from a specific branch in a Git repository to current branch without checkout.
# Parameters:
#   - branch_name: The name of the branch to copy files from.
#   - files_to_copy: The list of files to copy.
#
# Usage: git_copy_files_from_branch <branch_name> <file1> [<file2> ...]
git_copy_files_from_branch() {
  if [ $# -eq 0 ]; then
    echo "Error: No parameters provided." >&2
    echo "Usage: git_copy_files_from_branch <branch_name> <file1> [<file2> ...]" >&2
    return 1
  fi

  local branch_name=$1
  shift
  local files_to_copy=("$@")

  if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
    echo "Error: Branch '$branch_name' does not exist." >&2
    return 1
  fi

  if [ ${#files_to_copy[@]} -eq 0 ]; then
    echo "Error: No files specified to copy." >&2
    echo "Usage: git_copy_files_from_branch <branch_name> <file1> [<file2> ...]" >&2
    return 1
  fi

  local success_count=0
  local fail_count=0

  for file in "${files_to_copy[@]}"; do
    if git show "$branch_name:$file" >"$file" 2>/dev/null; then
      ((success_count++))
    else
      echo "Failed to copy $file from $branch_name branch. Check if the file exists." >&2
      ((fail_count++))
    fi
  done

  echo "Summary: $success_count file(s) copied successfully, $fail_count file(s) failed."

  # Return non-zero exit status if any file copy failed
  [ $fail_count -eq 0 ]
}
