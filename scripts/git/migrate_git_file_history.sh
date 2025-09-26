#!/usr/bin/env bash
# migrate_git_file_history.sh
#
# Extract and migrate the full commit history of one or more files from a source Git repository
# into a new destination repository, preserving all history for those files.
#
# Usage:
#   ./migrate_git_file_history.sh <source_repo_path> <dest_repo_path> <file_pattern1> [<file_pattern2> ...]
#
# Arguments:
#   <source_repo_path>     Path to the source Git repository (must be a valid git repo)
#   <dest_repo_path>       Path to the destination directory (will be initialized as a new repo)
#   <file_pattern1> [...]  One or more files or glob patterns (relative to the source repo root) to extract and migrate
#
# Requirements:
#   - git-filter-repo (https://github.com/newren/git-filter-repo)
#     Install with: pip install git-filter-repo
#
# What it does:
#   - Validates input and dependencies
#   - Clones the source repo to a temporary directory
#   - Uses git-filter-repo to filter history to only the specified files
#   - Initializes a new destination repo and creates an initial commit
#   - Imports the filtered file history into the destination repo, preserving commit history
#   - Outputs a summary of the migration
#
# Examples:
#   ./migrate_git_file_history.sh ~/src/my-old-repo ~/src/new-repo path/to/file1.txt path/to/file2.sh
#   ./migrate_git_file_history.sh ~/src/my-old-repo ~/src/new-repo "*.py" "docs/*.md"
#   ./migrate_git_file_history.sh ~/src/my-old-repo ~/src/new-repo "src/**/*.js"
#
# Notes:
#   - The destination repo will be reinitialized if it already exists.
#   - Only the history for the specified files will be migrated.
#   - Requires bash 4.0+, git, and git-filter-repo.

# Modern bash settings
set -euo pipefail
# Enable extended pattern matching features and advanced globbing options:
# - 'lastpipe': allows the last command in a pipeline to run in the current shell context,
#   enabling variable assignments within pipelines to persist after the pipeline completes.
# - 'nullglob': causes patterns that do not match any files to expand to nothing,
#   rather than themselves.
# - 'globstar': allows the use of '**' in glob patterns to match all files and directories recursively.
shopt -s lastpipe nullglob globstar

# Modern logging with color support
declare -A LOG_COLORS=(
  [INFO]="\033[1;34m"
  [WARN]="\033[1;33m"
  [ERROR]="\033[1;31m"
  [RESET]="\033[0m"
)

log() {
  local level="$1"
  shift
  printf '%b[%s]%b %s\n' "${LOG_COLORS[$level]}" "$level" "${LOG_COLORS[RESET]}" "$*"
}

log_info() { log INFO "$@"; }
log_warn() { log WARN "$@"; }
log_error() { log ERROR "$@"; }

# Validation functions
validate_source_repo() {
  local repo_path="$1"

  # Check if path exists
  if [[ ! -d "$repo_path" ]]; then
    log_error "Source path '$repo_path' does not exist"
    return 1
  fi

  # Check if it's a git repository
  if [[ ! -d "$repo_path/.git" ]]; then
    log_error "Source path '$repo_path' is not a git repository"
    return 1
  fi

  # Check if we can read the repository
  if ! git -C "$repo_path" status &>/dev/null; then
    log_error "Cannot read git repository at '$repo_path' (may be corrupted or permission denied)"
    return 1
  fi

  return 0
}

validate_destination_path() {
  local dest_path="$1"

  # Check if parent directory exists or can be created
  local parent_dir
  parent_dir=$(dirname "$dest_path")
  if [[ ! -d "$parent_dir" ]]; then
    if ! mkdir -p "$parent_dir" 2>/dev/null; then
      log_error "Cannot create parent directory '$parent_dir' for destination repo"
      return 1
    fi
  fi

  # Check if destination path is writable
  if [[ -e "$dest_path" ]] && [[ ! -w "$dest_path" ]]; then
    log_error "Destination path '$dest_path' exists but is not writable"
    return 1
  fi

  return 0
}

expand_file_patterns() {
  local -n patterns_ref="$1"
  local -n expanded_ref="$2"
  local repo_path="$3"

  expanded_ref=()

  # Change to repo directory for glob expansion
  local original_dir
  original_dir=$(pwd)
  cd "$repo_path" || return 1

  local pattern
  for pattern in "${patterns_ref[@]}"; do
    # Enable nullglob to handle patterns that don't match anything
    local original_nullglob_setting
    original_nullglob_setting=$(shopt -p nullglob)
    shopt -s nullglob

    # Expand the pattern
    local expanded_pattern
    expanded_pattern=("$pattern")

    # If pattern contains wildcards, expand it
    if [[ "$pattern" == *"*"* ]] || [[ "$pattern" == *"?"* ]] || [[ "$pattern" == *"["* ]]; then
      # shellcheck disable=SC2206
      expanded_pattern=($pattern)
    fi

    # Restore nullglob setting
    eval "$original_nullglob_setting"

    # Add results to array
    if ((${#expanded_pattern[@]} == 0)); then
      log_warn "Pattern '$pattern' does not match any files"
    else
      for file in "${expanded_pattern[@]}"; do
        if [[ -f "$file" ]]; then
          expanded_ref+=("$file")
        elif [[ -d "$file" ]]; then
          log_warn "Skipping directory '$file' (only files can be migrated)"
        else
          log_warn "Pattern '$pattern' matched '$file' but it's not a regular file"
        fi
      done
    fi
  done

  cd "$original_dir"

  if ((${#expanded_ref[@]} == 0)); then
    log_error "No files found matching the provided patterns"
    return 1
  fi

  return 0
}

# Git operation functions
clone_and_filter_repo() {
  local src_repo="$1"
  local tmp_dir="$2"
  local -n files_ref="$3"

  log_info "Cloning source repo to temp directory..."
  cd "$tmp_dir"
  git clone --no-local --no-hardlinks "$src_repo" filtered_repo
  cd filtered_repo

  log_info "Filtering repo history to specified files..."
  local filter_args=()
  local file
  for file in "${files_ref[@]}"; do
    filter_args+=(--path "$file")
  done
  git filter-repo "${filter_args[@]}" --force

  log_info "Creating bare clone of filtered repo..."
  cd "$tmp_dir"
  git clone --bare filtered_repo filtered_repo_bare
}

initialize_destination_repo() {
  local dest_repo="$1"

  log_info "Initializing new destination repo at $dest_repo..."
  cd "$dest_repo"
  git init -b main
  git config user.name "Migration Bot"
  git config user.email "migration[bot]@github.com"

  echo "# Extracted file history" >README.md
  git add README.md
  git commit -m "Initial commit"
}

import_filtered_history() {
  local tmp_dir="$1"

  log_info "Adding filtered history as remote and fetching..."
  git remote add extract "$tmp_dir/filtered_repo_bare"
  git fetch extract

  log_info "Merging imported history into main branch..."
  git merge --allow-unrelated-histories extract/main -m "Import file history"

  git remote remove extract
}

if (($# < 3)); then
  log_error "Usage: $0 <source_repo_path> <dest_repo_path> <file_pattern1> [<file_pattern2> ...]"
  exit 1
fi

# Check if git-filter-repo is available
if ! command -v git-filter-repo &>/dev/null; then
  log_error "git-filter-repo is required but not installed. Please install it first."
  log_error "Install with: pip install git-filter-repo"
  exit 1
fi

log_info "Validating source repository: $1"
if ! validate_source_repo "$1"; then
  exit 1
fi
SRC_REPO=$(realpath "$1")

log_info "Validating destination path: $2"
DEST_REPO="$2"
if ! validate_destination_path "$DEST_REPO"; then
  exit 1
fi

ORIG_PWD=$(pwd)
shift 2
FILE_PATTERNS=("$@")
log_info "File patterns to extract: ${FILE_PATTERNS[*]}"

# Expand glob patterns to actual files
EXPANDED_FILES=()
if ! expand_file_patterns FILE_PATTERNS EXPANDED_FILES "$SRC_REPO"; then
  exit 1
fi

log_info "Expanded to ${#EXPANDED_FILES[@]} files: ${EXPANDED_FILES[*]}"
FILES=("${EXPANDED_FILES[@]}")

# Create temporary directory and setup cleanup
TMP_DIR=$(mktemp -d) || {
  log_error "Failed to create temporary directory"
  exit 1
}
readonly TMP_DIR
trap 'rm -rf "$TMP_DIR"' EXIT
log_info "Created temporary directory: $TMP_DIR"

# Setup destination repository path
DEST_REPO_ABS="$DEST_REPO"
if [[ "$DEST_REPO" != /* ]]; then
  DEST_REPO_ABS="$ORIG_PWD/$DEST_REPO"
fi

# Check if destination repo already exists and warn user
if [[ -d "$DEST_REPO_ABS/.git" ]]; then
  log_warn "Destination repository '$DEST_REPO_ABS' already exists and will be reinitialized"
fi

mkdir -p "$DEST_REPO_ABS"
if [[ $(realpath "$DEST_REPO_ABS") == $TMP_DIR* ]]; then
  log_error "Destination repo cannot be inside the temporary directory."
  exit 1
fi

# Perform git operations using modern functions
clone_and_filter_repo "$SRC_REPO" "$TMP_DIR" FILES
initialize_destination_repo "$DEST_REPO_ABS"
import_filtered_history "$TMP_DIR"

# Show migration summary
COMMIT_COUNT=$(git rev-list --count HEAD)
log_info "Migration complete! Summary:"
log_info "  • Repository: $DEST_REPO_ABS"
log_info "  • Files migrated: ${FILES[*]}"
log_info "  • Total commits: $COMMIT_COUNT"
log_info "  • Branches available: $(git branch -r | grep -c extract/ || echo 0) (from filtered repo)"
