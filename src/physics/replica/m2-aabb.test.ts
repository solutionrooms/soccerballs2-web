// Milestone M2 gate — shape AABB (the broadphase's geometric core) vs the
// ORIGINAL Nape AS3. Golden captured from harness-m2.as (unrotated circle,
// box, and an OFF-CENTRE triangle that also exercises `align`). Pair-list
// ORDERING is internal and gets verified later when multi-contact results
// become observable (M4).
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m2-aabb.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// golden AABB [minx,miny,maxx,maxy] (16-hex) for a tag
function goldenAABB(tag: string): string[] {
  const l = lines.find((x) => x.startsWith(`[M2] ${tag} `));
  if (!l) throw new Error(`no golden for ${tag}`);
  return l.split(/\s+/).slice(2).map(norm);
}

function checkAABB(tag: string, w: NapeReplica, h: number): void {
  const got = w.shapeAABB(h, 0).map(hex16);
  const exp = goldenAABB(tag);
  const names = ['minx', 'miny', 'maxx', 'maxy'];
  for (let k = 0; k < 4; k++) {
    if (got[k] !== exp[k]) throw new Error(`${tag} ${names[k]}: original=${exp[k]} replica=${got[k]}`);
  }
}

const MAT = [1.0, 0.5, 0.1, 0.3, 1, 0xffff, false] as const; // density, friction, rolling, elasticity, cat, mask, sensor

describe('M2 — shape AABB (broadphase bounds) vs ORIGINAL Nape AS3', () => {
  it('circle / box / off-centre triangle world AABBs match the original bit-for-bit', () => {
    let w = new NapeReplica(1000);
    let h = w.createBody(false, 100, 50, 0, 0.015, 0.015);
    w.addCircle(h, 0, 0, 12, ...MAT);
    w.finalizeBody(h, false);
    checkAABB('c0', w, h);

    w = new NapeReplica(1000);
    h = w.createBody(false, -30, 200, 0, 0.015, 0.015);
    w.addCircle(h, 0, 0, 7.5, ...MAT);
    w.finalizeBody(h, false);
    checkAABB('c1', w, h);

    w = new NapeReplica(1000);
    h = w.createBody(false, 300, 80, 0, 0.015, 0.015);
    w.addPolygon(h, [-20, -12, 20, -12, 20, 12, -20, 12], ...MAT);
    w.finalizeBody(h, false);
    checkAABB('b0', w, h);

    w = new NapeReplica(1000);
    h = w.createBody(false, 50, 400, 0, 0.015, 0.015);
    w.addPolygon(h, [0, -15, 13, 10, -13, 10], ...MAT);
    w.finalizeBody(h, false);
    checkAABB('t0', w, h);
  });
});
