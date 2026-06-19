// CRITICAL gate (bit-exact) — POLYGON-POLYGON (box on static floor).
// Golden from harness-p0pp.as: a dynamic 24×24 box resting centred on a static
// floor, bottom edge penetrating by 1. The manifold is face-face with TWO contact
// points → exercises the 2×2 "block" velocity LCP (iterateVel hc2) and the
// two-contact position solver (iteratePos hpc2), the paths that previously threw.
// We assert the box's full state every step, bit-for-bit, 60 steps.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0pp.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
const dv = new DataView(new ArrayBuffer(8));
const toNum = (pair: string): number => {
  const [hi, lo] = pair.split(':');
  dv.setUint32(0, parseInt(hi, 16) >>> 0);
  dv.setUint32(4, parseInt(lo, 16) >>> 0);
  return dv.getFloat64(0);
};

const frames = lines
  .filter((l) => l.startsWith('[P0PP] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0PP] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

describe('CRITICAL — polygon-polygon (box on static floor) vs ORIGINAL Nape AS3', () => {
  it('box full state matches the original bit-for-bit, 60 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...MAT);
    w.finalizeBody(floor, false);

    const box = w.createBody(false, 200, 367, 0, 0, 0);
    w.addPolygon(box, [-12, -12, 12, -12, 12, 12, -12, 12], ...MAT);
    w.finalizeBody(box, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got: Record<string, string> = {
        x: hex16(w.getX(box)), y: hex16(w.getY(box)), rot: hex16(w.getRotRad(box)),
        vx: hex16(w.getVX(box)), vy: hex16(w.getVY(box)), angvel: hex16(w.getAngVel(box)),
      };
      const pairs: Record<string, string> = {
        x: f.x, y: f.y, rot: f.rot, vx: f.vx, vy: f.vy, angvel: f.angvel,
      };
      for (const k of ['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const) {
        if (got[k] !== norm(pairs[k])) {
          throw new Error(`step ${f.i} field ${k}: original=${toNum(pairs[k])} (${norm(pairs[k])}) replica=(${got[k]}=${toNum2(got[k])})`);
        }
      }
    }
  });
});

function toNum2(hex: string): number {
  dv.setUint32(0, parseInt(hex.slice(0, 8), 16) >>> 0);
  dv.setUint32(4, parseInt(hex.slice(8), 16) >>> 0);
  return dv.getFloat64(0);
}
