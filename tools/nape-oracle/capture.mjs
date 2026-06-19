// Capture trace() output from a SWF running the ORIGINAL AS3 under Ruffle,
// headless, via Puppeteer. This is the oracle pipeline: the original engine
// actually executes; its trace() lines reach the browser console; we collect
// them into a fixture.
//
//   node tools/nape-oracle/capture.mjs <file.swf> [seconds] [matchSubstring]
//
// Self-contained: serves the SWF + a minimal Ruffle host page on an ephemeral
// port (Ruffle pulled from the unpkg CDN), drives it with the installed Chrome.
import http from 'node:http';
import { readFileSync } from 'node:fs';
import puppeteer from 'puppeteer-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const SWF = process.argv[2];
const SECONDS = Number(process.argv[3] || 15);
const MATCH = process.argv[4] || '';
if (!SWF) {
  console.error('usage: node capture.mjs <file.swf> [seconds] [matchSubstring]');
  process.exit(1);
}

const swfData = readFileSync(SWF);
const PAGE = `<!doctype html><meta charset="utf-8"><div id="player"></div>
<script src="https://unpkg.com/@ruffle-rs/ruffle"></script>
<script>
  window.RufflePlayer = window.RufflePlayer || {};
  window.addEventListener("DOMContentLoaded", function () {
    var r = window.RufflePlayer.newest();
    var p = r.createPlayer();
    document.getElementById("player").appendChild(p);
    p.style.width = "700px"; p.style.height = "525px";
    p.load({ url: "/target.swf", autoplay: "on", letterbox: "on", logLevel: "info" })
      .then(function () { console.log("[capture] ruffle loaded swf"); })
      .catch(function (e) { console.log("[capture] load error: " + e); });
  });
</script>`;

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/target.swf')) {
    res.setHeader('content-type', 'application/x-shockwave-flash');
    res.end(swfData);
    return;
  }
  res.setHeader('content-type', 'text/html; charset=utf-8');
  res.end(PAGE);
});
await new Promise((r) => server.listen(0, r));
const port = server.address().port;

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: true,
  args: ['--no-sandbox', '--disable-gpu'],
});
const page = await browser.newPage();
const lines = [];
page.on('console', (m) => lines.push(m.text()));
page.on('pageerror', (e) => lines.push('[pageerror] ' + e.message));

await page.goto(`http://localhost:${port}/`, { waitUntil: 'domcontentloaded', timeout: 30000 });
await new Promise((r) => setTimeout(r, SECONDS * 1000));
await browser.close();
server.close();

const shown = MATCH ? lines.filter((l) => l.includes(MATCH)) : lines;
console.log(`CAPTURED ${lines.length} console lines${MATCH ? ` (${shown.length} match "${MATCH}")` : ''}`);
for (const l of shown.slice(0, 120)) console.log('>>', l);
