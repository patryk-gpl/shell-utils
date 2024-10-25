decode_base64() {
  local input="$1"
  local decoded="$input"
  local temp

  if [ -z "$input" ]; then
    echo "Error: input is empty." >&2
    return 1
  fi

  while true; do
    if temp=$(echo -n "$decoded" | base64 -d 2>/dev/null) && [ -n "$temp" ]; then
      if [ "$temp" = "$decoded" ]; then
        break
      fi

      if echo -n "$temp" | LC_ALL=C grep -q '[^[:print:][:space:]]'; then
        break
      fi

      decoded="$temp"
    else
      break
    fi
  done

  printf '%s' "$decoded"
}

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

remove_empty_lines_with_spaces_from_file() {
  local filename="$1"
  if [[ -z $filename ]]; then
    echo "Error: filename not provided."
    return 1
  fi
  sed '/^$/d; /^[[:space:]]*$/d' "$filename" >"${filename}.tmp" && mv "${filename}.tmp" "$filename"
}

remove_trailing_spaces_from_ascii_files_recursively() {
  local folder="$1"
  if [[ -z $folder ]]; then
    echo "Error: folder not provided."
    return 1
  fi

  local exclude_options_paths=(-type f -not -path '*/.git/*' -not -path '*/.venv/*')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    find "$folder" "${exclude_options_paths[@]}" -exec file {} + | grep ASCII | cut -d: -f1 | xargs -I {} sed -i '' -e 's/[[:space:]]*$//' {}
  else
    find "$folder" "${exclude_options_paths[@]}" -exec file {} + | grep ASCII | cut -d: -f1 | xargs -I {} sed -i -e 's/[[:space:]]*$//' {}
  fi
}

remove_trailing_newlines_from_ascii_files_recursively() {
  local folder="$1"
  if [[ -z $folder ]]; then
    echo "Error: folder not provided."
    return 1
  fi

  local exclude_options_paths=(-type f -not -path '*/.git/*' -not -path '*/.venv/*')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    find "$folder" "${exclude_options_paths[@]}" -exec sed -i '' -e :a -e '/^$/{N;ba' -e '}' {} \;
  else
    find "$folder" "${exclude_options_paths[@]}" -exec sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' {} \;
  fi
}

remove_trailing_chars() {
  local folder="$1"
  remove_trailing_newlines_from_ascii_files_recursively "$folder"
  remove_trailing_spaces_from_ascii_files_recursively "$folder"
}
