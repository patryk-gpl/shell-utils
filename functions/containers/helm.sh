if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

function helm_history_all_releases() {
  local releases
  releases=$(helm list --all-namespaces --all -o json | jq -r '.[] | "\(.name) \(.namespace)"')

  if [ -z "$releases" ]; then
    echo "No Helm releases found in the cluster."
    return
  fi

  echo "$releases" | while read -r name namespace; do
    echo "=== History for release '$name' in namespace '$namespace' ==="
    helm history "$name" -n "$namespace"
    echo # Empty line for better readability
  done
}

helm_get_release_details() {
  local release_name=""
  local revision=""
  local zipfile=""
  local password=""

  # Parse command line arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -h | --help)
        cat <<EOF
Usage: helm_get_release_details <release_name> <revision> [-z <zipfile>] [-p <password>]

Purpose:
    This function retrieves detailed information about a specific Helm release
    at a given revision. It exports data for various subcommands (hooks, manifest,
    metadata, notes, and values) into separate log files.

Arguments:
    release_name    The name of the Helm release
    revision        The revision number of the release

Options:
    -z, --zipfile <zipfile>    Compress output files into a zip archive
    -p, --password <password>  Set a password for the zip archive (requires -z)
    -h, --help                 Show this help message

Output:
    Creates log files named <release_name>-<revision>-<subcommand>.log
    for each non-empty subcommand output. If -z is specified, creates a zip archive.

Example:
    helm_get_release_details my-release 3 -z output.zip -p mypassword

Note:
    Empty log files are automatically removed.
EOF
        return 0
        ;;
      -z | --zipfile)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "Error: -z|--zipfile requires a non-empty argument"
          return 1
        fi
        zipfile="$2"
        shift 2
        ;;
      -p | --password)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "Error: -p|--password requires a non-empty argument"
          return 1
        fi
        password="$2"
        shift 2
        ;;
      *)
        if [[ -z "$release_name" ]]; then
          release_name="$1"
        elif [[ -z "$revision" ]]; then
          revision="$1"
        else
          echo "Error: Unexpected argument: $1"
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$release_name" || -z "$revision" ]]; then
    echo "Error: Both release name and revision number are required."
    echo "Use -h or --help for usage information."
    return 1
  fi

  if [[ -n "$password" && -z "$zipfile" ]]; then
    echo "Error: Password (-p) can only be used with zipfile (-z)."
    return 1
  fi

  local subcommands=("hooks" "manifest" "metadata" "notes" "values")
  local files_created=()

  for cmd in "${subcommands[@]}"; do
    local output_file="${release_name}-${revision}-${cmd}.log"
    echo "Exporting $cmd to $output_file..."
    if ! helm get "$cmd" "$release_name" --revision "$revision" >"$output_file"; then
      echo "Warning: Failed to get $cmd for $release_name (revision $revision)"
    fi

    if [ ! -s "$output_file" ]; then
      echo "Removing empty file: $output_file"
      rm "$output_file"
    else
      files_created+=("$output_file")
    fi
  done

  if [[ ${#files_created[@]} -eq 0 ]]; then
    echo "No files exported."
    return 0
  fi

  echo "Exported files:"
  printf '%s\n' "${files_created[@]}"

  if [[ -n "$zipfile" ]]; then
    if [[ -n "$password" ]]; then
      zip -e -P "$password" "$zipfile" "${files_created[@]}"
    else
      zip "$zipfile" "${files_created[@]}"
    fi
    echo "Created zip archive: $zipfile"
    rm "${files_created[@]}"
  fi
}
