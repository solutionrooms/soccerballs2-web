#!/usr/bin/env python3
# Serves the ORIGINAL game's bin/ directory and runs its SWFs through Ruffle (CDN), so we can
# visually confirm which SWF matches the hosted/YouTube version. Non-invasive: writes nothing into
# the original project; the Ruffle host page is injected by this server, not saved into bin/.
#
#   python3 tools/serve-ruffle.py      ->  http://localhost:8754/
#   switch builds via the links, or ?swf=SoccerBalls2_Stage3D.swf
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

BIN = "/Users/jonscott/Projects/SoccerBalls2/bin"
PORT = 8754
# FFDec-patched copy of SoccerBalls2.swf with Game.unlockEverything=true (all levels unlocked),
# served at /SoccerBalls2_unlocked.swf without writing into the original bin/.
PATCHED = "/Users/jonscott/Projects/soccerballs2-web/tools/swf-patched/SoccerBalls2_unlocked.swf"

PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><title>Original SoccerBalls2 (Ruffle)</title>
<style>
 html,body{margin:0;background:#1b1b1b;color:#ddd;font-family:system-ui,sans-serif}
 #wrap{display:flex;flex-direction:column;align-items:center;gap:10px;padding:12px}
 #player{width:700px;height:525px;background:#000;box-shadow:0 0 20px #000}
 .bar{font-size:13px} a{color:#6cf;margin:0 4px}
 #status{font-size:12px;color:#999;min-height:16px}
</style></head>
<body><div id="wrap">
 <div class="bar">Original via Ruffle &mdash; <b id="name"></b>
   &nbsp;|&nbsp; pick build:
   <a href="?swf=SoccerBalls2.swf">main</a>·
   <a href="?swf=SoccerBalls2_Stage3D.swf">Stage3D</a>·
   <a href="?swf=Begamer_SoccerBalls2.swf">Begamer</a>·
   <a href="?swf=SoccerBalls2_unlocked.swf"><b>main + ALL LEVELS unlocked</b></a>
 </div>
 <div id="player"></div>
 <div id="status">loading Ruffle from CDN&hellip;</div>
</div>
<script src="https://unpkg.com/@ruffle-rs/ruffle"></script>
<script>
 var swf = new URLSearchParams(location.search).get("swf") || "SoccerBalls2.swf";
 document.getElementById("name").textContent = swf;
 var st = document.getElementById("status");
 window.RufflePlayer = window.RufflePlayer || {};
 window.addEventListener("DOMContentLoaded", function () {
   if (!window.RufflePlayer || !window.RufflePlayer.newest) {
     st.textContent = "Ruffle failed to load from CDN (no internet?). Tell me and I'll self-host it.";
     return;
   }
   var ruffle = window.RufflePlayer.newest();
   var player = ruffle.createPlayer();
   var c = document.getElementById("player");
   c.appendChild(player);
   player.style.width = "700px"; player.style.height = "525px";
   st.textContent = "booting " + swf + " …";
   player.load({ url: swf, autoplay: "on", letterbox: "on", logLevel: "info" })
     .then(function(){ st.textContent = "running " + swf + " (traces -> browser console)"; })
     .catch(function(e){ st.textContent = "load error: " + e; });
 });
</script>
</body></html>"""

class H(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=BIN, **k)
    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/ruffle", "/ruffle.html"):
            body = PAGE.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/SoccerBalls2_unlocked.swf":
            try:
                with open(PATCHED, "rb") as f:
                    data = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/x-shockwave-flash")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(data)
            except OSError:
                self.send_error(404, "patched SWF not found")
            return
        return super().do_GET()

if __name__ == "__main__":
    ThreadingHTTPServer.allow_reuse_address = True
    httpd = ThreadingHTTPServer(("0.0.0.0", PORT), H)
    print("Ruffle original at http://localhost:%d/   (serving %s)" % (PORT, BIN))
    httpd.serve_forever()
