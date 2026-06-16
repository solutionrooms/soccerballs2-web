const puppeteer = require('puppeteer-core');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
(async () => {
  const b = await puppeteer.launch({ executablePath: CHROME, headless:'new', args:['--no-sandbox','--disable-gpu'] });
  const p = await b.newPage();
  await p.goto('http://localhost:8753/index.html',{waitUntil:'load',timeout:30000}).catch(()=>{});
  await new Promise(r=>setTimeout(r,13000));
  await p.evaluate(()=>window.sb2LoadLevel(0));
  await new Promise(r=>setTimeout(r,600));
  // very gentle: mouse just above the ball (small drag = low power)
  await p.evaluate(()=>window.sb2RealKick(330, 395));
  for (let i=0;i<26;i++){
    await new Promise(r=>setTimeout(r,120));
    const s = await p.evaluate(()=>window.sb2BallInfo());
    console.log('t='+((i+1)*0.12).toFixed(2), s.replace(/xvel=\S+ yvel=\S+ /,'').replace(/mass=\S+ /,''));
  }
  await b.close();
})().catch(e=>console.log('ERR '+e.message));
