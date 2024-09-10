import http.server
import socketserver


class HTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        client_ip = self.client_address[0]
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(f"Your IP address is: {client_ip}".encode("utf-8"))


class SimpleWebServer:
    def __init__(self, host="0.0.0.0", port=8080):
        self.host = host
        self.port = port
        self.handler = HTTPRequestHandler
        self.httpd = socketserver.TCPServer((self.host, self.port), self.handler)

    def start(self):
        print(f"Serving on {self.host}:{self.port}")
        self.httpd.serve_forever()

    def stop(self):
        self.httpd.shutdown()
        print("Server stopped.")


if __name__ == "__main__":
    server = SimpleWebServer(host="0.0.0.0", port=8080)
    try:
        server.start()
    except KeyboardInterrupt:
        server.stop()
