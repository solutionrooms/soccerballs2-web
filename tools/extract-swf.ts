// Parse the ffdec -swf2xml dump of bin/SoccerBalls2.swf and produce:
//   src/data/labels.json — frame labels per exported (SymbolClass-named) sprite
//   src/data/rigs.json   — player/ref/keeper per-frame part transforms,
//                          replicating AnimHierarchy.Init() accumulation math
//
// Run `java -jar tools/vendor/ffdec.jar -swf2xml <swf> /tmp/sb2-swf.xml` first
// (or pass an alternate xml path as argv[2]).
//
// The 68MB dump is processed line-by-line; only sprite structure tags are read.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const XML_PATH = process.argv[2] ?? '/tmp/sb2-swf.xml';
const OUT = join(import.meta.dirname, '..');

interface Matrix {
  a: number;
  b: number;
  c: number;
  d: number;
  tx: number; // px
  ty: number; // px
}
interface Placement {
  charId: number;
  name: string;
  matrix: Matrix | null;
}
interface SpriteFrame {
  label: string | null;
  // depth -> placement snapshot
  placements: Record<number, Placement>;
}
interface Sprite {
  id: number;
  frames: SpriteFrame[];
}

const IDENT: Matrix = { a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 };

function attr(line: string, name: string): string | undefined {
  const m = line.match(new RegExp(` ${name}="([^"]*)"`));
  return m?.[1];
}

const lines = readFileSync(XML_PATH, 'utf8').split('\n');

// ---- pass 1: sprites (display list per frame) ----
const sprites = new Map<number, Sprite>();
{
  let cur: Sprite | null = null;
  let depthState: Map<number, Placement> | null = null;
  let pendingLabel: string | null = null;
  let pendingPlace: { depth: number; move: boolean; place: Placement } | null = null;
  let spriteEndDepth = 0;
  let elemDepth = 0;

  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith('<item type="DefineSpriteTag"')) {
      cur = { id: Number(attr(t, 'spriteId')), frames: [] };
      depthState = new Map();
      pendingLabel = null;
      spriteEndDepth = elemDepth;
    }
    // track element nesting via opens/closes (machine-generated, one tag per line)
    if (
      t.startsWith('<') &&
      !t.startsWith('</') &&
      !t.endsWith('/>') &&
      !t.startsWith('<?') &&
      !t.includes('</') // single-line <item>text</item> opens AND closes
    ) {
      elemDepth++;
    } else if (t.startsWith('</')) {
      elemDepth--;
      if (cur && elemDepth === spriteEndDepth && t === '</item>') {
        sprites.set(cur.id, cur);
        cur = null;
        depthState = null;
      }
    }
    if (!cur || !depthState) continue;

    if (t.startsWith('<item type="PlaceObject2Tag"') || t.startsWith('<item type="PlaceObject3Tag"')) {
      const depth = Number(attr(t, 'depth'));
      const move = attr(t, 'placeFlagMove') === 'true';
      const hasChar = attr(t, 'placeFlagHasCharacter') === 'true';
      const prev = depthState.get(depth);
      const place: Placement = {
        charId: hasChar ? Number(attr(t, 'characterId')) : (prev?.charId ?? -1),
        name: attr(t, 'name') ?? (move ? (prev?.name ?? '') : ''),
        matrix:
          attr(t, 'placeFlagHasMatrix') === 'true'
            ? null // filled by the nested <matrix> line
            : move
              ? (prev?.matrix ?? { ...IDENT })
              : { ...IDENT },
      };
      depthState.set(depth, place);
      if (attr(t, 'placeFlagHasMatrix') === 'true' && !t.endsWith('/>')) {
        pendingPlace = { depth, move, place };
      }
    } else if (pendingPlace && t.startsWith('<matrix type="MATRIX"')) {
      const hasScale = attr(t, 'hasScale') === 'true';
      const hasRotate = attr(t, 'hasRotate') === 'true';
      // ffdec emits scale/rotateSkew as decoded floats (NOT raw 16.16 fixed
      // point); only translate is still in twips
      pendingPlace.place.matrix = {
        a: hasScale ? Number(attr(t, 'scaleX')) : 1,
        d: hasScale ? Number(attr(t, 'scaleY')) : 1,
        b: hasRotate ? Number(attr(t, 'rotateSkew0')) : 0,
        c: hasRotate ? Number(attr(t, 'rotateSkew1')) : 0,
        tx: Number(attr(t, 'translateX')) / 20,
        ty: Number(attr(t, 'translateY')) / 20,
      };
      pendingPlace = null;
    } else if (t.startsWith('<item type="RemoveObject2Tag"') || t.startsWith('<item type="RemoveObjectTag"')) {
      depthState.delete(Number(attr(t, 'depth')));
    } else if (t.startsWith('<item type="FrameLabelTag"')) {
      pendingLabel = attr(t, 'name') ?? null;
    } else if (t.startsWith('<item type="ShowFrameTag"')) {
      const placements: Record<number, Placement> = {};
      for (const [d, p] of depthState) {
        placements[d] = { charId: p.charId, name: p.name, matrix: p.matrix ? { ...p.matrix } : null };
      }
      cur.frames.push({ label: pendingLabel, placements });
      pendingLabel = null;
    }
  }
}

// ---- pass 2: SymbolClass charId -> className ----
const classByCharId = new Map<number, string>();
{
  let inSymbol = false;
  let inTags = false;
  let inNames = false;
  const ids: number[] = [];
  const names: string[] = [];
  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith('<item type="SymbolClassTag"')) inSymbol = true;
    if (!inSymbol) continue;
    if (t === '<tags>') inTags = true;
    else if (t === '</tags>') inTags = false;
    else if (t === '<names>') inNames = true;
    else if (t === '</names>') {
      inNames = false;
      inSymbol = false;
      for (let i = 0; i < ids.length; i++) {
        classByCharId.set(ids[i], names[i]);
      }
      ids.length = 0;
      names.length = 0;
    } else if (t.startsWith('<item>')) {
      const v = t.replace('<item>', '').replace('</item>', '');
      if (inTags) ids.push(Number(v));
      else if (inNames) names.push(v);
    }
  }
}

const charIdByClass = new Map<string, number>();
for (const [id, name] of classByCharId) charIdByClass.set(name, id);

// ---- labels.json ----
const labels: Record<string, { frame: number; label: string }[]> = {};
for (const [id, sprite] of sprites) {
  const cls = classByCharId.get(id);
  if (!cls) continue;
  const list: { frame: number; label: string }[] = [];
  sprite.frames.forEach((f, i) => {
    if (f.label) list.push({ frame: i, label: f.label });
  });
  if (list.length) labels[cls] = list;
}
writeFileSync(join(OUT, 'src/data/labels.json'), JSON.stringify(labels, null, 1));
console.log(`labels: ${Object.keys(labels).length} clips with labels`);

// ---- rigs.json (AnimHierarchy.Init replication) ----
// Flash DisplayObject decomposition used by AnimHierarchy (x, y, rotation, scaleX):
function flashProps(m: Matrix): { x: number; y: number; r: number; sc: number } {
  return {
    x: m.tx,
    y: m.ty,
    r: (Math.atan2(m.b, m.a) * 180) / Math.PI,
    sc: Math.hypot(m.a, m.b),
  };
}

function findChildByName(frame: SpriteFrame, name: string): Placement | null {
  for (const p of Object.values(frame.placements)) {
    if (p.name === name) return p;
  }
  return null;
}

// GameVars.as parts/clips tables (verbatim).
const PARTS_PLAYER = [
  'upperArmRight', 'upperArmRight.tint', 'upperArmRight.lines',
  'lowerArmRight',
  'upperLegRight', 'upperLegRight.tint', 'upperLegRight.lines',
  'footRight', 'footRight.tint', 'footRight.lines',
  'head',
  'upperLegLeft', 'upperLegLeft.tint', 'upperLegLeft.lines',
  'body', 'body.tint', 'body.tint_stripes', 'body.tint_hoops', 'body.lines',
  'footLeft', 'footLeft.tint', 'footLeft.lines',
  'upperArmLeft', 'upperArmLeft.tint', 'upperArmLeft.lines',
  'lowerArmLeft',
];
const CLIPS_PLAYER = [
  'player_upperArm', 'tint_topArm', 'player_toparmLines',
  'player_foreArm',
  'player_topLeg', 'tint_topLeg', 'player_shortLines',
  'player_foot', 'tint_socks', 'player_legLines',
  'player_head',
  'player_topLeg', 'tint_topLeg', 'player_shortLines',
  'player_body', 'tint_shirtbase', 'tint_shirtStripes', 'tint_hoopsEXP', 'shirt_lines',
  'player_foot', 'tint_socks', 'player_legLines',
  'player_upperArm', 'tint_topArm', 'player_toparmLines',
  'player_foreArm',
];
const PARTS_BASIC = [
  'upperArmRight', 'lowerArmRight', 'upperLegRight', 'footRight', 'head',
  'upperLegLeft', 'body', 'footLeft', 'upperArmLeft', 'lowerArmLeft',
];
const CLIPS_REF = [
  'ref_upperArm', 'ref_foreArm', 'ref_topLeg', 'ref_foot', 'ref_head',
  'ref_topLeg', 'ref_body', 'ref_foot', 'ref_upperArm', 'ref_foreArm',
];
const CLIPS_KEEPER = [
  'keeper_upperArm', 'keeper_foreArm', 'keeper_topLeg', 'keeper_foot', 'keeper_head',
  'keeper_topLeg', 'keeper_body', 'keeper_foot', 'keeper_upperArm', 'keeper_foreArm',
];

interface RigPart {
  part: string;
  clip: string;
  x: number;
  y: number;
  r: number;
  sc: number;
}

function buildRig(className: string, parts: string[], clips: string[]): RigPart[][] | null {
  const charId = charIdByClass.get(className);
  if (charId === undefined) {
    console.error(`rig: no SymbolClass for "${className}"`);
    return null;
  }
  const sprite = sprites.get(charId);
  if (!sprite) {
    console.error(`rig: charId ${charId} ("${className}") is not a sprite`);
    return null;
  }
  const frames: RigPart[][] = [];
  for (const frame of sprite.frames) {
    const frameParts: RigPart[] = [];
    for (let pi = 0; pi < parts.length; pi++) {
      const path = parts[pi].split('.');
      // Accumulate exactly like AnimHierarchy.Init: rotate+scale accumulated
      // position offsets, sum rotations, multiply scaleX.
      let x = 0;
      let y = 0;
      let r = 0;
      let sc = 1;
      let curFrame: SpriteFrame | null = frame;
      let ok = true;
      for (const childName of path) {
        const placement = curFrame ? findChildByName(curFrame, childName) : null;
        if (!placement || !placement.matrix) {
          ok = false;
          break;
        }
        const props = flashProps(placement.matrix);
        const rad = (r * Math.PI) / 180;
        const px = props.x * Math.cos(rad) - props.y * Math.sin(rad);
        const py = props.x * Math.sin(rad) + props.y * Math.cos(rad);
        x += px * sc;
        y += py * sc;
        r += props.r;
        sc *= props.sc;
        // descend: child clip's own frame 1 (gotoAndStop(1) in original)
        const childSprite = sprites.get(placement.charId);
        curFrame = childSprite?.frames[0] ?? null;
      }
      frameParts.push({
        part: parts[pi],
        clip: clips[pi],
        x: ok ? round3(x) : 0,
        y: ok ? round3(y) : 0,
        r: ok ? round3(r) : 0,
        sc: ok ? round3(sc) : 1,
      });
    }
    frames.push(frameParts);
  }
  return frames;
}

function round3(n: number): number {
  return Math.round(n * 1000) / 1000;
}

const rigs: Record<string, RigPart[][]> = {};
for (const [name, parts, clips] of [
  ['player', PARTS_PLAYER, CLIPS_PLAYER],
  ['ref', PARTS_BASIC, CLIPS_REF],
  ['keeper', PARTS_BASIC, CLIPS_KEEPER],
] as const) {
  const rig = buildRig(name, parts, clips);
  if (rig) {
    rigs[name] = rig;
    console.log(`rig "${name}": ${rig.length} frames x ${parts.length} parts`);
  }
}
writeFileSync(join(OUT, 'src/data/rigs.json'), JSON.stringify(rigs));

// quick visibility into label sets gameplay relies on
for (const cls of ['player', 'ref', 'keeper', 'goal', 'goal2']) {
  if (labels[cls]) {
    console.log(`labels[${cls}]:`, labels[cls].map((l) => `${l.label}@${l.frame}`).join(' '));
  }
}
