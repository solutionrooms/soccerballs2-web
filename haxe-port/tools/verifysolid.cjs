const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  console.log('BEFORE:', await p.evaluate(()=>window.sb2DynShapes()));
  await p.evaluate(()=>window.sb2MakeBallSolid());
  console.log('AFTER :', await p.evaluate(()=>window.sb2DynShapes()));
  // now kick gently and watch
  await p.evaluate(()=>window.sb2RealKick(330, 395));
  for (let i=0;i<10;i++){ await new Promise(r=>setTimeout(r,130)); console.log('t'+i, (await p.evaluate(()=>window.sb2BallInfo())).replace(/xvel.*mass=\S+ /,'')); }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
