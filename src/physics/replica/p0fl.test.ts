// Gate (bit-exact) — COLLISION FILTERING + SENSORS (F1/F2).
// Golden from harness-p0fl.as: three balls dropped on a floor. bLand's mask
// includes the floor's group → it collides and settles; bPass's mask EXCLUDES it →
// no arbiter, free-falls through; bSens is a sensor (collisionGroup 0) → also
// free-falls. Validates that the interaction-filter decision matches the original
// (and that excluded balls integrate as pure free-fall, bit-for-bit). 30 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0fl.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0FL] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0FL] i L <y> <vy> P <y> S <y>
    return { i: Number(p[1]), ly: p[3], lvy: p[4], py: p[6], sy: p[8] };
  });

describe('collision filtering + sensors vs ORIGINAL Nape AS3', () => {
  it('mask-included ball settles; excluded + sensor balls free-fall, bit-for-bit', () => {
    const w = new NapeReplica(1000);
    const m = (cat: number, mask: number, sensor: boolean) =>
      [1.0, 0.5, 0.1, 0.0, cat, mask, sensor] as const;

    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...m(1, 0xffff, false));
    w.finalizeBody(floor, false);

    const bLand = w.createBody(false, 160, 360, 0, 0, 0);
    w.addCircle(bLand, 0, 0, 12, ...m(4, 0xffff, false));
    w.finalizeBody(bLand, false);

    const bPass = w.createBody(false, 200, 360, 0, 0, 0);
    w.addCircle(bPass, 0, 0, 12, ...m(4, 2, false)); // floor group 1 ∉ mask 2
    w.finalizeBody(bPass, false);

    const bSens = w.createBody(false, 240, 360, 0, 0, 0);
    w.addCircle(bSens, 0, 0, 12, ...m(4, 0xffff, true)); // sensor → collisionGroup 0
    w.finalizeBody(bSens, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(bLand))).toBe(norm(f.ly));
      expect(hex16(w.getVY(bLand))).toBe(norm(f.lvy));
      expect(hex16(w.getY(bPass))).toBe(norm(f.py));
      expect(hex16(w.getY(bSens))).toBe(norm(f.sy));
    }
  });
});
