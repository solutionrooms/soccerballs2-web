const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage();
  await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  const errs = [];
  p.on('pageerror', e => errs.push('[PAGEERROR] ' + String((e&&(e.stack||e.message))||e).split('\n').slice(0,5).join(' | ')));
  p.on('console', m => { const t=m.text(); if(/error|#20|null|undefined|exception|can't find/i.test(t) && !/willReadFrequently/.test(t)) errs.push('['+m.type()+'] '+t); });
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000)); // boot to menu
  const box = await (await p.$('canvas')).boundingBox();
  console.log('canvas box', JSON.stringify(box));
  const clickFrac = async (fx,fy,label) => {
    const x = box.x + box.width*fx, y = box.y + box.height*fy;
    console.log('CLICK '+label+' @ '+Math.round(x)+','+Math.round(y));
    await p.mouse.move(x,y); await new Promise(r=>setTimeout(r,200));
    await p.mouse.click(x,y); await new Promise(r=>setTimeout(r,2500));
  };
  await clickFrac(0.86,0.52,'play game');
  await p.screenshot({ path:'/tmp/sb2_after_play.png' });
  console.log('=== ERRORS AFTER CLICK ('+errs.length+') ===');
  console.log([...new Set(errs)].slice(0,25).join('\n') || '(none)');
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
