const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  await p.evaluate(()=>window.sb2MakeBallSolid());
  console.log('made ball solid; kicking...');
  await p.evaluate(()=>window.sb2RealKick(420, 150));
  for (let i=0;i<22;i++){
    await new Promise(r=>setTimeout(r,120));
    console.log('t='+((i+1)*0.12).toFixed(2), await p.evaluate(()=>window.sb2BallInfo()));
  }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
