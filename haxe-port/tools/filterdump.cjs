const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  console.log('DYN  :', await p.evaluate(()=>{try{return window.sb2DynShapes();}catch(e){return 'THREW '+e.message;}}));
  console.log('GROUND:', await p.evaluate(()=>{try{return window.sb2GroundShape();}catch(e){return 'THREW '+e.message;}}));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
