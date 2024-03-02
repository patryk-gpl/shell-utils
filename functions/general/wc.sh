#!/usr/bin/env bash
# This file contains functions to work wc (word count) tool

if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

# Count the number of quotes in a file
wc_count_quotes_in_file() {
  filename=$1
  if [[ -z "${filename}" ]]; then
    echo "File is missing. Aborting.."
    return 1
  fi
  single_quotes=$(grep -o "'" "${filename}" | wc -l | sed 's/^[ \t]*//')
  double_quotes=$(grep -o '"' "${filename}" | wc -l | sed 's/^[ \t]*//')
  triple_single_quotes=$(grep -o "'''" "${filename}" | wc -l | sed 's/^[ \t]*//')
  triple_double_quotes=$(grep -o '"""' "${filename}" | wc -l | sed 's/^[ \t]*//')

  echo "== Filename: ${filename} =="
  echo "Single Quotes: $single_quotes, Triple Single Quotes: $triple_single_quotes"
  echo "Double Quotes: $double_quotes, Triple Double Quotes: $triple_double_quotes"
}
