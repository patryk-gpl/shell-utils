#!/usr/bin/env bash

set -euo pipefail

# Check if any shell script or bats file has a hyphen in its filename
for file in "$@"; do
    if [[ "$file" =~ .*\.(sh|bats)$ && "$file" =~ - ]]; then
        echo "Error: Shell script or Bats test filename contains a hyphen: $file"
        echo "Please use underscores instead of hyphens in shell script and Bats test filenames."
        echo "The scripts in this repository follow Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html"
        exit 1
    fi
done

exit 0
