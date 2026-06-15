const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage();
  await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  const errs=[];
  p.on('pageerror',e=>errs.push('[PAGEERROR] '+String((e&&(e.stack||e.message))||e).split('\n').slice(0,8).join('\n   ')));
  p.on('console',m=>{const t=m.text(); if(/error|#\d|null|undefined|exception|cannot|can't find/i.test(t)&&!/willReadFrequently/.test(t)) errs.push('['+m.type()+'] '+t);});
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000)); // boot to menu
  console.log('=== triggering level 1 (gamescreen transition) ===');
  const res = await p.evaluate(() => {
    try {
      if (typeof window.sb2LoadLevel !== 'function') return 'NO HOOK (sb2LoadLevel='+(typeof window.sb2LoadLevel)+')';
      window.sb2LoadLevel(0);
      return 'called sb2LoadLevel(0)';
    } catch(e) { return 'EVAL THREW: '+(e&&(e.stack||e.message)||e); }
  });
  console.log('evaluate result:', res);
  await new Promise(r=>setTimeout(r,4000));
  await p.screenshot({path:'/tmp/sb2_level1.png'});
  console.log('=== ERRORS ('+errs.length+') ===');
  console.log([...new Set(errs)].slice(0,12).join('\n---\n') || '(none)');
  await b.close();
})().catch(e=>console.log('HARNESS ERR '+e.message));
