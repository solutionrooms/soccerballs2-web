// No-cache static server for the built Haxe game (the -Dreplica build in bin/html5/bin).
// Run via `npm run replica:serve`. Port overridable with PORT env (default 8753).
const http = require('http');
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..', 'haxe-port', 'bin', 'html5', 'bin');
const PORT = Number(process.env.PORT || 8753);
const MIME = { '.js': 'text/javascript', '.html': 'text/html', '.json': 'application/json', '.png': 'image/png', '.ogg': 'audio/ogg', '.m4a': 'audio/mp4', '.wav': 'audio/wav', '.ttf': 'font/ttf', '.css': 'text/css', '.xml': 'application/xml', '.svg': 'image/svg+xml' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const fp = path.join(ROOT, p);
  fs.readFile(fp, (e, data) => {
    if (e) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(fp)] || 'application/octet-stream', 'Cache-Control': 'no-store, no-cache, must-revalidate', 'Pragma': 'no-cache', 'Expires': '0' });
    res.end(data);
  });
}).listen(PORT, () => console.log(`serving ${ROOT}\n  → http://localhost:${PORT}  (no-cache)`));
