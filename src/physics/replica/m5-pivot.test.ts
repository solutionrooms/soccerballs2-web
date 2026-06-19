// Milestone M5 — the constraint solver (PivotJoint) on a ROTATING body, vs the
// ORIGINAL Nape AS3. Golden from harness-m5.as: a dynamic 80×20 box pinned by a
// PivotJoint at its left end to a STATIC anchor, swinging under gravity (a
// pendulum). No contacts → isolates the joint solver.
//
// The solver itself is gated BIT-FOR-BIT by m5b-pivot-notrig.test.ts (same solver,
// pivot at the COM so the body never rotates → no trig). Here the body rotates, so
// the result is bit-exact only until the accumulating ≤1-ULP cross-runtime sin/cos
// difference (AVM2/Ruffle vs V8 — the one documented unavoidable gap) first crosses
// a rounding boundary. A pendulum amplifies that, so we assert: (a) a bit-exact
// prefix of the run, and (b) the FULL run tracks the original to a tiny relative
// tolerance — far tighter than any physical concern, but loose enough for the
// trig gap. A real op-order bug would diverge exponentially to O(1), failing (b).
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m5-pivot.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[M5] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [M5] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

function runPendulum() {
  const w = new NapeReplica(1000);
  const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
  const anchor = w.createBody(true, 200, 100, 0, 0, 0); // static, no shapes
  w.finalizeBody(anchor, false);
  const box = w.createBody(false, 240, 100, 0, 0, 0);
  w.addPolygon(box, [-40, -10, 40, -10, 40, 10, -40, 10], ...MAT); // Polygon.box(80,20)
  w.finalizeBody(box, false);
  w.addPivotJoint(anchor, box, 0, 0, -40, 0); // pin box's left end to the anchor
  return { w, box };
}

describe('M5 — PivotJoint constraint solver (rotating pendulum) vs ORIGINAL Nape AS3', () => {
  it('is bit-for-bit until the first cross-runtime sin/cos rounding boundary (≥30 steps)', () => {
    const { w, box } = runPendulum();
    let exactPrefix = 0;
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got = {
        x: hex16(w.getX(box)), y: hex16(w.getY(box)), rot: hex16(w.getRotRad(box)),
        vx: hex16(w.getVX(box)), vy: hex16(w.getVY(box)), angvel: hex16(w.getAngVel(box)),
      };
      const exp = { x: norm(f.x), y: norm(f.y), rot: norm(f.rot), vx: norm(f.vx), vy: norm(f.vy), angvel: norm(f.angvel) };
      const allExact = (['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const).every((k) => got[k] === exp[k]);
      if (!allExact) break;
      exactPrefix = f.i;
    }
    expect(exactPrefix).toBeGreaterThanOrEqual(30);
  });

  it('tracks the original to <1e-9 relative over the full 90 steps (trig-limited)', () => {
    const { w, box } = runPendulum();
    let maxRel = 0;
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got = [w.getX(box), w.getY(box), w.getRotRad(box), w.getVX(box), w.getVY(box), w.getAngVel(box)];
      const exp = [f.x, f.y, f.rot, f.vx, f.vy, f.angvel].map(toNum);
      for (let k = 0; k < 6; k++) {
        const denom = Math.max(Math.abs(exp[k]), 1e-6);
        maxRel = Math.max(maxRel, Math.abs(got[k] - exp[k]) / denom);
      }
    }
    expect(maxRel).toBeLessThan(1e-9);
  });
});
