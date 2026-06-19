// CRITICAL gate (bit-exact) — DYNAMIC-DYNAMIC circle-circle (ball ↔ ball).
// Golden from harness-p0cc2.as: two dynamic balls stacked on a static floor. The
// top↔bottom contact is dynamic-vs-dynamic circle-circle — impulse AND position
// correction apply to BOTH bodies (nonzero imass on each), the path the
// single-dynamic-body test did not exercise. We assert the top ball's full state
// (it depends entirely on the dynamic-dynamic contact) AND the bottom ball's
// y/vy, every step, bit-for-bit.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0cc2-dyndyn.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[P0CC2] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0CC2] i x y rot vx vy angvel B botY botVY
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7], botY: p[9], botVY: p[10] };
  });

describe('CRITICAL — dynamic-dynamic circle-circle (ball ↔ ball stack) vs ORIGINAL Nape AS3', () => {
  it('top ball full state + bottom ball y/vy match the original bit-for-bit, 60 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...MAT);
    w.finalizeBody(floor, false);

    const bot = w.createBody(false, 200, 369, 0, 0, 0);
    w.addCircle(bot, 0, 0, 12, ...MAT);
    w.finalizeBody(bot, false);

    const top = w.createBody(false, 200, 346, 0, 0, 0);
    w.addCircle(top, 0, 0, 12, ...MAT);
    w.finalizeBody(top, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got: Record<string, string> = {
        x: hex16(w.getX(top)), y: hex16(w.getY(top)), rot: hex16(w.getRotRad(top)),
        vx: hex16(w.getVX(top)), vy: hex16(w.getVY(top)), angvel: hex16(w.getAngVel(top)),
        botY: hex16(w.getY(bot)), botVY: hex16(w.getVY(bot)),
      };
      const pairs: Record<string, string> = {
        x: f.x, y: f.y, rot: f.rot, vx: f.vx, vy: f.vy, angvel: f.angvel, botY: f.botY, botVY: f.botVY,
      };
      for (const k of ['x', 'y', 'rot', 'vx', 'vy', 'angvel', 'botY', 'botVY'] as const) {
        if (got[k] !== norm(pairs[k])) {
          throw new Error(`step ${f.i} field ${k}: original=${toNum(pairs[k])} (${norm(pairs[k])}) replica=(${got[k]})`);
        }
      }
    }
  });
});
