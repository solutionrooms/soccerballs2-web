const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage(); await p.setViewport({ width:760, height:600, deviceScaleFactor:2 });
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,14000));
  await p.evaluate(()=>window.sb2LoadLevel(0)).catch(()=>{});
  await new Promise(r=>setTimeout(r,1500));
  // focus canvas then press backtick
  const c = await p.$('canvas'); if(c){ const box=await c.boundingBox(); await p.mouse.click(box.x+box.width/2, box.y+box.height/2); }
  await p.keyboard.press('Backquote');
  await new Promise(r=>setTimeout(r,1500));
  await p.screenshot({path:'/tmp/sb2_perf.png'});
  console.log('perf screenshot saved');
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
