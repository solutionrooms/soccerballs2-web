// Milestone M5 gate (bit-exact) — AngleJoint constraint solver.
// Golden from harness-m5a.as: a centred dynamic box is given an initial spin and
// constrained by an AngleJoint to a static body so its rotation stays within
// [-0.5, 0.5] rad, while falling under gravity (linear). AngleJoint is PURELY
// angular (reads rot/angvel, never the sin/cos axis) and the COM is centred, so no
// force reads the axis → the whole state is bit-exact despite the rotation. The box
// spins into the +0.5 limit and is held (angvel → 0), exercising slack→limit.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m5a-angle.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[M5A] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [M5A] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

describe('M5 — AngleJoint constraint solver (spin into limit) vs ORIGINAL Nape AS3', () => {
  it('box state matches the original bit-for-bit at every one of 90 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const anchor = w.createBody(true, 200, 100, 0, 0, 0);
    w.finalizeBody(anchor, false);

    const box = w.createBody(false, 300, 100, 0, 0, 0);
    w.addPolygon(box, [-10, -10, 10, -10, 10, 10, -10, 10], ...MAT); // Polygon.box(20,20)
    w.finalizeBody(box, false);
    w.setAngVel(box, 5); // initial spin → hits +0.5 rad limit

    w.addAngleJoint(anchor, box, -0.5, 0.5); // ratio 1

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got = {
        x: hex16(w.getX(box)),
        y: hex16(w.getY(box)),
        rot: hex16(w.getRotRad(box)),
        vx: hex16(w.getVX(box)),
        vy: hex16(w.getVY(box)),
        angvel: hex16(w.getAngVel(box)),
      };
      const exp = { x: norm(f.x), y: norm(f.y), rot: norm(f.rot), vx: norm(f.vx), vy: norm(f.vy), angvel: norm(f.angvel) };
      for (const k of ['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const) {
        if (got[k] !== exp[k]) {
          throw new Error(
            `step ${f.i} field ${k}: original=${toNum(f[k])} (${exp[k]}) ` +
              `replica=${toNum(`${got[k].slice(0, 8)}:${got[k].slice(8)}`)} (${got[k]})`,
          );
        }
      }
    }
  });
});
