// UI screen extraction: walk each screen sprite's display list in the
// ffdec swf2xml dump and emit src/data/ui-layout.json (child id/name/
// transform/kind per frame) plus the list of character ids whose art must be
// exported as PNG (printed for the ffdec -selectid step).
// Run extract-swf prerequisites first (uses the same /tmp/sb2-swf.xml dump).
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const XML_PATH = process.argv[2] ?? '/tmp/sb2-swf.xml';
const OUT = join(import.meta.dirname, '..');

const UI_SCREENS = [
  'screen_mainMenu',
  'screen_levelSelect',
  'screen_matchSelect',
  'screen_pickATeam_alt',
  'screen_modifyTeam',
  'screen_levelComplete',
  'screen_paused',
  'screen_credits',
  'screen_clearSave',
  'screen_language',
  'ui_hud',
  'screen_preparing',
  // components instantiated by code (UI_LevelSelect.as InitPage etc.)
  'levelIcon',
];

function attr(line: string, name: string): string | undefined {
  const m = line.match(new RegExp(` ${name}="([^"]*)"`));
  return m?.[1];
}

const ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
};
function decode(s: string): string {
  return s.replace(/&(amp|lt|gt|quot|apos);/g, (m) => ENTITIES[m]);
}

const lines = readFileSync(XML_PATH, 'utf8').split('\n');

// ---- pass 1: character kinds + text defs ----
type Kind = 'sprite' | 'button' | 'text' | 'statictext' | 'shape' | 'image' | 'font' | 'other';
const kindById = new Map<number, Kind>();
interface TextDef {
  html: string;
  fontHeightTwips: number;
  align: number;
  x: number;
  y: number;
  w: number;
  h: number;
}
const textById = new Map<number, TextDef>();
let pendingTextId = -1;
const staticTextBounds = new Map<number, { x0: number; y0: number; x1: number; y1: number }>();
let pendingStaticTextId = -1;

for (const raw of lines) {
  const t = raw.trim();
  if (t.startsWith('<item type="DefineSpriteTag"')) {
    kindById.set(Number(attr(t, 'spriteId')), 'sprite');
  } else if (t.startsWith('<item type="DefineButton2Tag"') || t.startsWith('<item type="DefineButtonTag"')) {
    kindById.set(Number(attr(t, 'buttonId')), 'button');
  } else if (t.startsWith('<item type="DefineEditTextTag"')) {
    const id = Number(attr(t, 'characterID'));
    kindById.set(id, 'text');
    textById.set(id, {
      html: decode(attr(t, 'initialText') ?? ''),
      fontHeightTwips: Number(attr(t, 'fontHeight') ?? 240),
      align: Number(attr(t, 'align') ?? 0),
      x: 0,
      y: 0,
      w: 0,
      h: 0,
    });
    pendingTextId = id;
  } else if (pendingTextId >= 0 && t.startsWith('<bounds type="RECT"')) {
    const td = textById.get(pendingTextId)!;
    td.x = Number(attr(t, 'Xmin')) / 20;
    td.y = Number(attr(t, 'Ymin')) / 20;
    td.w = (Number(attr(t, 'Xmax')) - Number(attr(t, 'Xmin'))) / 20;
    td.h = (Number(attr(t, 'Ymax')) - Number(attr(t, 'Ymin'))) / 20;
    pendingTextId = -1;
  } else if (t.startsWith('<item type="DefineTextTag"') || t.startsWith('<item type="DefineText2Tag"')) {
    kindById.set(Number(attr(t, 'characterID')), 'statictext');
    pendingStaticTextId = Number(attr(t, 'characterID'));
  } else if (pendingStaticTextId >= 0 && t.startsWith('<textBounds type="RECT"')) {
    staticTextBounds.set(pendingStaticTextId, {
      x0: Number(attr(t, 'Xmin')) / 20,
      y0: Number(attr(t, 'Ymin')) / 20,
      x1: Number(attr(t, 'Xmax')) / 20,
      y1: Number(attr(t, 'Ymax')) / 20,
    });
    pendingStaticTextId = -1;
  } else if (t.startsWith('<item type="DefineShape')) {
    kindById.set(Number(attr(t, 'shapeId')), 'shape');
  } else if (t.startsWith('<item type="DefineBitsLossless') || t.startsWith('<item type="DefineBitsJPEG')) {
    kindById.set(Number(attr(t, 'characterID')), 'image');
  }
}

// ---- pass 1b: shape bounds + button records (for art registration) ----
interface Rect {
  x0: number;
  y0: number;
  x1: number;
  y1: number;
}
const shapeBounds = new Map<number, Rect>();
const buttonRecords = new Map<number, { charId: number; a: number; b: number; c: number; d: number; tx: number; ty: number }[]>();
{
  let pendingShapeId = -1;
  let curButtonId = -1;
  let pendingButtonRecord: { charId: number } | null = null;
  for (const raw of lines) {
    const t = raw.trim();
    if (t.startsWith('<item type="DefineShape')) {
      pendingShapeId = Number(attr(t, 'shapeId'));
    } else if (pendingShapeId >= 0 && t.startsWith('<shapeBounds type="RECT"')) {
      shapeBounds.set(pendingShapeId, {
        x0: Number(attr(t, 'Xmin')) / 20,
        y0: Number(attr(t, 'Ymin')) / 20,
        x1: Number(attr(t, 'Xmax')) / 20,
        y1: Number(attr(t, 'Ymax')) / 20,
      });
      pendingShapeId = -1;
    } else if (t.startsWith('<item type="DefineButton2Tag"') || t.startsWith('<item type="DefineButtonTag"')) {
      curButtonId = Number(attr(t, 'buttonId'));
      buttonRecords.set(curButtonId, []);
    } else if (curButtonId >= 0 && t.startsWith('<item type="BUTTONRECORD"')) {
      // only the UP state contributes to the exported PNG bounds
      if (attr(t, 'buttonStateUp') === 'true') {
        pendingButtonRecord = { charId: Number(attr(t, 'characterId')) };
      } else {
        pendingButtonRecord = null;
      }
    } else if (pendingButtonRecord && curButtonId >= 0 && t.startsWith('<placeMatrix type="MATRIX"')) {
      const hasScale = attr(t, 'hasScale') === 'true';
      const hasRotate = attr(t, 'hasRotate') === 'true';
      buttonRecords.get(curButtonId)!.push({
        charId: pendingButtonRecord.charId,
        a: hasScale ? Number(attr(t, 'scaleX')) : 1,
        d: hasScale ? Number(attr(t, 'scaleY')) : 1,
        b: hasRotate ? Number(attr(t, 'rotateSkew0')) : 0,
        c: hasRotate ? Number(attr(t, 'rotateSkew1')) : 0,
        tx: Number(attr(t, 'translateX')) / 20,
        ty: Number(attr(t, 'translateY')) / 20,
      });
      pendingButtonRecord = null;
    } else if (t.startsWith('<item type="DefineSpriteTag"') || t.startsWith('<item type="DefineEditTextTag"')) {
      curButtonId = -1;
    }
  }
}

// ---- pass 2: sprite display lists (same scan as extract-swf) ----
interface Placement {
  depth: number;
  charId: number;
  name: string;
  a: number;
  b: number;
  c: number;
  d: number;
  tx: number;
  ty: number;
}
interface SpriteFrames {
  frames: { label: string | null; placements: Placement[] }[];
}
const sprites = new Map<number, SpriteFrames>();
{
  let cur: SpriteFrames | null = null;
  let curId = -1;
  let depthState = new Map<number, Placement>();
  let pendingLabel: string | null = null;
  let pendingPlace: Placement | null = null;
  let elemDepth = 0;
  let spriteEndDepth = 0;

  for (const raw of lines) {
    const t = raw.trim();
    if (t.startsWith('<item type="DefineSpriteTag"')) {
      curId = Number(attr(t, 'spriteId'));
      cur = { frames: [] };
      depthState = new Map();
      pendingLabel = null;
      spriteEndDepth = elemDepth;
    }
    if (t.startsWith('<') && !t.startsWith('</') && !t.endsWith('/>') && !t.startsWith('<?')) {
      elemDepth++;
    } else if (t.startsWith('</')) {
      elemDepth--;
      if (cur && elemDepth === spriteEndDepth && t === '</item>') {
        sprites.set(curId, cur);
        cur = null;
      }
    }
    if (!cur) continue;

    if (t.startsWith('<item type="PlaceObject2Tag"') || t.startsWith('<item type="PlaceObject3Tag"')) {
      const depth = Number(attr(t, 'depth'));
      const move = attr(t, 'placeFlagMove') === 'true';
      const hasChar = attr(t, 'placeFlagHasCharacter') === 'true';
      const prev = depthState.get(depth);
      const place: Placement = {
        depth,
        charId: hasChar ? Number(attr(t, 'characterId')) : (prev?.charId ?? -1),
        name: attr(t, 'name') ?? (move ? (prev?.name ?? '') : ''),
        a: move && prev ? prev.a : 1,
        b: move && prev ? prev.b : 0,
        c: move && prev ? prev.c : 0,
        d: move && prev ? prev.d : 1,
        tx: move && prev ? prev.tx : 0,
        ty: move && prev ? prev.ty : 0,
      };
      depthState.set(depth, place);
      if (attr(t, 'placeFlagHasMatrix') === 'true' && !t.endsWith('/>')) {
        pendingPlace = place;
      }
    } else if (pendingPlace && t.startsWith('<matrix type="MATRIX"')) {
      const hasScale = attr(t, 'hasScale') === 'true';
      const hasRotate = attr(t, 'hasRotate') === 'true';
      pendingPlace.a = hasScale ? Number(attr(t, 'scaleX')) : 1;
      pendingPlace.d = hasScale ? Number(attr(t, 'scaleY')) : 1;
      pendingPlace.b = hasRotate ? Number(attr(t, 'rotateSkew0')) : 0;
      pendingPlace.c = hasRotate ? Number(attr(t, 'rotateSkew1')) : 0;
      pendingPlace.tx = Number(attr(t, 'translateX')) / 20;
      pendingPlace.ty = Number(attr(t, 'translateY')) / 20;
      pendingPlace = null;
    } else if (t.startsWith('<item type="RemoveObject2Tag"') || t.startsWith('<item type="RemoveObjectTag"')) {
      depthState.delete(Number(attr(t, 'depth')));
    } else if (t.startsWith('<item type="FrameLabelTag"')) {
      pendingLabel = attr(t, 'name') ?? null;
    } else if (t.startsWith('<item type="ShowFrameTag"')) {
      cur.frames.push({
        label: pendingLabel,
        placements: [...depthState.values()].sort((x, y) => x.depth - y.depth).map((p) => ({ ...p })),
      });
      pendingLabel = null;
    }
  }
}

// ---- pass 3: SymbolClass ----
const idByClass = new Map<string, number>();
{
  let inSymbol = false;
  let inTags = false;
  let inNames = false;
  const ids: number[] = [];
  const names: string[] = [];
  for (const raw of lines) {
    const t = raw.trim();
    if (t.startsWith('<item type="SymbolClassTag"')) inSymbol = true;
    if (!inSymbol) continue;
    if (t === '<tags>') inTags = true;
    else if (t === '</tags>') inTags = false;
    else if (t === '<names>') inNames = true;
    else if (t === '</names>') {
      inNames = false;
      inSymbol = false;
      for (let i = 0; i < ids.length; i++) idByClass.set(names[i], ids[i]);
      ids.length = 0;
      names.length = 0;
    } else if (t.startsWith('<item>')) {
      const v = t.replace('<item>', '').replace('</item>', '');
      if (inTags) ids.push(Number(v));
      else if (inNames) names.push(v);
    }
  }
}

// ---- emit layouts + collect art ids ----
interface UiChild {
  charId: number;
  kind: Kind;
  name: string;
  x: number;
  y: number;
  scaleX: number;
  scaleY: number;
  rotDeg: number;
  text?: TextDef;
}
interface UiScreen {
  frames: { label: string | null; children: UiChild[] }[];
}

const artIds = new Set<number>();
const screens: Record<string, UiScreen> = {};

for (const cls of UI_SCREENS) {
  const id = idByClass.get(cls);
  const sprite = id !== undefined ? sprites.get(id) : undefined;
  if (!sprite) {
    console.error(`screen "${cls}" not found`);
    continue;
  }
  screens[cls] = {
    frames: sprite.frames.map((f) => ({
      label: f.label,
      children: f.placements.map((p) => {
        const kind = kindById.get(p.charId) ?? 'other';
        if (kind === 'sprite' || kind === 'button' || kind === 'shape' || kind === 'image') {
          artIds.add(p.charId);
        }
        const child: UiChild = {
          charId: p.charId,
          kind,
          name: p.name,
          x: Math.round(p.tx * 100) / 100,
          y: Math.round(p.ty * 100) / 100,
          scaleX: Math.round(Math.hypot(p.a, p.b) * 1000) / 1000,
          scaleY: Math.round(Math.hypot(p.c, p.d) * 1000) / 1000,
          rotDeg: Math.round(((Math.atan2(p.b, p.a) * 180) / Math.PI) * 100) / 100,
        };
        if (kind === 'text') child.text = textById.get(p.charId);
        return child;
      }),
    })),
  };
  console.log(
    `${cls}: ${sprite.frames.length} frames, ${sprite.frames[0].placements.length} children on frame 1`,
  );
}

// ---- recursive bounds: where the exported PNG's top-left sits relative to
// the character origin (placement matrices position the ORIGIN) ----
function xformRect(r: Rect, m: { a: number; b: number; c: number; d: number; tx: number; ty: number }): Rect {
  const pts = [
    [r.x0, r.y0],
    [r.x1, r.y0],
    [r.x0, r.y1],
    [r.x1, r.y1],
  ].map(([x, y]) => [m.a * x + m.c * y + m.tx, m.b * x + m.d * y + m.ty]);
  return {
    x0: Math.min(...pts.map((p) => p[0])),
    y0: Math.min(...pts.map((p) => p[1])),
    x1: Math.max(...pts.map((p) => p[0])),
    y1: Math.max(...pts.map((p) => p[1])),
  };
}

function unionRect(a: Rect | null, b: Rect): Rect {
  if (!a) return b;
  return { x0: Math.min(a.x0, b.x0), y0: Math.min(a.y0, b.y0), x1: Math.max(a.x1, b.x1), y1: Math.max(a.y1, b.y1) };
}

function boundsOf(charId: number, visited = new Set<number>()): Rect | null {
  if (visited.has(charId)) return null;
  visited.add(charId);
  const kind = kindById.get(charId);
  if (kind === 'shape') return shapeBounds.get(charId) ?? null;
  if (kind === 'statictext') return staticTextBounds.get(charId) ?? null;
  if (kind === 'text') {
    const td = textById.get(charId);
    return td ? { x0: td.x, y0: td.y, x1: td.x + td.w, y1: td.y + td.h } : null;
  }
  if (kind === 'button') {
    let r: Rect | null = null;
    for (const rec of buttonRecords.get(charId) ?? []) {
      const cb = boundsOf(rec.charId, visited);
      if (cb) r = unionRect(r, xformRect(cb, rec));
    }
    return r;
  }
  if (kind === 'sprite') {
    const sprite = sprites.get(charId);
    if (!sprite || !sprite.frames.length) return null;
    let r: Rect | null = null;
    for (const p of sprite.frames[0].placements) {
      const cb = boundsOf(p.charId, visited);
      if (cb) r = unionRect(r, xformRect(cb, p));
    }
    return r;
  }
  return null;
}

const art: Record<string, { ox: number; oy: number; w: number; h: number }> = {};
for (const id of artIds) {
  const r = boundsOf(id);
  if (r) {
    art[id] = {
      ox: Math.round(r.x0 * 100) / 100,
      oy: Math.round(r.y0 * 100) / 100,
      w: Math.round((r.x1 - r.x0) * 100) / 100,
      h: Math.round((r.y1 - r.y0) * 100) / 100,
    };
  } else {
    console.error(`no bounds for art id ${id} (${kindById.get(id)})`);
  }
}

writeFileSync(join(OUT, 'src/data/ui-layout.json'), JSON.stringify({ screens, art }, null, 1));
console.log(`\nart ids to export (${artIds.size}):`);
console.log([...artIds].sort((a, b) => a - b).join(','));
