#!/usr/bin/env bash

function cdq() {
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a directory name."
        return 1
    fi

    # local target_dir
    target_dir="$(ghq list -p "$1")"

    if [ -d "$target_dir" ]; then
        cd "$target_dir" || return
    else
        echo "Error: Directory does not exist: $1"
        return 1
    fi
}
