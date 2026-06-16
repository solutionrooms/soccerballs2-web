const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args:['--no-sandbox','--disable-gpu','--force-device-scale-factor=2','--high-dpi-support=1','--window-size=720,560'] });
  const p = await b.newPage();
  await p.setViewport({ width: 720, height: 560, deviceScaleFactor: 2 });
  await p.goto('http://localhost:8753/index.html', { waitUntil:'load', timeout:30000 }).catch(()=>{});
  await new Promise(r=>setTimeout(r,14000));
  const canvas = await p.$('canvas');
  if (canvas) { await canvas.screenshot({ path:'/tmp/sb2menu.png' }); console.log('canvas shot saved'); }
  else { await p.screenshot({ path:'/tmp/sb2menu.png' }); console.log('page shot saved'); }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
