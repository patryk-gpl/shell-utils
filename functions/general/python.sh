# This file contains functions to utilize Python CLI

alias python_find_local_ports_opened='python -c "import socket; open_ports = [port for port in range(1, 65536) if socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect_ex((\"localhost\", port)) == 0]; print(\"Open ports:\", open_ports)"'

python_check_url_content() {
  if [ -z "$1" ]; then
    echo "Error: URL not provided. Usage: python_check_url_content <URL>"
    return 1
  fi

  python -c "import requests; url = '$1'; response = requests.get(url); print(f'Content is returned (Status Code: {response.status_code})' if response.content else 'No content returned')"
}
