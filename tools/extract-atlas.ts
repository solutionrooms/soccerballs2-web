// GraphicObjectsLayout.xml -> src/data/atlas.json + copy texture pages.
// Frame format mirrors DisplayObjFrame.as: sourceRect in page pixels,
// xoffset/yoffset = registration offset (sprite-origin relative, 2px pad baked in).
import { readFileSync, writeFileSync, copyFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parseXml, childrenOf, attrInt, attrStr } from './xml.ts';

const SRC = '/Users/jonscott/Projects/SoccerBalls2';
const OUT = join(import.meta.dirname, '..');

const xml = parseXml(readFileSync(join(SRC, 'bin/GraphicObjectsLayout.xml'), 'utf8'));
const graphicobjects = childrenOf(xml, 'graphicobjects')[0];

interface FrameJson {
  page: number;
  x: number;
  y: number;
  w: number;
  h: number;
  ox: number;
  oy: number;
}
interface ObjJson {
  flags: string;
  frames: FrameJson[];
}

const objects: Record<string, ObjJson> = {};
let frameCount = 0;
const pagesUsed = new Set<number>();

for (const obj of childrenOf(graphicobjects, 'object')) {
  const name = attrStr(obj, 'origName');
  const entry: ObjJson = { flags: attrStr(obj, 'flags'), frames: [] };
  for (const f of childrenOf(obj, 'frame')) {
    const page = attrInt(f, 's3dTexPageIndex');
    pagesUsed.add(page);
    entry.frames.push({
      page,
      x: attrInt(f, 'sourceRectX'),
      y: attrInt(f, 'sourceRectY'),
      w: attrInt(f, 'sourceRectW'),
      h: attrInt(f, 'sourceRectH'),
      ox: attrInt(f, 'xoffset'),
      oy: attrInt(f, 'yoffset'),
    });
    frameCount++;
  }
  objects[name] = entry;
}

writeFileSync(join(OUT, 'src/data/atlas.json'), JSON.stringify({ objects }, null, 1));

const pagesDir = join(OUT, 'public/assets/pages');
mkdirSync(pagesDir, { recursive: true });
let copied = 0;
for (const page of [...pagesUsed].sort((a, b) => a - b)) {
  const src = join(SRC, `bin/TexturePageGfx/TexturePage_${page}.png`);
  if (!existsSync(src)) {
    console.error(`MISSING page png: ${src}`);
    continue;
  }
  copyFileSync(src, join(pagesDir, `page-${page}.png`));
  copied++;
}

console.log(
  `atlas: ${Object.keys(objects).length} objects, ${frameCount} frames, ${copied}/${pagesUsed.size} pages copied`,
);
