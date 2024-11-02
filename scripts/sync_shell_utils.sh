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
