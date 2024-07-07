#!/usr/bin/env bash

git_repo_path="$(ghq list -p shell-utils)/functions"

while IFS= read -r -d '' file; do
  # shellcheck disable=SC1090
  source "$file"
done < <(find "$git_repo_path" -type f -name "*.sh" -print0)
