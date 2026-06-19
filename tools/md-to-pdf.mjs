// Render Markdown files to PDF via headless Chrome (marked + page.pdf).
//   node tools/md-to-pdf.mjs <dir-or-file> [<dir-or-file> ...]
// For a directory, every *.md inside is rendered to a sibling *.pdf.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import puppeteer from 'puppeteer-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('usage: node tools/md-to-pdf.mjs <dir-or-file> ...');
  process.exit(1);
}

const mdFiles = [];
for (const a of args) {
  if (statSync(a).isDirectory()) {
    for (const f of readdirSync(a)) if (f.endsWith('.md')) mdFiles.push(join(a, f));
  } else if (a.endsWith('.md')) {
    mdFiles.push(a);
  }
}
mdFiles.sort();

const CSS = `
body{font-family:-apple-system,"Segoe UI",Helvetica,Arial,sans-serif;line-height:1.55;color:#1f2328;max-width:820px;margin:0 auto;padding:8px 6px;font-size:13.5px}
h1,h2,h3,h4{font-weight:600;line-height:1.25;margin:1.2em 0 .5em}
h1{font-size:1.7em;border-bottom:1px solid #d0d7de;padding-bottom:.25em}
h2{font-size:1.35em;border-bottom:1px solid #eaecef;padding-bottom:.2em}
h3{font-size:1.1em} h4{font-size:1em}
code{background:#f0f1f3;padding:.12em .35em;border-radius:4px;font-size:.86em;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
pre{background:#f6f8fa;padding:12px;border-radius:6px;overflow:auto;font-size:.8em;line-height:1.45}
pre code{background:none;padding:0}
table{border-collapse:collapse;margin:1em 0;font-size:.88em;width:100%}
th,td{border:1px solid #d0d7de;padding:5px 10px;text-align:left;vertical-align:top}
th{background:#f6f8fa}
blockquote{border-left:3px solid #d0d7de;color:#57606a;margin:1em 0;padding:.1em 1em}
a{color:#0969da;text-decoration:none}
hr{border:none;border-top:1px solid #eaecef;margin:1.5em 0}
ul,ol{padding-left:1.4em}
`;

// Fetch the markdown renderer once and inject its source (loading by URL on
// about:blank is blocked, so we inject the script content instead).
const markedSrc = await (await fetch('https://cdn.jsdelivr.net/npm/marked/marked.min.js')).text();

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--no-sandbox', '--disable-gpu'] });
for (const file of mdFiles) {
  const md = readFileSync(file, 'utf8');
  const page = await browser.newPage();
  await page.goto('about:blank');
  await page.addScriptTag({ content: markedSrc });
  await page.evaluate(
    (mdText, css) => {
      const style = document.createElement('style');
      style.textContent = css;
      document.head.appendChild(style);
      const render = (window.marked && (window.marked.parse || window.marked)) || ((x) => x);
      document.body.innerHTML = `<div id="content"></div>`;
      document.getElementById('content').innerHTML = render(mdText);
    },
    md,
    CSS,
  );
  const out = join(dirname(file), basename(file).replace(/\.md$/, '.pdf'));
  await page.pdf({
    path: out,
    format: 'A4',
    printBackground: true,
    margin: { top: '14mm', bottom: '14mm', left: '14mm', right: '14mm' },
  });
  await page.close();
  console.log('wrote', out);
}
await browser.close();
console.log(`done: ${mdFiles.length} PDFs`);
