#!/usr/bin/env bash

set -euo pipefail

for file in "$@"; do
    if [[ -x "$file" ]]; then
        echo "Error: Shell function is executable: $file"
        exit 1
    fi
done
