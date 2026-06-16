const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  const errs=[]; p.on('pageerror',e=>errs.push(String((e&&e.message)||e).split('\n')[0]));
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  console.log('GROUNDINFO:', await p.evaluate(()=>{ try { return window.sb2GroundInfo(); } catch(e){ return 'THREW '+e.message; } }));
  if(errs.length) console.log('errs:', errs.slice(0,2).join(' | '));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
