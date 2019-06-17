#!/usr/bin/env bash
#####################################################################################################
# This script will allow to update Git Commit history replacing author name and e-mail.
#
# Note:
#   Be cautious. If no commit range is provided it can re-write the whole Git commit history.
#   Script can be added to user $PATH to execute on any repository. 
#
# Sample usage:
#   bash update_git_commits.sh "Joe Z" "Joe.Z@example.com" "Joz Z" "joe.z@company.com"
#   bash update_git_commits.sh "Joe Z" "Joe.Z@example.com" "Joz Z" "joe.z@company.com" d56443a..HEAD
#####################################################################################################

# main
if [[ $# -lt 4 || $# -gt 5 ]]; then
    echo "Syntax: $0 <old_name> <old_email> <new_name> <new_email> <first_commit..last_commit>"
    echo "Commit range is optional, name and email are mandatory!"
    exit 1
fi

export OLD_NAME=$1
export OLD_EMAIL=$2
export NEW_NAME=$3
export NEW_EMAIL=$4
shift 4

echo "Apply settings: old_name=$OLD_NAME old_email=$OLD_EMAIL new_name=$NEW_NAME new_email=$NEW_EMAIL"

git filter-branch --force --env-filter '

old_name="$OLD_NAME"
old_email="$OLD_EMAIL"
new_name="$NEW_NAME"
new_email="$NEW_EMAIL"

if [ "$GIT_COMMITTER_EMAIL" = "$old_email" ]  || [ "$GIT_COMMITTER_NAME" = "$old_name" ]
then
    echo "Updating GIT_COMMITTER_NAME=$GIT_COMMITTER_NAME => $new_name and GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL => $new_email"
    export GIT_COMMITTER_NAME="$new_name"
    export GIT_COMMITTER_EMAIL="$new_email"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$old_email" ] || [ "$GIT_AUTHOR_NAME" = "$old_name" ]
then
    echo "Updating GIT_AUTHOR_NAME=$GIT_AUTHOR_NAME => $new_name and GIT_AUTHOR_EMAIL=$GIT_AUTHOR_EMAIL => $new_email"
    export GIT_AUTHOR_NAME="$new_name"
    export GIT_AUTHOR_EMAIL="$new_email"
fi
' --tag-name-filter cat -- --branches --tags "$@"
