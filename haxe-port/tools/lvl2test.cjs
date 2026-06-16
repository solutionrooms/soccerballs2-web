const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage(); await p.setViewport({ width:760, height:600, deviceScaleFactor:2 });
  await p.goto('http://localhost:8753/index.html?fps',{waitUntil:'load',timeout:30000}).catch(()=>{}); // overlay forced on
  await new Promise(r=>setTimeout(r,14000));
  await p.evaluate(()=>window.sb2LoadLevel(1)); // level 2 (0-indexed)
  await new Promise(r=>setTimeout(r,2500));
  await p.screenshot({path:'/tmp/sb2_lvl2.png'});
  console.log('lvl2 ball:', await p.evaluate(()=>window.sb2BallInfo()));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
