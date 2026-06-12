// SoccerBalls2_Objects_Data.xml -> src/data/objects.json
// Mirrors PhysObj.FromXml / PhysObj_Material / polymat / gamelayer parsing.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  parseXml,
  childrenOf,
  attrStr,
  attrNum,
  attrInt,
  attrBool,
  numList,
} from './xml.ts';

const SRC = '/Users/jonscott/Projects/SoccerBalls2';
const OUT = join(import.meta.dirname, '..');

const xml = parseXml(readFileSync(join(SRC, 'bin/SoccerBalls2_Objects_Data.xml'), 'utf8'));

function pair(s: string, defX = 0, defY = 0): [number, number] {
  const n = numList(s);
  return [n[0] ?? defX, n[1] ?? defY];
}

// ---- materials ----
const materials: Record<
  string,
  {
    density: number;
    frictionStatic: number;
    frictionDynamic: number;
    frictionRolling: number;
    elasticity: number;
  }
> = {};
for (const m of childrenOf(xml, 'material')) {
  const fs = attrNum(m, 'friction_static', 0);
  materials[attrStr(m, 'name')] = {
    density: attrNum(m, 'density', 1),
    frictionStatic: fs,
    // PhysObj_Material defaults dynamic/rolling to static when absent
    frictionDynamic: attrNum(m, 'friction_dynamic', fs),
    frictionRolling: attrNum(m, 'friction_rolling', fs),
    elasticity: attrNum(m, 'elasticity', 0),
  };
}

// ---- gamelayers ----
const gamelayers: Record<string, number> = {};
for (const g of childrenOf(xml, 'gamelayer')) {
  gamelayers[attrStr(g, 'name')] = attrNum(g, 'zpos', 0);
}

// ---- polymats (line materials) ----
const polymats: Record<
  string,
  {
    clip: string;
    frame: number;
    fixed: boolean;
    initType: string;
    colCat: number;
    colMask: number;
    senCat: number;
    senMask: number;
    initFunction: string;
    material: string;
    gameLayer: string;
  }
> = {};
for (const p of childrenOf(xml, 'polymat')) {
  const [colCat, colMask] = pair(attrStr(p, 'col', '0,0'));
  const [senCat, senMask] = pair(attrStr(p, 'sensor', '0,0'));
  polymats[attrStr(p, 'name')] = {
    clip: attrStr(p, 'clip'),
    frame: attrInt(p, 'frame', 1) - 1,
    fixed: attrBool(p, 'fixed', true),
    initType: attrStr(p, 'inittype'),
    colCat,
    colMask,
    senCat,
    senMask,
    initFunction: attrStr(p, 'initfunction'),
    material: attrStr(p, 'material'),
    gameLayer: attrStr(p, 'gamelayer', 'Centre'),
  };
}

// ---- objparams (global instance-param defaults) ----
const objparams: Record<string, { type: string; default: string }> = {};
for (const op of childrenOf(xml, 'objparam')) {
  objparams[attrStr(op, 'name')] = {
    type: attrStr(op, 'type', 'string'),
    default: attrStr(op, 'default'),
  };
}

// ---- physobjs ----
interface ShapeJson {
  type: string;
  name: string;
  colCat: number;
  colMask: number;
  senCat: number;
  senMask: number;
  material: string;
  pos: [number, number];
  radius?: number;
  vertices?: number[];
  rotDeg?: number;
}
interface GraphicJson {
  clip: string;
  frame: number;
  pos: [number, number];
  rot: number;
  shadow: boolean;
  goInitFunction: string;
  goInitVars: string;
}
interface BodyJson {
  name: string;
  pos: [number, number];
  fixed: boolean;
  sensor: boolean;
  graphics: GraphicJson[];
  shapes: ShapeJson[];
}
interface PhysObjJson {
  name: string;
  libClass: string;
  hasPhysics: boolean;
  snapToFloor: boolean;
  initFunction: string | null;
  initParams: string;
  wakeFunction: string;
  params: Record<string, string>;
  sfxBreak: string;
  sfxHit: string;
  bodies: BodyJson[];
}

const physobjs: Record<string, PhysObjJson> = {};
for (const po of childrenOf(xml, 'physobj')) {
  const params: Record<string, string> = {};
  for (const p of childrenOf(po, 'parameter')) {
    params[attrStr(p, 'name')] = attrStr(p, 'default');
  }
  let sfxBreak = '';
  let sfxHit = '';
  for (const s of childrenOf(po, 'sfx')) {
    sfxBreak = attrStr(s, 'broken');
    sfxHit = attrStr(s, 'hit');
  }
  const bodies: BodyJson[] = [];
  // graphics may sit on the physobj directly (hasphysics=false decor) or on bodies
  const looseGraphics = childrenOf(po, 'graphic').map(parseGraphic);
  for (const b of childrenOf(po, 'body')) {
    bodies.push({
      name: attrStr(b, 'name'),
      pos: pair(attrStr(b, 'pos', '0,0')),
      fixed: attrBool(b, 'fixed', false),
      sensor: attrBool(b, 'sensor', false),
      graphics: childrenOf(b, 'graphic').map(parseGraphic),
      shapes: childrenOf(b, 'shape').map(parseShape),
    });
  }
  if (looseGraphics.length && !bodies.length) {
    bodies.push({
      name: 'fix',
      pos: [0, 0],
      fixed: true,
      sensor: false,
      graphics: looseGraphics,
      shapes: [],
    });
  }
  const name = attrStr(po, 'name');
  physobjs[name] = {
    name,
    libClass: attrStr(po, 'libclass'),
    hasPhysics: attrBool(po, 'hasphysics', true),
    snapToFloor: attrBool(po, 'snaptofloor', false),
    initFunction: attrStr(po, 'initfunction') || null,
    initParams: attrStr(po, 'initparams'),
    wakeFunction: attrStr(po, 'wakefunction'),
    params,
    sfxBreak,
    sfxHit,
    bodies,
  };
}

function parseGraphic(g: import('./xml.ts').XmlNode): GraphicJson {
  return {
    clip: attrStr(g, 'clip'),
    frame: attrInt(g, 'frame', 1) - 1,
    pos: pair(attrStr(g, 'pos', '0,0')),
    rot: attrNum(g, 'rot', 0),
    shadow: attrBool(g, 'shadow', true),
    goInitFunction: attrStr(g, 'gameobjfunction'),
    goInitVars: attrStr(g, 'gameobjvars'),
  };
}

function parseShape(s: import('./xml.ts').XmlNode): ShapeJson {
  const [colCat, colMask] = pair(attrStr(s, 'col', '0,0'));
  const [senCat, senMask] = pair(attrStr(s, 'sensor', '0,0'));
  const shape: ShapeJson = {
    type: attrStr(s, 'type'),
    name: attrStr(s, 'name'),
    colCat,
    colMask,
    senCat,
    senMask,
    material: attrStr(s, 'material'),
    pos: pair(attrStr(s, 'pos', '0,0')),
  };
  if (shape.type === 'circle') {
    shape.radius = attrNum(s, 'radius', 10);
  } else {
    shape.vertices = numList(attrStr(s, 'vertices'));
    shape.rotDeg = attrNum(s, 'rot', 0);
  }
  return shape;
}

writeFileSync(
  join(OUT, 'src/data/objects.json'),
  JSON.stringify({ materials, gamelayers, polymats, objparams, physobjs }, null, 1),
);

console.log(
  `objects: ${Object.keys(physobjs).length} physobjs, ${Object.keys(materials).length} materials, ` +
    `${Object.keys(polymats).length} polymats, ${Object.keys(gamelayers).length} layers, ${Object.keys(objparams).length} objparams`,
);
