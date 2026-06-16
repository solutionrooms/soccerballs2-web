const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage(); await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  const errs=[]; p.on('pageerror',e=>errs.push(String((e&&e.message)||e).split('\n')[0]));
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  console.log('ball starts at y=414, floor ~440-450. Sampling ball Y (Nape y+ = down):');
  for (let i=0;i<12;i++){
    await new Promise(r=>setTimeout(r,400));
    const y = await p.evaluate(()=>window.sb2BallY());
    console.log('  t='+((i+1)*0.4).toFixed(1)+'s  ballY='+(typeof y==='number'?y.toFixed(1):y));
  }
  if(errs.length) console.log('errors:', [...new Set(errs)].slice(0,3).join(' | '));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
