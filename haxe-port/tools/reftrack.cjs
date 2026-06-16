const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  for (let i=0;i<6;i++){
    await new Promise(r=>setTimeout(r,500));
    console.log('t='+((i+1)*0.5).toFixed(1)+'s', await p.evaluate(()=>window.sb2DynShapes()));
  }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
