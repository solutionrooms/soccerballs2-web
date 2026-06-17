import http.server, socketserver, os
PORT = 8753
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "html5", "bin")
os.chdir(ROOT)
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()
socketserver.TCPServer.allow_reuse_address = True
print("serving", ROOT, "on", PORT, "with no-cache")
with socketserver.TCPServer(("", PORT), H) as httpd:
    httpd.serve_forever()
