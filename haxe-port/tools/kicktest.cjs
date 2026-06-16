const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  console.log('bbox:', await p.evaluate(()=>window.sb2BBox()));
  console.log('PRE :', await p.evaluate(()=>window.sb2BallInfo()));
  await p.evaluate(()=>window.sb2TestKick(120, -60)); // up-and-right
  for (let i=0;i<14;i++){
    await new Promise(r=>setTimeout(r,150));
    console.log('t='+((i+1)*0.15).toFixed(2)+'s', await p.evaluate(()=>window.sb2BallInfo()));
  }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
