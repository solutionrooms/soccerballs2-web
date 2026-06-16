const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage(); await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  const c = await p.$('canvas');
  for (let i=0;i<3;i++){ await c.screenshot({path:'/tmp/sb2_frame'+i+'.png'}); await new Promise(r=>setTimeout(r,250)); }
  console.log('3 frames captured');
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
