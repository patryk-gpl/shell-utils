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
