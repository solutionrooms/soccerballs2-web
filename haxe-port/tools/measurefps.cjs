const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage(); await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,500));
  const m = await p.evaluate(async () => {
    const c0 = window.sb2LoopCount();
    // also measure raw rAF rate
    let raf=0; const t0=performance.now();
    await new Promise(res=>{ function tick(){ raf++; if(performance.now()-t0<2000) requestAnimationFrame(tick); else res(); } requestAnimationFrame(tick); });
    const dt=(performance.now()-t0)/1000;
    const c1 = window.sb2LoopCount();
    return { gameLoopPerSec: (c1-c0)/dt, rafPerSec: raf/dt, dt };
  });
  console.log('=== TIMING (headless) ===');
  console.log('game MainLoop /sec :', m.gameLoopPerSec.toFixed(1), '(target 60)');
  console.log('raw rAF /sec       :', m.rafPerSec.toFixed(1));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
