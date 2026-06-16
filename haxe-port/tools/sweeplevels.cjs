const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage();
  await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  let frameErrs = [];
  p.on('pageerror', e => frameErrs.push(String((e&&e.message)||e).split('\n')[0]));
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000)); // boot to menu
  const results = [];
  for (let i=0; i<36; i++) {
    frameErrs = [];
    const r = await p.evaluate((idx) => {
      try { window.sb2LoadLevel(idx); return 'LOAD_OK'; }
      catch(e){ return 'LOAD_THREW: ' + String((e&&e.message)||e).split('\n')[0]; }
    }, i);
    await new Promise(r=>setTimeout(r,900)); // let a few frames run
    const fe = [...new Set(frameErrs)];
    results.push({ lvl: i+1, load: r, frame: fe.length ? fe[0] : '' });
  }
  console.log('=== 36-LEVEL LOAD SWEEP ===');
  for (const x of results) {
    const ok = x.load==='LOAD_OK' && !x.frame;
    console.log((ok?'  OK  ':' FAIL ') + 'L'+String(x.lvl).padStart(2) + '  ' + (x.load==='LOAD_OK'?'':x.load) + (x.frame?(' | frame: '+x.frame):''));
  }
  const fails = results.filter(x=>x.load!=='LOAD_OK'||x.frame);
  console.log('\n'+ (results.length-fails.length) + '/36 load clean, ' + fails.length + ' with errors');
  await b.close();
})().catch(e=>console.log('HARNESS ERR '+e.message));
