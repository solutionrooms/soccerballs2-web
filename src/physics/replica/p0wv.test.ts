// Gate (bit-exact) — wake-on-velocity-mutation. Golden from harness-p0wv.as: two dynamic
// balls settle ASLEEP on a static floor (y=368.200, vy=0 by ~step 58); at step 90 — long
// after both sleep — ballI gets applyImpulse(0,-100) and ballV gets velocity=(0,-300), as
// the game does when it kicks/launches a ball. 2012 Nape WAKES a sleeping body on velocity
// mutation (Body.velocity → vel_invalidate → invalidate_wake, ZPP_Body.as:291; applyImpulse
// → invalidate_wake guarded on DYNAMIC, Body.as:2467) so the new velocity integrates —
// verified against the shipped SWF, NOT inferred. The latent bug (same class as the
// destroyBody/wake-on-removal one): setVel/applyImpulse mutated velocity but never woke the
// body, so a kick on a body asleep >1s was silently discarded. Balls are x-separated → no
// interaction, vertical only, no rotation, no trig. 140 steps (settle → sleep → kick →
// launch → re-settle → re-sleep).
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0wv.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// [P0WV] i I <Iy> <Ivy> V <Vy> <Vvy>
const frames = lines
  .filter((l) => l.startsWith('[P0WV] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), iy: p[3], ivy: p[4], vy: p[6], vvy: p[7] };
  });

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elasticity,group,mask,sensor

describe('wake-on-velocity-mutation vs ORIGINAL Nape AS3', () => {
  it('applyImpulse and velocity= on a SLEEPING ball wake it and launch, bit-for-bit over 140 steps', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-150, -20, 150, -20, 150, 20, -150, 20], ...MAT);
    w.finalizeBody(floor, false);
    const ballI = w.createBody(false, 150, 369, 0, 0, 0);
    w.addCircle(ballI, 0, 0, 12, ...MAT);
    w.finalizeBody(ballI, false);
    const ballV = w.createBody(false, 250, 369, 0, 0, 0);
    w.addCircle(ballV, 0, 0, 12, ...MAT);
    w.finalizeBody(ballV, false);

    for (const f of frames) {
      if (f.i === 90) {
        w.applyImpulse(ballI, 0, -100); // kick the (sleeping) impulse ball
        w.setVel(ballV, 0, -300); // launch the (sleeping) set-velocity ball
      }
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(ballI)), `step ${f.i} ballI y`).toBe(norm(f.iy));
      expect(hex16(w.getVY(ballI)), `step ${f.i} ballI vy`).toBe(norm(f.ivy));
      expect(hex16(w.getY(ballV)), `step ${f.i} ballV y`).toBe(norm(f.vy));
      expect(hex16(w.getVY(ballV)), `step ${f.i} ballV vy`).toBe(norm(f.vvy));
    }
  });

  // setAngVel shares the same wakeBody() code path; cover it behaviorally (a spinning
  // readout is trig-laden, so this is not goldened): a ball asleep on the floor must
  // start rotating once given an angular velocity — proving the mutation woke it.
  it('setAngVel wakes a sleeping ball so its rotation integrates', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-150, -20, 150, -20, 150, 20, -150, 20], ...MAT);
    w.finalizeBody(floor, false);
    const ball = w.createBody(false, 200, 369, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);

    for (let i = 0; i < 90; i++) w.step(1 / 60, 10, 10); // settle + sleep
    expect(w.getRot(ball), 'asleep: no rotation yet').toBe(0);
    expect(w.getAngVel(ball), 'asleep: angvel zeroed at rest').toBe(0);

    w.setAngVel(ball, 5); // spin the sleeping ball
    w.step(1 / 60, 10, 10);
    expect(w.getRot(ball), 'woke: rotation advanced').not.toBe(0);
  });
});
