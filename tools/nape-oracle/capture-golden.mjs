// Capture a golden fixture from a [ORACLE]-emitting harness SWF (the original
// Nape AS3 running under Ruffle) and write it as JSON for the replica tests.
//
//   node tools/nape-oracle/capture-golden.mjs <harness.swf> <out.json>
//
// Each "[ORACLE] <i> <hi:lo> x6" line carries the raw IEEE-754 bits of a body's
// (x, y, vx, vy, rot, angvel); we store them as 16-hex-char strings so the
// fixture is exact. "[ORACLE] mass <hi:lo>" and "[ORACLE] DONE" frame the run.
import http from 'node:http';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import puppeteer from 'puppeteer-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const SWF = process.argv[2];
const OUT = process.argv[3];
if (!SWF || !OUT) {
  console.error('usage: node capture-golden.mjs <harness.swf> <out.json>');
  process.exit(1);
}

// "3fdcf3f2:6d5cdffb" -> "3fdcf3f26d5cdffb" (each half zero-padded to 8 hex)
function combine(pair) {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
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
const oracleLines = [];
let done = false;
page.on('console', (m) => {
  const t = m.text();
  const idx = t.indexOf('[ORACLE]');
  if (idx < 0) return;
  const payload = t.slice(idx + '[ORACLE]'.length).trim().replace(/\s+color:.*$/, '');
  oracleLines.push(payload);
  if (payload.startsWith('DONE')) done = true;
});

await page.goto(`http://localhost:${port}/`, { waitUntil: 'domcontentloaded', timeout: 30000 });
for (let waited = 0; waited < 30000 && !done; waited += 200) {
  await new Promise((r) => setTimeout(r, 200));
}
await browser.close();
server.close();

// parse
let mass = null;
const steps = [];
for (const line of oracleLines) {
  const f = line.split(/\s+/);
  if (f[0] === 'mass') {
    mass = combine(f[1]);
  } else if (f[0] === 'DONE') {
    // end
  } else if (/^\d+$/.test(f[0])) {
    const i = Number(f[0]);
    const vals = f.slice(1, 7).map(combine);
    steps[i - 1] = vals; // [x,y,vx,vy,rot,angvel]
  }
}

if (mass == null || steps.length === 0 || !done) {
  console.error(`capture incomplete: mass=${mass} steps=${steps.length} done=${done}`);
  process.exit(1);
}

const golden = {
  source: 'original Nape AS3 (release_nape.swc in SoccerBalls2.swf) via Ruffle',
  fields: ['x', 'y', 'vx', 'vy', 'rot', 'angvel'],
  note: 'values are 16-hex-char IEEE-754 bit patterns (big-endian)',
  mass,
  steps,
};
mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, JSON.stringify(golden, null, 0));
console.log(`wrote ${OUT}: mass=${mass}, ${steps.length} steps`);
