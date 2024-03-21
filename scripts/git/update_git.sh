#!/usr/bin/env bash
set -e

branch="$1"
if [[ -z "$branch" ]]; then
  read -r -p "Do you want to switch a branch during Git update? [y/n] " response
  if [[ "$response" =~ ^[yY]+$ ]]; then
    read -r -p "Enter the branch name: " branch
  fi
fi

for folder in *; do
  if [[ -d "$folder/.git" ]]; then
    cd "$folder" || {
        echo "Failed to enter $folder"
        exit 1
    }

    if [[ -n "$branch" ]]; then
      # Check if the branch exists on the remote repository
      if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        echo "== Switching to branch $branch in $folder =="
        git checkout "$branch"
      else
        echo "Branch $branch does not exist in remote repository of $folder"
        cd ..
        continue
      fi
    fi
    git fetch --prune

    echo "== Updating Git $folder =="
    git-up && cd ..
  fi
done
