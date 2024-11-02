pf_manage_rule() {
  local fqdn pf_conf="/etc/pf.conf" custom_conf="/etc/pf.anchors/custom"

  show_help() {
    echo "Usage: pf_manage_rule [--block <fqdn> | --unblock <fqdn> | --list [<anchorfile>] | -h]"
    echo ""
    echo "Options:"
    echo "  --block <fqdn>     Add a rule to block traffic to the specified fully qualified domain name (FQDN)."
    echo "  --unblock <fqdn>   Remove the rule blocking traffic to the specified FQDN."
    echo "  --list [<anchorfile>]  List all rules in the specified anchor file. If no file is specified, the default is /etc/pf.anchors/custom."
    echo "  -h                 Show this help message."
    echo ""
    echo "Examples:"
    echo "  pf_manage_rule --block example.com"
    echo "  pf_manage_rule --unblock example.com"
    echo "  pf_manage_rule --list"
    echo "  pf_manage_rule --list /path/to/anchorfile"
  }

  ensure_pf_setup() {
    grep -q 'anchor "custom"' "$pf_conf" || echo 'anchor "custom"' | sudo tee -a "$pf_conf" > /dev/null
    grep -q 'load anchor "custom" from "/etc/pf.anchors/custom"' "$pf_conf" || \
      echo 'load anchor "custom" from "/etc/pf.anchors/custom"' | sudo tee -a "$pf_conf" > /dev/null
    [[ -f "$custom_conf" ]] || sudo touch "$custom_conf"
  }

  [[ $# -lt 1 || $# -gt 2 ]] && { show_help; return 1; }

  case "$1" in
    --block)
      fqdn="$2"
      [[ -z "$fqdn" ]] && { show_help; return 1; }
      ensure_pf_setup
      grep -q "block drop out quick inet from any to $fqdn" "$custom_conf" && \
        { echo "Rule for $fqdn already exists."; return; }
      echo "block drop out quick inet from any to $fqdn" | sudo tee -a "$custom_conf" > /dev/null
      echo "Rule for $fqdn added."
      ;;
    --unblock)
      fqdn="$2"
      [[ -z "$fqdn" ]] && { show_help; return 1; }
      ensure_pf_setup
      grep -q "block drop out quick inet from any to $fqdn" "$custom_conf" || \
        { echo "No rule for $fqdn."; return; }
      sudo sed -i '' "/block drop out quick inet from any to $fqdn/d" "$custom_conf"
      echo "Rule for $fqdn removed."
      ;;
    --list)
      custom_conf="${2:-$custom_conf}"
      [[ -f "$custom_conf" ]] || { echo "Anchor file not found: $custom_conf"; return 1; }
      cat "$custom_conf"
      return
      ;;
    -h) show_help; return ;;
    *) show_help; return 1 ;;
  esac

  [[ -f "$pf_conf" ]] || { echo "Error: pf.conf not found at $pf_conf"; return 1; }

  echo "Reloading pf configuration"
  sudo pfctl -f "$pf_conf"
  sudo pfctl -e
  sudo pfctl -sr
}
