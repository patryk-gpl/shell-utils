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
  local old_emails new_email old_names new_name
  local name_callback="return name"
  local email_callback="return email"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --old-emails)
        old_emails="$2"
        shift 2
        ;;
      --new-email)
        new_email="$2"
        shift 2
        ;;
      --old-names)
        old_names="$2"
        shift 2
        ;;
      --new-name)
        new_name="$2"
        shift 2
        ;;
      *)
        echo "Unknown parameter: $1" >&2
        return 1
        ;;
    esac
  done

  # Validation
  if [[ -z "$old_emails" && -z "$old_names" ]]; then
    echo "Error: At least one pair of options must be provided." >&2
    echo "Syntax: git_history_update_user_data --old-emails <email1,email2,...> --new-email <new_email> --old-names <name1,name2,...> --new-name <new_name>" >&2
    return 1
  fi

  if [[ (-n "$old_emails" && -z "$new_email") || (-z "$old_emails" && -n "$new_email") ]]; then
    echo "Error: Both --old-emails and --new-email must be provided to update email." >&2
    return 1
  fi

  if [[ (-n "$old_names" && -z "$new_name") || (-z "$old_names" && -n "$new_name") ]]; then
    echo "Error: Both --old-names and --new-name must be provided to update name." >&2
    return 1
  fi

  # Save the current origin URL
  local origin_url
  origin_url=$(git config --get remote.origin.url)

  echo "Updating Git history..."

  # Build email callback for multiple old emails
  if [[ -n "$old_emails" ]]; then
    echo "Old Emails: $old_emails -> New Email: $new_email"
    local -a emails_array
    IFS=',' read -ra emails_array <<<"$old_emails"

    local email_conditions=""
    local email_entry
    for email_entry in "${emails_array[@]}"; do
      if [[ -z "$email_conditions" ]]; then
        email_conditions="email == b'$email_entry'"
      else
        email_conditions="$email_conditions or email == b'$email_entry'"
      fi
    done

    email_callback="return b'$new_email' if $email_conditions else email"
  fi

  # Build name callback for multiple old names
  if [[ -n "$old_names" ]]; then
    echo "Old Names: $old_names -> New Name: $new_name"
    local -a names_array
    IFS=',' read -ra names_array <<<"$old_names"

    local name_conditions=""
    local name_entry
    for name_entry in "${names_array[@]}"; do
      if [[ -z "$name_conditions" ]]; then
        name_conditions="name == b'$name_entry'"
      else
        name_conditions="$name_conditions or name == b'$name_entry'"
      fi
    done

    name_callback="return b'$new_name' if $name_conditions else name"
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
