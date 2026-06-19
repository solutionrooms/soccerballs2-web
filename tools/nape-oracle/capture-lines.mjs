// Generic golden capture: run a [TAG]-emitting harness SWF (original Nape AS3)
// under Ruffle headless and write every traced line to a JSON fixture. Each
// milestone test parses the tags it cares about. Stops on a line containing the
// done marker (default "DONE").
//
//   node tools/nape-oracle/capture-lines.mjs <harness.swf> <out.json> [doneMarker]
import http from 'node:http';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import puppeteer from 'puppeteer-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const SWF = process.argv[2];
const OUT = process.argv[3];
const DONE = process.argv[4] || 'DONE';
if (!SWF || !OUT) {
  console.error('usage: node capture-lines.mjs <harness.swf> <out.json> [doneMarker]');
  process.exit(1);
}

const swfData = readFileSync(SWF);
const PAGE = `<!doctype html><meta charset="utf-8"><div id="player"></div>
<script src="https://unpkg.com/@ruffle-rs/ruffle"></script>
<script>
  window.RufflePlayer = window.RufflePlayer || {};
  window.addEventListener("DOMContentLoaded", function () {
    var p = window.RufflePlayer.newest().createPlayer();
    document.getElementById("player").appendChild(p);
    p.style.width = "700px"; p.style.height = "525px";
    p.load({ url: "/target.swf", autoplay: "on", letterbox: "on", logLevel: "info" });
  });
</script>`;

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/target.swf')) {
    res.setHeader('content-type', 'application/x-shockwave-flash');
    res.end(swfData);
  } else {
    res.setHeader('content-type', 'text/html; charset=utf-8');
    res.end(PAGE);
  }
});
await new Promise((r) => server.listen(0, r));
const port = server.address().port;

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
const page = await browser.newPage();
const lines = [];
let done = false;
page.on('console', (m) => {
  // Ruffle routes trace() as: "%cINFO%c <loc:log_adapter.rs:N>%c <TRACE> color: …"
  const parts = m.text().split('%c');
  if (parts.length < 4 || !parts[2].includes('log_adapter.rs')) return;
  let payload = parts[3];
  const ci = payload.indexOf(' color:');
  if (ci >= 0) payload = payload.slice(0, ci);
  payload = payload.trim();
  if (!payload.startsWith('[')) return;
  lines.push(payload);
  if (payload.includes(DONE)) done = true;
});

await page.goto(`http://localhost:${port}/`, { waitUntil: 'domcontentloaded', timeout: 30000 });
for (let waited = 0; waited < 30000 && !done; waited += 200) {
  await new Promise((r) => setTimeout(r, 200));
}
await browser.close();
server.close();

if (!done) {
  console.error(`capture incomplete: ${lines.length} lines, no "${DONE}" seen`);
  process.exit(1);
}
mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, JSON.stringify({ source: 'original Nape AS3 via Ruffle', lines }, null, 0));
console.log(`wrote ${OUT}: ${lines.length} lines`);
