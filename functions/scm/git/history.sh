#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

git_history_cleanup() {
  if ! command -v git-filter-repo &>/dev/null; then
    echo "git-filter-repo could not be found. Please install it first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "You need to provide at least one file or directory pattern to remove. E.g., '*.jks' '*.zip'"
    return 1
  fi

  patterns=("$@")

  paths_to_remove=""
  for pattern in "${patterns[@]}"; do
    paths_to_remove="$paths_to_remove --path-glob '$pattern'"
  done

  eval "git filter-repo --invert-paths $paths_to_remove"
}

git_history_shrink_storage_size() {
  echo "=> Running reflog expire..."
  git reflog expire --expire=now --all

  echo "=> Running garbage collection..."
  git gc --aggressive --prune=all

  echo "=> Running repack..."
  git repack -ad --depth=250 --window=250

  echo "=> Remove all remote branches that no longer exist locally..."
  git remote prune origin

  echo "=> Verify the integrity of the repository..."
  git fsck --full

  echo "=> Optimization complete. <="
}

git_history_update_user_data() {
  local old_email new_email old_name new_name
  local name_callback="return name"
  local email_callback="return email"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --old-email)
        old_email="$2"
        shift 2
        ;;
      --new-email)
        new_email="$2"
        shift 2
        ;;
      --old-name)
        old_name="$2"
        shift 2
        ;;
      --new-name)
        new_name="$2"
        shift 2
        ;;
      *)
        echo "Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  if [[ (-n "$old_email" && -z "$new_email") || (-z "$old_email" && -n "$new_email") ]]; then
    echo "Error: Both --old-email and --new-email must be provided to update email."
    return 1
  fi

  if [[ (-n "$old_name" && -z "$new_name") || (-z "$old_name" && -n "$new_name") ]]; then
    echo "Error: Both --old-name and --new-name must be provided to update name."
    return 1
  fi

  if [[ -z "$old_email" && -z "$old_name" ]]; then
    echo "Error: At least one pair of options (--old-email and --new-email) or (--old-name and --new-name) must be provided."
    echo "Syntax: git_history_update_user_data --old-email <old_email> --new-email <new_email> --old-name <old_name> --new-name <new_name>"
    return 1
  fi

  # Save the current origin URL
  local origin_url
  origin_url=$(git config --get remote.origin.url)

  echo "Updating Git history..."

  if [[ -n "$old_email" ]]; then
    echo "Old Email: $old_email -> New Email: $new_email"
    email_callback="return b'$new_email' if email == b'$old_email' else email"
  fi

  if [[ -n "$old_name" ]]; then
    echo "Old Name: $old_name -> New Name: $new_name"
    name_callback="return b'$new_name' if name == b'$old_name' else name"
  fi

  git filter-repo --force --name-callback "
        $name_callback
    " --email-callback "
        $email_callback
    "

  # Restore the origin remote
  if [[ -n "$origin_url" ]]; then
    git remote add origin "$origin_url"
    echo "Origin remote has been restored."
  else
    echo "No origin remote was previously set."
  fi

  echo "Git history has been updated. You may need to force push these changes."
}

git_history_verify_user_data_update() {
  local old_email=""
  local old_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --old-email)
        old_email="$2"
        shift 2
        ;;
      --old-name)
        old_name="$2"
        shift 2
        ;;
      *)
        echo "Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  if [[ -z "$old_email" && -z "$old_name" ]]; then
    echo "Usage: git_history_verify_user_data_update --old-email <old_email> --old-name <old_name>"
    echo "At least one of --old-email or --old-name must be provided."
    return 1
  fi

  [[ -n "$old_email" ]] && echo "Checking for occurrences of old email: $old_email"
  [[ -n "$old_name" ]] && echo "Checking for occurrences of old name: $old_name"
  echo "-------------------------------------------"

  # Disable Git's pager
  export GIT_PAGER=cat

  check_commits() {
    local ref="$1"
    [[ -n "$old_email" ]] && git log --all --author="$old_email" "$ref"
    [[ -n "$old_email" ]] && git log --all --committer="$old_email" "$ref"
    [[ -n "$old_name" ]] && git log --all --author="$old_name" "$ref"
    [[ -n "$old_name" ]] && git log --all --committer="$old_name" "$ref"
  }

  # Check all branches
  for branch in $(git for-each-ref --format='%(refname)' refs/heads/); do
    echo "Checking branch: ${branch#refs/heads/}"
    check_commits "$branch"
  done

  # Check all tags
  for tag in $(git for-each-ref --format='%(refname)' refs/tags/); do
    echo "Checking tag: ${tag#refs/tags/}"
    check_commits "$tag"
  done

  # Restore Git's default pager setting
  unset GIT_PAGER

  echo "-------------------------------------------"
  echo "If no commits were listed above, all occurrences have been updated."
  echo "Otherwise, the listed commits still contain the old email or name."
}
