#!/usr/bin/env bash

# Copy folders recursively.
# List of files and folders to be excluded can be provided on run-time
# or else the default config will be used $HOME/rsync.exclude if exists!
copy_dir() {
    src="$1"
    dest="$2"
    config="${3:-$HOME/rsync.exclude}"

    if [[ ! -d "$src" || ! -d "$dest" ]]; then
        echo "Source or destination are missing. Aborting.."
        return 1
    fi

    rsync_opts=("-a")
    if [[ -f "$config" ]]; then
        rsync_opts+=("--exclude-from=$config")
    else
        echo "Config $config file is missing. No folders will be excluded from copy."
    fi

    echo "Running rsync with options: ${rsync_opts[@]}"
    rsync "${rsync_opts[@]}" "$src/" "$dest"
}


git_search() {
    pattern=$1
    if [ -z "$pattern" ]; then
        echo "Missing pattern. Aborting.."
        return
    fi
    git log --all -S"$pattern" --oneline \
     | while read -r commit; do git show "${commit:0:7}" ; done
}

# Show folder name and its size, sort the result
function git_folder_size() {
    for dir in "$1"/*; do
        if [ -d "$dir" ]; then
            if [ -d "$dir/.git" ]; then
                size=$(du -sh "$dir" | awk '{print $1}')
                echo "$size - $dir"
                if [-f "$dir/.meta" ]; then
                    git_folder_size "$dir"
                fi
            else
                git_folder_size "$dir"
            fi
        fi
    done | sort -h
}


git_is_shallow_repo() {
    dir=${1:-.}
    find "$dir" -type d -name ".git" -execdir sh -c '
        git rev-parse --is-shallow-repository | grep -c true > /dev/null &&
            echo "Git shallow copy: $(pwd)" ||
            echo "Git not shallow: $(pwd)"
    ' \;
}

git_gc() {
    dir=${1:-.}
    echo "Running 'git gc' command on directories containing '.git' in $dir"
    find "$dir" -type d -name ".git" -execdir git gc {} \;
}
