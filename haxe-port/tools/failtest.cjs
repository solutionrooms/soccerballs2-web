const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  p.on('console', m => { const t=m.text(); if(t.includes('[SB2] InitLevelState')||t.includes('[SB2] StartTransition')) console.log(t.replace(/^[^\[]*/,'')); });
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,800));
  console.log('--- forcing fail ---');
  await p.evaluate(()=>window.sb2ForceFail());
  await new Promise(r=>setTimeout(r,4000)); // watch for repeated InitLevelState calls
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
