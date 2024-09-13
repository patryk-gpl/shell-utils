prometheus_service_discovery() {
  local query='up'
  local filters=()
  local status_filter=""
  local output_format="table"
  local prometheus_port="9090"

  usage() {
    echo "Usage: prometheus_service_discovery [OPTIONS]"
    echo "Note: Ensure you have an active port-forward to the Prometheus pod before running this function."
    echo "Example: kubectl port-forward svc/prometheus-server 9090:9090 -n <prometheus-namespace>"
    echo ""
    echo "Options:"
    echo "  -f, --filter FILTER         Filter results (can be used multiple times)"
    echo "                              (e.g., -f 'namespace=\"netreveal\"' -f 'job=~\"netreveal-.*\"')"
    echo "  -s, --status STATUS         Filter by status: up, down, or all (default: all)"
    echo "  -o, --output FORMAT         Output format: table, json (default: table)"
    echo "  -p, --port PORT             Prometheus port (default: 9090)"
    echo "  -h, --help                  Display this help message"
  }

  check_port() {
    nc -z localhost "$1" >/dev/null 2>&1
  }

  while [[ $# -gt 0 ]]; do
    case $1 in
      -f | --filter)
        filters+=("$2")
        shift 2
        ;;
      -s | --status)
        status_filter="$2"
        shift 2
        ;;
      -o | --output)
        output_format="$2"
        shift 2
        ;;
      -p | --port)
        prometheus_port="$2"
        shift 2
        ;;
      -h | --help)
        usage
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        return 1
        ;;
    esac
  done

  if ! check_port "$prometheus_port"; then
    echo "Error: Prometheus port $prometheus_port is not accessible."
    echo "Please ensure you have an active port-forward to the Prometheus pod."
    echo "Example: kubectl port-forward svc/prometheus-server $prometheus_port:$prometheus_port -n <prometheus-namespace>"
    return 1
  fi

  # Combine multiple filters
  if [[ ${#filters[@]} -gt 0 ]]; then
    local filter_string
    filter_string=$(
      IFS=,
      echo "${filters[*]}"
    )
    query="${query}{${filter_string}}"
  fi

  # Add status filter to the query
  case $status_filter in
    up)
      query="${query} == 1"
      ;;
    down)
      query="${query} == 0"
      ;;
  esac

  # URL encode the query
  encoded_query=$(printf '%s' "$query" | jq -sRr @uri)

  # Execute the query using curl
  local result
  result=$(curl -s "http://localhost:$prometheus_port/api/v1/query?query=${encoded_query}")

  # Check if the query was successful
  if [[ $(echo "$result" | jq -r '.status') != "success" ]]; then
    echo "Error: Query failed. Response from Prometheus:"
    echo "$result" | jq .
    return 1
  fi

  # Process and display the results
  if [[ "$output_format" == "json" ]]; then
    echo "$result" | jq .
  else
    echo "$result" | jq -r '
        ["JOB", "INSTANCE", "NAMESPACE", "STATUS"],
        (.data.result[] | [.metric.job, .metric.instance, .metric.namespace, .value[1]])
        | @tsv' | column -t
  fi
}
