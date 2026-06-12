// SoccerBalls2_Levels_Data.xml -> src/data/levels.json
// Mirrors Levels.PreLoadLevel/LoadLevel: instance params are physobj defaults
// overridden by the instance's own params string.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  parseXml,
  childrenOf,
  firstChild,
  attrStr,
  attrNum,
  attrInt,
  numList,
  paramMap,
} from './xml.ts';

const SRC = '/Users/jonscott/Projects/SoccerBalls2';
const OUT = join(import.meta.dirname, '..');

const objectsJson = JSON.parse(
  readFileSync(join(OUT, 'src/data/objects.json'), 'utf8'),
) as { physobjs: Record<string, { params: Record<string, string> }> };

const xml = parseXml(readFileSync(join(SRC, 'bin/SoccerBalls2_Levels_Data.xml'), 'utf8'));

interface InstanceJson {
  id: string;
  type: string;
  x: number;
  y: number;
  rot: number;
  scale: number;
  params: Record<string, string>;
}
interface JointJson {
  id: string;
  type: string;
  obj0: string;
  obj1: string;
  x: number;
  y: number;
  x0: number;
  y0: number;
  x1: number;
  y1: number;
  params: Record<string, string>;
}
interface LineJson {
  id: string;
  type: number;
  points: number[];
  params: Record<string, string>;
}

const levels = childrenOf(xml, 'level').map((lx) => {
  const instances: InstanceJson[] = [];
  for (const group of childrenOf(lx, 'objgroup')) {
    for (const o of childrenOf(group, 'obj')) {
      const type = attrStr(o, 'type');
      const defaults = objectsJson.physobjs[type]?.params ?? {};
      if (!objectsJson.physobjs[type]) {
        console.error(`level ${attrStr(lx, 'id')}: unknown obj type "${type}"`);
      }
      instances.push({
        id: attrStr(o, 'id'),
        type,
        x: attrNum(o, 'x'),
        y: attrNum(o, 'y'),
        rot: attrNum(o, 'rot'),
        scale: attrNum(o, 'scale', 1),
        params: { ...defaults, ...paramMap(attrStr(o, 'params')) },
      });
    }
  }

  const joints: JointJson[] = [];
  const jointsEl = firstChild(lx, 'joints');
  if (jointsEl) {
    for (const j of childrenOf(jointsEl, 'joint')) {
      joints.push({
        id: attrStr(j, 'id'),
        type: attrStr(j, 'type'),
        obj0: attrStr(j, 'objid0'),
        obj1: attrStr(j, 'objid1'),
        x: attrNum(j, 'x'),
        y: attrNum(j, 'y'),
        x0: attrNum(j, 'x0'),
        y0: attrNum(j, 'y0'),
        x1: attrNum(j, 'x1'),
        y1: attrNum(j, 'y1'),
        params: paramMap(attrStr(j, 'params')),
      });
    }
  }

  const lines: LineJson[] = [];
  for (const ln of childrenOf(lx, 'line')) {
    const points: number[] = [];
    for (const p of childrenOf(ln, 'points')) {
      points.push(...numList(attrStr(p, 'a')));
    }
    lines.push({
      id: attrStr(ln, 'id'),
      type: attrInt(ln, 'type'),
      points,
      params: paramMap(attrStr(ln, 'params')),
    });
  }

  const sb = firstChild(lx, 'soccerballs');
  let totalCoins = 0;
  let trophyIndex = 0;
  for (const inst of instances) {
    if (inst.type === 'pickup_normal') totalCoins++;
    if (inst.type.startsWith('pickup_trophy_')) trophyIndex = parseInt(inst.type.slice(14), 10);
  }

  return {
    id: attrStr(lx, 'id', '1'),
    name: attrStr(lx, 'name', 'undefined'),
    displayName: attrStr(lx, 'displayname', 'undefined'),
    category: attrInt(lx, 'category', 0),
    bgFrame: attrInt(lx, 'bg', 1),
    goldKicks: sb ? attrInt(sb, 'gold', 1) : 1,
    failKicks: sb ? attrInt(sb, 'fail', 3) : 3,
    totalCoins,
    trophyIndex, // 0 = no trophy
    helpscreens: childrenOf(lx, 'helpscreen').map((h) => attrInt(h, 'frame', 0)),
    instances,
    joints,
    lines,
  };
});

writeFileSync(join(OUT, 'src/data/levels.json'), JSON.stringify({ levels }, null, 1));

const coins = levels.reduce((sum, l) => sum + l.totalCoins, 0);
const trophies = levels.filter((l) => l.trophyIndex > 0).length;
console.log(`levels: ${levels.length} levels, ${coins} coins total, ${trophies} trophies`);
