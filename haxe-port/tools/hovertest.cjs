const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu','--window-size=760,600'] });
  const p = await b.newPage();
  await p.setViewport({ width:760, height:600, deviceScaleFactor:1 });
  const errs=[]; p.on('pageerror',e=>errs.push('[PAGEERROR] '+String((e&&(e.stack||e.message))||e).split('\n').slice(0,4).join(' | ')));
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  const box = await (await p.$('canvas')).boundingBox();
  // play game button: game-coords ~ (612, 274) of 700x525 -> fraction
  const gx=612/700, gy=274/525;
  const x = box.x + box.width*gx, y = box.y + box.height*gy;
  console.log('hover/click @ '+Math.round(x)+','+Math.round(y)+' (canvas '+box.width+'x'+box.height+')');
  await p.mouse.move(x,y); await new Promise(r=>setTimeout(r,1500));
  await p.screenshot({path:'/tmp/sb2_hover.png'});      // should show hover state if events work
  await p.mouse.down(); await new Promise(r=>setTimeout(r,150)); await p.mouse.up();
  await new Promise(r=>setTimeout(r,3000));
  await p.screenshot({path:'/tmp/sb2_click2.png'});
  console.log('errs:'+errs.length+' '+errs.slice(0,3).join(' || '));
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
