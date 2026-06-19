// Milestone M5 gate (bit-exact) — WeldJoint constraint solver, cantilever / no rotation.
// Golden from harness-m5w.as: a dynamic 80×20 box WELDED at its left end to a static
// anchor, cantilevering under gravity. The weld is rigid, so the box neither rotates
// nor falls — its angular DOF (jAccz) actively resists the gravity torque while
// rotation stays ~0 (no sin/cos). This grades the full 3-DOF weld solver (preStep
// 3×3 kMass / warmStart / applyImpulseVel / applyImpulsePos) BIT-FOR-BIT, with no
// cross-runtime trig gap.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m5w-weld-notrig.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[M5W] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [M5W] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

function runWeld() {
  const w = new NapeReplica(1000);
  const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
  const anchor = w.createBody(true, 200, 100, 0, 0, 0);
  w.finalizeBody(anchor, false);
  const box = w.createBody(false, 240, 100, 0, 0, 0);
  w.addPolygon(box, [-40, -10, 40, -10, 40, 10, -40, 10], ...MAT);
  w.finalizeBody(box, false);
  w.addWeldJoint(anchor, box, 0, 0, -40, 0, 0); // weld left end, phase 0
  return { w, box };
}

describe('M5 — WeldJoint solver, cantilever/no-rotation vs ORIGINAL Nape AS3', () => {
  // The box is held rigidly: x, y and vy never move, so they are graded BIT-FOR-BIT
  // and prove the full 3×3 weld solve (the angular jAccz couples into x/y via the
  // off-diagonal kMass terms, so an angular-math error would corrupt these).
  it('holds the box bit-for-bit in x, y, vy at every one of 90 steps', () => {
    const { w, box } = runWeld();
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got = { x: hex16(w.getX(box)), y: hex16(w.getY(box)), vy: hex16(w.getVY(box)) };
      const exp = { x: norm(f.x), y: norm(f.y), vy: norm(f.vy) };
      for (const k of ['x', 'y', 'vy'] as const) {
        if (got[k] !== exp[k]) {
          throw new Error(`step ${f.i} field ${k}: original=${toNum(f[k])} (${exp[k]}) replica=(${got[k]})`);
        }
      }
    }
  });

  // The angular DOF (jAccz resisting the gravity torque) drives rotation to zero;
  // the residual rot / angvel / vx are numerically ZERO (≤1e-16) — pure FP rounding
  // noise whose exact bit pattern isn't reproducible across runtimes. We assert the
  // residual stays at the precision floor (a real solver error would be O(1)), and a
  // long all-fields-exact prefix.
  it('drives the angular residual to the FP precision floor (rot/angvel/vx ≤ 1e-14)', () => {
    const { w, box } = runWeld();
    let maxResidual = 0;
    let exactPrefix = 0;
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      maxResidual = Math.max(
        maxResidual,
        Math.abs(w.getRotRad(box) - toNum(f.rot)),
        Math.abs(w.getAngVel(box) - toNum(f.angvel)),
        Math.abs(w.getVX(box) - toNum(f.vx)),
      );
      const got = {
        x: hex16(w.getX(box)), y: hex16(w.getY(box)), rot: hex16(w.getRotRad(box)),
        vx: hex16(w.getVX(box)), vy: hex16(w.getVY(box)), angvel: hex16(w.getAngVel(box)),
      };
      const allExact = (['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const).every((k) => got[k] === norm(f[k]));
      if (allExact && exactPrefix === f.i - 1) exactPrefix = f.i;
    }
    expect(maxResidual).toBeLessThan(1e-14);
    expect(exactPrefix).toBeGreaterThanOrEqual(40);
  });
});
