// Gate (bit-exact) — kinematic-vs-resting-dynamic restitution (level-7 "ball sticks to the
// opponent"). Golden from harness-p0kr.as: a dynamic ball (e=1) rests on a static floor; a
// KINEMATIC wall (e=0.2) translates RIGHT at +120 (velocity re-set every step) and strikes
// the ball. Real Nape builds contact relative velocity from vel+KINVEL and sweeps a
// kinematic-involved CCD pair with dynamicSweep (relative frame), so the ball REBOUNDS to
// vx=+192 (combine 0.6: approach 120 + bounce 72) and pulls AHEAD of the wall.
//
// The bug had two layers, both in the CCD path: the replica always used staticSweep (obstacle
// treated as stationary), so after the discrete solve bounced the ball to 192 the sweep saw
// the wall (advanced into the ball's old cell) as a fixed penetrating wall → false toi=0 →
// re-solve → the bounce was clawed back and the ball locked to the wall's +120. Fixed by
// routing kinematic-obstacle pairs through dynamicSweep (both bodies advance, relative
// velocity) — a separating pair then yields toi<0 and is left alone. Verified vs the shipped
// SWF. Frictionless + axis-aligned ⇒ pure 1-D x, no rotation, no trig. 90 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0kr.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// [P0KR] i <ballx> <ballvx> <wallx>
const frames = lines
  .filter((l) => l.startsWith('[P0KR] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), bx: p[2], bvx: p[3], wx: p[4] };
  });

describe('kinematic-vs-resting-dynamic restitution vs ORIGINAL Nape AS3', () => {
  it('a moving kinematic wall bounces a resting ball ahead of it (no stick), bit-for-bit over 90 steps', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 300, 440, 0, 0, 0);
    w.addPolygon(floor, [-300, -20, 300, -20, 300, 20, -300, 20], 1.0, 0, 0, 0.0, 1, 0xffff, false);
    w.finalizeBody(floor, false);
    const ball = w.createBody(false, 300, 400, 0, 0, 0);
    w.addCircle(ball, 0, 0, 20, 1.0, 0, 0, 1.0, 1, 0xffff, false);
    w.finalizeBody(ball, false);
    const wall = w.createBody(false, 200, 400, 0, 0, 0);
    w.addPolygon(wall, [-20, -100, 20, -100, 20, 100, -20, 100], 1.0, 0, 0, 0.2, 1, 0xffff, false);
    w.finalizeBody(wall, false);
    w.setBodyType(wall, 2); // KINEMATIC

    for (const f of frames) {
      w.setVel(wall, 120, 0); // game re-sets the kinematic velocity each step
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getX(ball)), `step ${f.i} ball x`).toBe(norm(f.bx));
      expect(hex16(w.getVX(ball)), `step ${f.i} ball vx`).toBe(norm(f.bvx));
      expect(hex16(w.getX(wall)), `step ${f.i} wall x`).toBe(norm(f.wx));
    }
  });
});
