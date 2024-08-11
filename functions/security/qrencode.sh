if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi
prevent_to_execute_directly

qrencode_generate_fingerprint_code() {
  echo "D5B5760DAE881A77D30D3C2BEC9DE6EAF150DA18" | qrencode -o fingerprint_qr.png -l H
}
