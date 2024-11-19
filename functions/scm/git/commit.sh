# Performs a Git commit with a backdated timestamp.
# This function allows committing changes with a custom date in the past.
#
# Usage:
#   git_commit_backdate [options]
#
# Options should include date and commit message parameters
#
# Note: Use with caution as backdating commits can affect project history
#
git_commit_backdate() {
  local time_offset commit_hash dry_run=false

  show_usage() {
    echo "Usage: git_commit_backdate [-t|--time <seconds>] [-c|--commit <hash>] [-d|--dry-run]"
    echo "Options:"
    echo "  -t, --time <seconds>    Time offset in seconds to backdate"
    echo "  -c, --commit <hash>     Starting commit hash"
    echo "  -d, --dry-run          Show what would be done"
    echo "  -h, --help             Show this help message"
  }

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -t | --time)
        time_offset="$2"
        shift 2
        ;;
      -c | --commit)
        commit_hash="$2"
        shift 2
        ;;
      -d | --dry-run)
        dry_run=true
        shift
        ;;
      -h | --help)
        show_usage
        return 0
        ;;
      *)
        echo "Error: Unknown parameter $1"
        show_usage
        return 1
        ;;
    esac
  done

  [[ -z "$time_offset" || -z "$commit_hash" ]] && {
    echo "Error: Missing required parameters"
    show_usage
    return 1
  }
  [[ ! "$time_offset" =~ ^[0-9]+$ ]] && {
    echo "Error: Time offset must be a positive integer"
    return 1
  }

  if ! git rev-parse --quiet --verify "$commit_hash^{commit}" >/dev/null; then
    echo "Error: Invalid commit hash: $commit_hash"
    return 1
  fi

  if ! command -v git-filter-repo >/dev/null 2>&1; then
    echo "Error: git-filter-repo not found. Install with: brew install git-filter-repo"
    return 1
  fi

  # Create backup branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  backup_branch="backup_${current_branch}_$(date +%Y%m%d_%H%M%S)"
  git branch "$backup_branch"

  echo "Backdating commits starting from $commit_hash by $time_offset seconds"
  echo "Backup branch created: $backup_branch"

  if [[ "$dry_run" = true ]]; then
    echo "Dry run - would modify commits from $commit_hash to HEAD"
    git log --format="%h %ai %s" "$commit_hash"~1..HEAD
    return 0
  fi

  git filter-repo --force --quiet --commit-callback "
time_offset = $time_offset

def adjust_date(date_str):
    timestamp, timezone = date_str.decode('utf-8').split(' ', 1)
    new_timestamp = int(timestamp) - time_offset
    return f'{new_timestamp} {timezone}'.encode('utf-8')

commit.author_date = adjust_date(commit.author_date)
commit.committer_date = adjust_date(commit.committer_date)
" --refs "$commit_hash"~1..HEAD

  echo "Success! Original branch backed up to: $backup_branch"
  echo "Modified commits:"
  git log --format="%h %ai %s" "$commit_hash"~1..HEAD
}
