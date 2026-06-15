// Headless runtime smoke test: load the built game in the installed Chrome,
// capture console / page errors / failed requests, and screenshot what rendered.
const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const URL = process.argv[2] || 'http://localhost:8753/index.html';

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME, headless: 'new',
    args: ['--no-sandbox', '--disable-gpu', '--window-size=720,560'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 720, height: 560 });
  const logs = [];
  page.on('console', m => logs.push('[' + m.type() + '] ' + m.text()));
  page.on('pageerror', e => logs.push('[PAGEERROR] ' + String((e && (e.stack || e.message)) || e).split('\n').slice(0, 4).join(' | ')));
  page.on('error', e => logs.push('[CRASH] ' + String((e && e.message) || e)));
  page.on('requestfailed', r => logs.push('[REQFAIL] ' + r.url().split('/').pop() + ' :: ' + r.failure().errorText));
  try {
    await page.goto(URL, { waitUntil: 'load', timeout: 30000 });
  } catch (e) { logs.push('[GOTO] ' + e.message); }
  await new Promise(r => setTimeout(r, 6000)); // let it boot a few frames
  try { await page.screenshot({ path: '/tmp/sb2render.png' }); } catch (e) {}
  console.log('=== RUNTIME LOG (' + logs.length + ' lines) ===');
  console.log(logs.join('\n') || '(no console output)');
  await browser.close();
})().catch(e => { console.log('HARNESS ERROR: ' + e.message); process.exit(1); });
