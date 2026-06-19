// Gate (bit-exact) — KINEMATIC body semantics (E-kin). Golden from harness-p0kn.as,
// two contact-free kinematic bodies:
//   plat — driven right at 120 px/s (velocity re-set each frame, as the game does via
//          SetBodyXForm): integrates position from velocity and takes NO gravity (y=400).
//   ref  — stationary, with an OFFSET collision box (origin at the feet, COM 40px up):
//          keeps its REGISTRATION origin (388,128), NOT recentered onto the COM (388,88).
//          This is the level-9 "floating referee" bug, locked bit-for-bit.
// (The rider-CARRY contact path is governed by Nape's component sleep/wake lifecycle —
// a replica simplification — so it is verified behaviourally in p0kn-kinematic.test.ts,
// not bit-exact here. See sb2_developer_messages.md.) No trig. 30 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0kn.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0KN] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0KN] i px py rx ry
    return { i: Number(p[1]), px: p[2], py: p[3], rx: p[4], ry: p[5] };
  });

describe('KINEMATIC body semantics vs ORIGINAL Nape AS3', () => {
  it('moving platform integrates by velocity (no gravity); offset referee keeps its origin, bit-for-bit', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
    const plat = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(plat, [-100, -10, 100, -10, 100, 10, -100, 10], ...MAT);
    w.finalizeBody(plat, false);
    w.setBodyType(plat, 2); // → KINEMATIC
    const ref = w.createBody(true, 388, 128, 0, 0, 0);
    w.addPolygon(ref, [-10, -80, 10, -80, 10, 0, -10, 0], ...MAT); // offset box (COM 40px up)
    w.finalizeBody(ref, false);
    w.setBodyType(ref, 2); // → KINEMATIC (must NOT align → stays at the feet)

    for (const f of frames) {
      w.setVel(plat, 120, 0); // game re-drives velocity each frame
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getX(plat)), `step ${f.i} platX`).toBe(norm(f.px));
      expect(hex16(w.getY(plat)), `step ${f.i} platY`).toBe(norm(f.py));
      expect(hex16(w.getX(ref)), `step ${f.i} refX`).toBe(norm(f.rx));
      expect(hex16(w.getY(ref)), `step ${f.i} refY`).toBe(norm(f.ry));
    }
  });
});
