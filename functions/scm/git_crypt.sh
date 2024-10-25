git_crypt_enable() {
  local repo_path=""
  local key_path=""
  local encrypt_paths=""
  local working_dir

  # Store the current working directory
  working_dir=$(pwd)

  show_help() {
    echo "Usage: git_crypt_enable -r <path_to_repository> [-k <path_to_key>] [-p <paths_to_encrypt>]"
    echo
    echo "Options:"
    echo "  -r <path_to_repository>  The path to the Git repository where git-crypt should be enabled"
    echo "  -k <path_to_key>         (Optional) The path to a custom git-crypt key file"
    echo "  -p <paths_to_encrypt>    (Optional) Comma-separated list of paths to encrypt"
    echo "  -h                       Display this help message"
    echo
    echo "Description:"
    echo "  This function sets up git-crypt encryption for a specified Git repository."
    echo "  It initializes git-crypt, configures .gitattributes for specified paths or a default 'secrets' directory."
    echo "  If a key is provided and the repository is not initialized, it will initialize git-crypt with the provided key."
    echo
    echo "Requirements:"
    echo "  - git and git-crypt must be installed and accessible in the PATH"
    echo
    echo "Examples:"
    echo "  git_crypt_enable -r /path/to/your/repo"
    echo "  git_crypt_enable -r /path/to/your/repo -k /path/to/custom/key"
    echo "  git_crypt_enable -r /path/to/your/repo -p \"*.txt,*.log,secret/\""
    echo
    echo "For more information, see the full function documentation."
  }

  if ! command -v git >/dev/null 2>&1 || ! command -v git-crypt >/dev/null 2>&1; then
    echo "Error: git and git-crypt are required. Please install them and ensure they're in your PATH." >&2
    return 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r | --repo)
        repo_path="$2"
        shift 2
        ;;
      -k | --key)
        key_path="$2"
        shift 2
        ;;
      -p | --paths)
        encrypt_paths="$2"
        shift 2
        ;;
      -h | --help)
        show_help
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        show_help
        return 1
        ;;
    esac
  done

  if [ -z "$repo_path" ]; then
    echo "Error: Repository path is required." >&2
    show_help
    return 1
  fi

  # Handle relative paths
  if [[ ! "$repo_path" = /* ]]; then
    repo_path="$working_dir/$repo_path"
  fi

  # Create the directory if it doesn't exist
  if [ ! -d "$repo_path" ]; then
    mkdir -p "$repo_path"
  fi

  # Convert repo_path to absolute path
  repo_path=$(cd "$repo_path" && pwd)

  if [ -n "$key_path" ]; then
    # Handle relative paths for key_path
    if [[ ! "$key_path" = /* ]]; then
      key_path="$working_dir/$key_path"
    fi
    if [ ! -f "$key_path" ]; then
      echo "Error: The specified key file does not exist." >&2
      return 1
    fi
  fi

  # Change to the repository directory
  cd "$repo_path" || return 1

  if [ ! -d .git ]; then
    echo "The specified directory is not a git repository. Initializing..."
    git init
  fi

  if [ ! -f .git/git-crypt/keys/default ]; then
    echo "Initializing git-crypt..."
    if [ -n "$key_path" ]; then
      git-crypt unlock "$key_path"
      echo "Initialized git-crypt with the provided key."
    else
      git-crypt init
      echo "Initialized git-crypt with a new key."
    fi
  else
    echo "git-crypt is already initialized in this repository."
    if [ -n "$key_path" ]; then
      echo "Attempting to unlock with the provided key..."
      if git-crypt unlock "$key_path"; then
        echo "Successfully unlocked the repository with the provided key."
      else
        echo "Error: Unable to unlock the repository with the provided key."
        return 1
      fi
    fi
  fi
  echo -n "Checksum of the git-crypt key used: "
  sha256sum .git/git-crypt/keys/default | awk '{print $1}'

  # Configure .gitattributes
  gitattributes_changed=false
  if [ -n "$encrypt_paths" ]; then
    IFS=',' read -ra PATHS <<<"$encrypt_paths"
    for path in "${PATHS[@]}"; do
      path=$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      if ! grep -Fxq "$path filter=git-crypt diff=git-crypt" .gitattributes 2>/dev/null; then
        echo "$path filter=git-crypt diff=git-crypt" >>.gitattributes
        echo "Added '$path' to .gitattributes for encryption."
        gitattributes_changed=true
      else
        echo "'$path' is already in .gitattributes for encryption."
      fi
    done
  else
    echo "No custom paths specified. Using default 'secrets' directory."
    if ! grep -Fxq "secrets/** filter=git-crypt diff=git-crypt" .gitattributes 2>/dev/null; then
      echo "secrets/** filter=git-crypt diff=git-crypt" >>.gitattributes
      echo "Added default 'secrets/**' to .gitattributes for encryption."
      gitattributes_changed=true
    else
      echo "Default 'secrets/**' is already in .gitattributes for encryption."
    fi
    if [ ! -d secrets ]; then
      mkdir -p secrets
      echo "Created 'secrets' directory."
    fi
    if [ ! -f secrets/sample_secret.txt ]; then
      echo "This is a sample secret" >secrets/sample_secret.txt
      echo "Added sample secret file in 'secrets' directory."
    fi
  fi

  # Only commit if .gitattributes has changed
  if $gitattributes_changed; then
    git add -f .gitattributes
    git commit -m "Update .gitattributes for git-crypt" || true
    echo "Committed changes to .gitattributes"
  else
    echo "No changes to .gitattributes were necessary."
  fi

  echo "Status of encrypted files:"
  git-crypt status -e

  if [ -n "$encrypt_paths" ]; then
    echo "git-crypt is enabled for the specified paths in $repo_path."
  else
    echo "git-crypt is enabled for the 'secrets/' directory in $repo_path."
  fi
  echo "Files in these locations will be automatically encrypted."

  cd "$working_dir" || return 1
}
