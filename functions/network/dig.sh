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
