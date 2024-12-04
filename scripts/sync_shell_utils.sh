#!/usr/bin/env bash

resolve_script_path() {
    local source=$1
    local dir

    while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
        dir="$( cd -P "$( dirname "$source" )" &> /dev/null && pwd )"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    dir="$( cd -P "$( dirname "$source" )" &> /dev/null && pwd )"
    echo "$dir"
}

# Get the real directory of the script, compatible with Bash and Zsh, handling symlinks
if [[ -n $BASH_VERSION ]]; then
    script_dir=$(resolve_script_path "${BASH_SOURCE[0]}")
elif [[ -n $ZSH_VERSION ]]; then
    # shellcheck disable=SC2296
    script_dir=$(resolve_script_path "${(%):-%N}")
else
    script_dir=$(resolve_script_path "$0")
fi

functions_dir="$script_dir/../functions"
functions_mac_dir="$script_dir/../functions_mac"

if [ ! -d "$functions_dir" ]; then
  echo "Error: Directory $functions_dir does not exist."
  return 1
fi

if [ -f "$functions_dir/shared.sh" ]; then
  # shellcheck disable=SC1091
  source "$functions_dir/shared.sh"
else
  echo "$functions_dir/shared.sh not found."
  return 1
fi

while IFS= read -r -d '' file; do
  # shellcheck disable=SC1090
  source "$file"
done < <(find "$functions_dir" -type f -name "*.sh" -print0)

if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -d "$functions_mac_dir" ]; then
    while IFS= read -r -d '' file; do
      # shellcheck disable=SC1090
      source "$file"
    done < <(find "$functions_mac_dir" -type f -name "*.sh" -print0)
  else
    echo "Directory $functions_mac_dir does not exist, skipping Mac-specific scripts."
  fi
fi

# Usage: pull_repos_if_not_cached [<validity_seconds>] repo1 repo2 repo3
pull_repos_if_not_cached() {
    local validity_seconds=$((24 * 60 * 60))  # Default 24 hours
    local repos=("$@")

    # If first arg is a number, treat it as validity_seconds
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        validity_seconds=$1
        repos=("${@:2}")
    fi

    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bin-shell-init"
    local failed=0

    mkdir -p "$cache_dir"

    for repo in "${repos[@]}"; do
        local cache_file="$cache_dir/.last_pull_${repo//\//-}"

        # Check if pulled within validity period
        if [ -f "$cache_file" ]; then
            local cache_age=$(($(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
            if [ "$cache_age" -lt "$validity_seconds" ]; then
                continue
            fi
        fi

        echo "Pulling $repo..."
        local repo_path
        repo_path=$(ghq list -p "$repo" 2>/dev/null) || {
            echo "  ✗ $repo not found"
            failed=1
            continue
        }

        if git -C "$repo_path" pull -r > /dev/null 2>&1; then
            touch "$cache_file"
            echo "  ✓ $repo updated. Refresh time interval: $((validity_seconds / 3600)) hours"
        else
            echo "  ✗ $repo pull failed"
            failed=1
        fi
    done

    return $failed
}
