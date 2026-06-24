// Headless DPR-2 screenshot of the HD build (served on :8753 = the bin output).
// Usage: node scripts/hd-shot.cjs <levelIndex> <outfile> [deviceScaleFactor]
const puppeteer = require('puppeteer-core');

const LEVEL = parseInt(process.argv[2] || '8', 10);
const OUT   = process.argv[3] || 'hd-shot.png';
const DPR   = parseFloat(process.argv[4] || '2');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--ignore-gpu-blocklist',
           '--enable-webgl', '--no-sandbox', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 700, height: 525, deviceScaleFactor: DPR });
  const logs = [];
  page.on('console', m => logs.push('[console] ' + m.text()));
  page.on('pageerror', e => logs.push('[pageerror] ' + e.message));
  await page.goto('http://localhost:8753/', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 4500)); // boot the game

  const loaded = await page.evaluate((lvl) => {
    if (typeof window.sb2LoadLevel === 'function') { window.sb2LoadLevel(lvl); return true; }
    return false;
  }, LEVEL);
  await new Promise(r => setTimeout(r, 3500)); // let the level render a few frames

  // report the actual canvas backing size so we can confirm HiDPI took effect
  const canvasInfo = await page.evaluate(() => {
    const c = document.querySelector('canvas');
    return c ? { cssW: c.clientWidth, cssH: c.clientHeight, backW: c.width, backH: c.height } : null;
  });

  await page.screenshot({ path: OUT });
  await browser.close();
  console.log('loaded level hook?', loaded);
  console.log('canvas:', JSON.stringify(canvasInfo));
  console.log(logs.slice(-12).join('\n'));
})().catch(e => { console.error(e); process.exit(1); });
