// Gate (bit-exact) — SLEEPING (E3). Golden from harness-p0sl.as: two dynamic balls
// stacked on a static floor, run 240 steps — well past the 60-stamp sleep gate. In
// the original, once both balls are at rest for 60 consecutive stamps the island
// sleeps: velocities snap to EXACTLY 0 and the bodies freeze. Without our sleeping
// implementation this diverged at step 67 (residual ~1e-15 vy vs 0). Validates the
// island/atRest/freeze path, top ball full state + bottom y/vy, bit-for-bit.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0sl.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0SL] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0SL] i x y rot vx vy angvel B botY botVY
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7], by: p[9], bvy: p[10] };
  });

describe('sleeping (island atRest + freeze) vs ORIGINAL Nape AS3', () => {
  it('stack settles, sleeps and freezes bit-for-bit over 240 steps', () => {
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
      expect(hex16(w.getX(top)), `step ${f.i} x`).toBe(norm(f.x));
      expect(hex16(w.getY(top)), `step ${f.i} y`).toBe(norm(f.y));
      expect(hex16(w.getRotRad(top)), `step ${f.i} rot`).toBe(norm(f.rot));
      expect(hex16(w.getVX(top)), `step ${f.i} vx`).toBe(norm(f.vx));
      expect(hex16(w.getVY(top)), `step ${f.i} vy`).toBe(norm(f.vy));
      expect(hex16(w.getAngVel(top)), `step ${f.i} angvel`).toBe(norm(f.angvel));
      expect(hex16(w.getY(bot)), `step ${f.i} botY`).toBe(norm(f.by));
      expect(hex16(w.getVY(bot)), `step ${f.i} botVY`).toBe(norm(f.bvy));
    }
  });
});
