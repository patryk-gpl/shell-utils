# Convert an epoch timestamp (seconds or milliseconds) to an RFC3339 UTC datetime.
#
# Usage:
#   date_expiry_to_human_format EPOCH
#
# Arguments:
#   EPOCH  Epoch time in seconds or milliseconds. May be quoted; non-digits will be removed.
#
# Output:
#   Writes an RFC3339 UTC timestamp (YYYY-MM-DDTHH:MM:SSZ) to stdout.
#
# Exit codes:
#   0  Success
#   2  Missing argument
#   3  Invalid epoch value
#
# Notes:
#   - Detects GNU date vs BSD date (macOS) and uses the appropriate flag.
#   - If the provided epoch looks like milliseconds (>=13 digits or > 9999999999),
#     it will be converted to seconds by dividing by 1000.
date_expiry_to_human_format() {
  if [ -z "$1" ]; then
    printf 'Usage: date_expiry_to_human_format EPOCH_STRING\n' >&2
    return 2
  fi

  ts=$1

  # Strip surrounding single/double quotes if present and keep digits only
  ts=${ts%\"}
  ts=${ts#\"}
  ts=${ts%\'}
  ts=${ts#\'}
  ts=$(printf '%s' "$ts" | tr -cd '0-9')

  if [ -z "$ts" ]; then
    printf 'Invalid epoch: %s\n' "$1" >&2
    return 3
  fi

  # If it's milliseconds (13+ digits or greater than 9999999999), convert to seconds
  if [ "${#ts}" -ge 13 ] || [ "$ts" -gt 9999999999 ]; then
    ts=$((ts / 1000))
  fi

  # Use GNU date (-d) if available, otherwise use BSD/macOS date (-r)
  if date --version >/dev/null 2>&1; then
    date -u -d "@$ts" +"%Y-%m-%dT%H:%M:%SZ"
  else
    date -u -r "$ts" +"%Y-%m-%dT%H:%M:%SZ"
  fi
}
