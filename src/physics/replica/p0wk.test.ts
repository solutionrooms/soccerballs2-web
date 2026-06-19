// Gate (bit-exact) — WAKE-ON-CONTACT (E3). Golden from harness-p0wk.as: a bottom
// ball rests on the floor and SLEEPS (~step 61); a top ball free-falls from high and
// strikes it after it slept — the impact must WAKE the sleeping ball (its island
// links to the moving ball in doForests, re-entering the solver). Both at x=200 →
// vertical, no rotation, no trig. Validates the wake path bit-for-bit, 120 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0wk.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0WK] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0WK] i bot <y> <vy> top <y> <vy>
    return { i: Number(p[1]), by: p[3], bvy: p[4], ty: p[6], tvy: p[7] };
  });

describe('wake-on-contact (sleeping ball struck by a falling ball) vs ORIGINAL Nape AS3', () => {
  it('bottom ball sleeps, is woken by the impact, and settles, bit-for-bit over 120 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...MAT);
    w.finalizeBody(floor, false);
    const bot = w.createBody(false, 200, 369, 0, 0, 0);
    w.addCircle(bot, 0, 0, 12, ...MAT);
    w.finalizeBody(bot, false);
    const top = w.createBody(false, 200, -440, 0, 0, 0);
    w.addCircle(top, 0, 0, 12, ...MAT);
    w.finalizeBody(top, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(bot)), `step ${f.i} botY`).toBe(norm(f.by));
      expect(hex16(w.getVY(bot)), `step ${f.i} botVY`).toBe(norm(f.bvy));
      expect(hex16(w.getY(top)), `step ${f.i} topY`).toBe(norm(f.ty));
      expect(hex16(w.getVY(top)), `step ${f.i} topVY`).toBe(norm(f.tvy));
    }
  });
});
