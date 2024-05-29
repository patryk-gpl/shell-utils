#!/usr/bin/env zsh

git_repo_path="$(ghq list -p shell-utils)/functions"

# shellcheck disable=SC1090,SC2044
for file in $(find "$git_repo_path" -type f -name "*.sh"); do
  source "$file"
done
