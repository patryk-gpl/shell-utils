if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../../shared.sh"
fi
prevent_to_execute_directly

git_rebase_cleanup_files() {
  local rebase_patterns=("*_BACKUP_*" "*_BASE_*" "*_LOCAL_*" "*_REMOTE_*")
  local removed_files=0
  local removed_file_list=()

  while IFS= read -r -d '' file; do
    if rm "$file"; then
      ((removed_files++))
      removed_file_list+=("$file")
    fi
  done < <(find . -type f \( -name "${rebase_patterns[0]}" -o -name "${rebase_patterns[1]}" \
    -o -name "${rebase_patterns[2]}" -o -name "${rebase_patterns[3]}" \) -print0)

  if [[ $removed_files -eq 0 ]]; then
    echo "No files were removed."
  else
    echo "Removed $removed_files file(s):"
    echo
    printf '%s\n' "${removed_file_list[@]}" | sed 's|^./||'
  fi
}
