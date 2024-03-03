#!/usr/bin/env bash
# This script allows updating Git commit history by replacing author name and email.

# Usage: update_git_commits.sh [-r range] old_name old_email new_name new_email
# -r range: Optional commit range (default: all commits)
# old_name: Old author name to be replaced
# old_email: Old author email to be replaced
# new_name: New author name to replace the old name
# new_email: New author email to replace the old email

# Parse command-line options
while getopts ":r:" opt; do
  case $opt in
    r)
      range="$OPTARG"
      ;;
    \?)
      echo "Invalid option -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Check required arguments
if [[ $# -ne 4 ]]; then
  echo "Usage: update_git_commits.sh [-r range] old_name old_email new_name new_email"
  exit 1
fi

# Assign arguments to variables
old_name="$1"
old_email="$2"
new_name="$3"
new_email="$4"

echo "Apply settings: old_name=\"$old_name\" old_email=\"$old_email\" new_name=\"$new_name\" new_email=\"$new_email\""

# If commit range is not provided, assume all commits
if [[ -z $range ]]; then
  range="-- --all"
else
  range="$range"
fi

# Filter Git history
if !  git filter-branch --force --env-filter "
if [ \"\$GIT_COMMITTER_EMAIL\" = \"$old_email\" ] || [ \"\$GIT_COMMITTER_NAME\" = \"$old_name\" ]; then
    echo \"Updating GIT_COMMITTER_NAME='\$GIT_COMMITTER_NAME' => '$new_name' and GIT_COMMITTER_EMAIL='\$GIT_COMMITTER_EMAIL' => '$new_email'\"
    export GIT_COMMITTER_NAME=\"$new_name\"
    export GIT_COMMITTER_EMAIL=\"$new_email\"
fi
if [ \"\$GIT_AUTHOR_EMAIL\" = \"$old_email\" ] || [ \"\$GIT_AUTHOR_NAME\" = \"$old_name\" ]; then
    echo \"Updating GIT_AUTHOR_NAME='\$GIT_AUTHOR_NAME' => '$new_name' and GIT_AUTHOR_EMAIL='\$GIT_AUTHOR_EMAIL' => '$new_email'\"
    export GIT_AUTHOR_NAME=\"$new_name\"
    export GIT_AUTHOR_EMAIL=\"$new_email\"
fi
" --tag-name-filter cat "$range"; then
  echo "An error occurred while updating Git history. Please check your inputs and try again."
  exit 1
fi

# Print success message
echo "Git commit history updated successfully!"
