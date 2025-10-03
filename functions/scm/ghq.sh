# Functions to work with ghq tool


cdq() {
  # Starship Zephyr-inspired color variables
  local COLOR_RESET="\033[0m"
  local COLOR_ERR="\033[1;31m"      # Bold Red
  local COLOR_OK="\033[1;32m"       # Bold Green
  local COLOR_PROMPT="\033[1;33m"   # Bold Yellow
  local COLOR_DIR="\033[1;36m"      # Bold Cyan
  local COLOR_NUM="\033[1;35m"      # Bold Magenta

  if [[ -z "$1" ]]; then
    echo -e "${COLOR_ERR}✗ Error:${COLOR_RESET} Please provide a directory name."
    return 1
  fi

  local dirs
  dirs=$(ghq list -p "$1")

  if [[ -z "$dirs" ]]; then
    echo -e "${COLOR_ERR}✗ Error:${COLOR_RESET} No matching directories found for: ${COLOR_PROMPT}$1${COLOR_RESET}"
    return 1
  fi

  if [[ -n $ZSH_VERSION ]]; then
    # shellcheck disable=SC2296
    local target_dirs=("${(@f)dirs}")
  else
    # shellcheck disable=SC2206
    local target_dirs=($dirs)
  fi

  local dir_count
  dir_count=${#target_dirs[@]}

  if [ "$dir_count" -eq 1 ]; then
    # shellcheck disable=SC2124
    local dir="${target_dirs[@]:0:1}"
    cd "$dir" || return 1
    echo -e "${COLOR_OK}✔ Changed to directory:${COLOR_RESET} ${COLOR_DIR}$dir${COLOR_RESET}"
  else
    echo -e "${COLOR_PROMPT}Multiple matching directories found:${COLOR_RESET}"
    local i=1
    for dir in "${target_dirs[@]}"; do
      echo -e "  ${COLOR_NUM}$i${COLOR_RESET}: ${COLOR_DIR}$dir${COLOR_RESET}"
      ((i++))
    done

    local selection
    echo -ne "${COLOR_PROMPT}Select a directory (1-$dir_count): ${COLOR_RESET}"
    read -r selection

    selection=$(echo "$selection" | tr -cd '[:digit:]')

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$dir_count" ]; then
      echo -e "${COLOR_ERR}✗ Error:${COLOR_RESET} Invalid selection."
      return 1
    fi

    # shellcheck disable=SC2124
    local selected_dir="${target_dirs[@]:$((selection-1)):1}"
    cd "$selected_dir" && echo -e "${COLOR_OK}✔ Changed to directory:${COLOR_RESET} ${COLOR_DIR}$selected_dir${COLOR_RESET}"
  fi
}

ghq_tree() {
  local root_dir="${1:-~/$HOME}"

  if [ -d "$root_dir" ]; then
    tree -d "$root_dir/github.com/" -L 2
  else
    echo "Directory $root_dir does not exist."
  fi
}
