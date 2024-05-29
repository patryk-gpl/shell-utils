#!/usr/bin/env bash
if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# convert myVar to my-var
convert_camel_case_to_kebab_case() {
  echo "$1" | sed -r 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]'
}

# convert myVar to my_var
convert_camel_case_to_snake_case() {
  echo "$1" | sed -r 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]'
}

# convert my-var to myVar
convert_kebap_case_to_camel_case() {
  echo "$1" | awk -F"-" '{printf "%s", $1; for(i=2; i<=NF; i++) printf "%s", toupper(substr($i, 1, 1)) substr($i, 2)}'
}

# convert my-var to my_var
convert_kebab_case_to_snake_case() {
  echo "${1//-/_}"
}

# convert my_var to myVar
convert_snake_case_to_camel_case() {
  echo "$1" | awk -F"_" '{printf "%s", $1; for(i=2; i<=NF; i++) printf "%s", toupper(substr($i, 1, 1)) substr($i, 2)}'
}

# convert my_var to my-var
convert_snake_case_to_kebab_case() {
  echo "${1//_/-}"
}

# convert my_var to MY_VAR
convert_snake_case_to_upper_snake_case() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# convert MY_VAR to my_var
convert_upper_snake_case_to_snake_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert tabs to spaces in a file and print the number of tabs converted
convert_tabs_to_spaces() {
  local file=$1
  if [[ -f $file ]]; then
    beforeTabs=$(grep $'\t' -o "$file" | wc -l | tr -d '[:space:]')
    expand -t 2 "$file" >"${file}.tmp" && mv "${file}.tmp" "$file"
    echo "Number of tabs converted to spaces in $file: $beforeTabs"
  else
    echo "File $file does not exist."
  fi
}

remove_trailing_newlines_from_files_recursively() {
  local folder="$1"
  if [[ -z $folder ]]; then
    echo "Error: folder not provided."
    return 1
  fi

  local ignore_extensions=("png" "jks" "jpg" "gif" "pdf")
  local ignore_files=()
  for ext in "${ignore_extensions[@]}"; do
    ignore_files+=("-not")
    ignore_files+=("-name")
    ignore_files+=("*.$ext")
  done
  local common_options=(-type f -not -path '*/.git/*' "${ignore_files[@]}")

  if [[ "$OSTYPE" == "darwin"* ]]; then
    find "$folder" "${common_options[@]}" -exec sed -i '' -e :a -e '/^$/{N;ba' -e '}' {} \;
  else
    find "$folder" "${common_options[@]}" -exec sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' {} \;
  fi
}

remove_trailing_spaces_from_files_recursively() {
  local folder="$1"
  if [[ -z $folder ]]; then
    echo "Error: folder not provided."
    return 1
  fi

  local ignore_extensions=("png" "jks" "jpg" "gif" "pdf")
  local ignore_files=()
  for ext in "${ignore_extensions[@]}"; do
    ignore_files+=("-not")
    ignore_files+=("-name")
    ignore_files+=("*.$ext")
  done
  local common_options=(-type f -not -path '*/.git/*' "${ignore_files[@]}")

  if [[ "$OSTYPE" == "darwin"* ]]; then
    find "$folder" "${common_options[@]}" -exec sed -i '' -e 's/[[:space:]]*$//' {} \;
  else
    find "$folder" "${common_options[@]}" -exec sed -i -e 's/[[:space:]]*$//' {} \;
  fi
}

remove_trailing_chars() {
  local folder="$1"
  remove_trailing_newlines_from_files_recursively "$folder"
  remove_trailing_spaces_from_files_recursively "$folder"
}
