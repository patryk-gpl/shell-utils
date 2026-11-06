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

  echo "=> Pruning remote-tracking branches that no longer exist on the remote..."
  git remote prune origin

  echo "=> Verify the integrity of the repository..."
  git fsck --full

  echo "=> Optimization complete. <="
}

git_history_update_user_data() {
  local old_emails="" new_email="" old_names="" new_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --old-emails | --new-email | --old-names | --new-name)
        if [[ $# -lt 2 || -z "$2" ]]; then
          printf 'Error: %s requires a non-empty value.\n' "$1" >&2
          return 1
        fi
        case "$1" in
          --old-emails) old_emails="$2" ;;
          --new-email) new_email="$2" ;;
          --old-names) old_names="$2" ;;
          --new-name) new_name="$2" ;;
        esac
        shift 2
        ;;
      *)
        printf 'Unknown parameter: %s\n' "$1" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$old_emails" && -z "$old_names" ]]; then
    printf 'Error: At least one pair of options must be provided.\n' >&2
    printf 'Syntax: git_history_update_user_data --old-emails <email1,email2,...> --new-email <new_email> --old-names <name1,name2,...> --new-name <new_name>\n' >&2
    return 1
  fi

  if [[ (-n "$old_emails" && -z "$new_email") || (-z "$old_emails" && -n "$new_email") ]]; then
    printf 'Error: Both --old-emails and --new-email must be provided to update email.\n' >&2
    return 1
  fi

  if [[ (-n "$old_names" && -z "$new_name") || (-z "$old_names" && -n "$new_name") ]]; then
    printf 'Error: Both --old-names and --new-name must be provided to update name.\n' >&2
    return 1
  fi

  if ! command -v git-filter-repo &>/dev/null; then
    printf 'Error: git-filter-repo could not be found. Please install it first.\n' >&2
    return 1
  fi

  if ! git rev-parse --git-dir &>/dev/null; then
    printf 'Error: This command must be run inside a Git repository.\n' >&2
    return 1
  fi

  local origin_url=""
  origin_url=$(git config --get remote.origin.url 2>/dev/null || true)

  printf 'Updating Git history...\n'
  if [[ -n "$old_emails" ]]; then
    printf 'Old Emails: %s -> New Email: %s\n' "$old_emails" "$new_email"
  fi
  if [[ -n "$old_names" ]]; then
    printf 'Old Names: %s -> New Name: %s\n' "$old_names" "$new_name"
  fi

  # Keep callbacks static so user data cannot become executable Python code.
  local name_callback='
import os
old_names = os.environb[b"GIT_HISTORY_UPDATE_OLD_NAMES"].split(b",")
return os.environb[b"GIT_HISTORY_UPDATE_NEW_NAME"] if name in old_names else name
'
  local email_callback='
import os
old_emails = os.environb[b"GIT_HISTORY_UPDATE_OLD_EMAILS"].split(b",")
return os.environb[b"GIT_HISTORY_UPDATE_NEW_EMAIL"] if email in old_emails else email
'

  local filter_repo_status=0
  GIT_HISTORY_UPDATE_OLD_NAMES="$old_names" \
    GIT_HISTORY_UPDATE_NEW_NAME="$new_name" \
    GIT_HISTORY_UPDATE_OLD_EMAILS="$old_emails" \
    GIT_HISTORY_UPDATE_NEW_EMAIL="$new_email" \
    git filter-repo --force \
    --name-callback "$name_callback" \
    --email-callback "$email_callback" || filter_repo_status=$?

  # git-filter-repo removes the origin remote after rewriting history.
  if [[ -n "$origin_url" ]]; then
    if ! git remote add origin "$origin_url" 2>/dev/null; then
      if ! git remote set-url origin "$origin_url"; then
        printf 'ERROR: Failed to restore origin remote to %s\n' "$origin_url" >&2
        return 1
      fi
    fi
    printf 'Origin remote has been restored.\n'
  else
    printf 'No origin remote was previously set.\n'
  fi

  if [[ $filter_repo_status -ne 0 ]]; then
    printf 'ERROR: git filter-repo failed with status %d.\n' "$filter_repo_status" >&2
    return "$filter_repo_status"
  fi

  printf 'Git history has been updated. You may need to force push these changes.\n'
}
