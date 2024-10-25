shfmt_format_shell_scripts() {
  local dir="$1"

  if [ -z "$dir" ]; then
    echo "Usage: shfmt_format_shell_and_bats_scripts <dir>"
    return 1
  fi

  extensions=("sh" "bats")
  for ext in "${extensions[@]}"; do
    echo "Formatting $ext files in $dir"
    find "$dir" -type f -name "*.$ext" -exec shfmt -i 2 -ci -w {} \;
  done
  echo "Formatting completed in $dir"
}
