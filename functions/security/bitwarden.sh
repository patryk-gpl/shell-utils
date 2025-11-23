# bw_list_accounts_with_passkey
# Print a table of Bitwarden items that have passkeys (FIDO2 credentials).
# Requires an unlocked Bitwarden session in BW_SESSION (run `bw unlock` or `bw login` first).
# Outputs two columns: Name and Username, formatted with `column -t`.
# Exit codes:
#   0 - success
#   1 - BW_SESSION missing or other failure
bw_list_accounts_with_passkey() {
  if [[ -z "${BW_SESSION:-}" ]]; then
    echo "Please run: bw unlock (or bw login) first" >&2
    return 1
  fi

  {
    printf "%s\t%s\n" "Name" "Username"
    bw list items | jq -r '
            .[] |
            select(.login.fido2Credentials != null and (.login.fido2Credentials | length) > 0) |
            "\(.name)\t\(.login.username // "")"
        '
  } | column -t -s $'\t'
}
