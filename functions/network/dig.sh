dig_get_all_dns_records() {
  if [ $# -eq 0 ]; then
    echo "Usage: dig_get_all_dns_records <domain>" >&2
    return 1
  fi

  domain="$1"
  root_domain=$(echo "$domain" | awk -F. '{print $(NF-1)"."$NF}')
  record_types="A AAAA CNAME MX NS SOA TXT PTR SRV"

  echo "DNS records for $domain:"
  echo "========================="

  for type in $record_types; do
    result=$(dig +nocmd +noall +answer "$domain" "$type")
    if [ -n "$result" ]; then
      echo "--- $type Records ---"
      echo "$result"
      echo
    fi
  done

  # Check for SPF record
  spf_result=$(dig +short "$domain" TXT | grep "v=spf1")
  if [ -n "$spf_result" ]; then
    echo "--- SPF Record ---"
    echo "$spf_result"
    echo
  fi

  # Check root domain if it's different from the queried domain
  if [ "$domain" != "$root_domain" ]; then
    echo "DNS records for root domain ($root_domain):"
    echo "==========================================="
    for type in $record_types; do
      result=$(dig +nocmd +noall +answer "$root_domain" "$type")
      if [ -n "$result" ]; then
        echo "--- $type Records ---"
        echo "$result"
        echo
      fi
    done
  fi
}

# Queries DNS over HTTPS using Cloudflare's DNS service.
# This function uses the `dig` command to perform the DNS query.
# Usage:
#   dig_query_dns_over_https_via_cloudflare <domain>
# Arguments:
#   <domain> - The domain name to query.
# Example:
#   dig_query_dns_over_https_via_cloudflare example.com
dig_query_dns_over_https_via_cloudflare() {
  local hostname=""
  local record_type="A"
  local arg

  for arg in "$@"; do
    case "${arg}" in
      -h | --help)
        echo "Usage: ${FUNCNAME[0]} [-h | --help] [-t | --type <type>] <hostname>"
        echo ""
        echo "Arguments:"
        echo "  <hostname>        The hostname to query. (Required)"
        echo "  -t, --type <type> The DNS record type to query (e.g., A, AAAA, MX, TXT)."
        echo "                    Default: A"
        echo "  -h, --help        Display this help message."
        return 0
        ;;
      -t | --type)
        if [[ -n "${2-}" && "${2-}" != -* ]]; then
          record_type="$2"
          shift
        else
          echo "Error: -t/--type option requires a value." >&2
          return 1
        fi
        ;;
      -*)
        echo "Error: Invalid option: ${arg}" >&2
        echo "Usage: ${FUNCNAME[0]} [-h | --help] [-t | --type <type>] <hostname>" >&2
        return 1
        ;;
      *)
        if [[ -z "${hostname}" ]]; then
          hostname="${arg}"
        else
          echo "Error: Unexpected argument: ${arg}" >&2
          return 1
        fi
        ;;
    esac
    shift
  done

  if [[ -z "${hostname}" ]]; then
    echo "Error: Hostname is required." >&2
    echo "Usage: ${FUNCNAME[0]} [-h | --help] [-t | --type <type>] <hostname>" >&2
    return 1
  fi

  local doh_url="https://chrome.cloudflare-dns.com/dns-query"
  curl -sH 'accept: application/dns-json' "${doh_url}?name=${hostname}&type=${record_type}" | jq .
}
