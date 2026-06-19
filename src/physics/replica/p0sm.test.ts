// Gate (bit-exact) — per-shape collision-mask change (level-11 keeper duck). Golden from
// harness-p0sm.as: one static body with two solid box shapes, a ball settled on each; at step
// 30 — while the riders are AWAKE — the game disables ONE shape's collision
// (`body.shapes.at(0).filter.collisionMask = 0`, GameObj_Base.SetBodyShapeCollisionMask). Real
// Nape drops that shape's arbiter so its rider falls through, and leaves the other ball on the
// still-solid shape — the per-shape filter the body-wide setBodyCollisionMask can't express (it
// would disable all shapes and the ball would pass straight through). Verified vs the shipped SWF.
//
// Awake (the game's case: a flying ball clears the ducked shape) ⇒ the drop is immediate and
// bit-exact. A filter change on a *sleeping* rider has a separate one-step Nape wake-deferral
// (the stale arbiter holds it one extra step) that the replica's immediate dropStaleArbiters does
// not model — documented in claude-nape-replica.md; out of scope here, and not the game scenario.
//
// NB SHAPE ORDER: Nape `body.shapes.at(i)` is the REVERSE of insertion order (Nape prepends),
// whereas the replica's `b.shapes[i]` is addCircle/addPolygon CALL order. So the physical shape
// at Nape index 0 (the harness disables it → ball1 falls) is the replica's `b.shapes[1]`. The
// shim is responsible for mapping the game's Nape-order index to the replica index. Centered
// circles + axis-aligned boxes ⇒ vertical only, no rotation, no trig. 90 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0sm.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// [P0SM] i <ball0.y> <ball0.vy> <ball1.y> <ball1.vy>
const frames = lines
  .filter((l) => l.startsWith('[P0SM] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), b0y: p[2], b0vy: p[3], b1y: p[4], b1vy: p[5] };
  });

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elasticity,group,mask,sensor

describe('per-shape collision-mask change (keeper duck) vs ORIGINAL Nape AS3', () => {
  it('disabling one shape drops only its sleeping rider; the other shape keeps its rider, bit-for-bit', () => {
    const w = new NapeReplica(1000);
    const keeper = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(keeper, [-80, -20, -40, -20, -40, 20, -80, 20], ...MAT); // b.shapes[0] — left, ball0
    w.addPolygon(keeper, [40, -20, 80, -20, 80, 20, 40, 20], ...MAT); // b.shapes[1] — right, ball1
    w.finalizeBody(keeper, false);
    const ball0 = w.createBody(false, 140, 364, 0, 0, 0);
    w.addCircle(ball0, 0, 0, 15, ...MAT);
    w.finalizeBody(ball0, false);
    const ball1 = w.createBody(false, 260, 364, 0, 0, 0);
    w.addCircle(ball1, 0, 0, 15, ...MAT);
    w.finalizeBody(ball1, false);

    for (const f of frames) {
      // Nape disabled shapes.at(0) = the right shape (ball1's) ⇒ replica index 1
      if (f.i === 30) w.setShapeCollisionMask(keeper, 1, 0);
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(ball0)), `step ${f.i} ball0 y`).toBe(norm(f.b0y));
      expect(hex16(w.getVY(ball0)), `step ${f.i} ball0 vy`).toBe(norm(f.b0vy));
      expect(hex16(w.getY(ball1)), `step ${f.i} ball1 y`).toBe(norm(f.b1y));
      expect(hex16(w.getVY(ball1)), `step ${f.i} ball1 vy`).toBe(norm(f.b1vy));
    }
  });
});
