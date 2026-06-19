// Milestone M5 gate (bit-exact) — MotorJoint constraint solver.
// Golden from harness-m5m.as: a centred dynamic box is driven by a MotorJoint
// (rate 10 rad/s) to spin at a constant angular velocity while falling under
// gravity. MotorJoint is a purely-angular VELOCITY constraint (no position
// correction) and the COM is centred, so nothing reads the sin/cos axis → the
// whole state is bit-exact despite the spin (angvel pinned to 10, rot accumulates).
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m5m-motor.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[M5M] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [M5M] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

describe('M5 — MotorJoint constraint solver (constant-rate spin) vs ORIGINAL Nape AS3', () => {
  it('box state matches the original bit-for-bit at every one of 90 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const anchor = w.createBody(true, 200, 100, 0, 0, 0);
    w.finalizeBody(anchor, false);

    const box = w.createBody(false, 300, 100, 0, 0, 0);
    w.addPolygon(box, [-10, -10, 10, -10, 10, 10, -10, 10], ...MAT); // Polygon.box(20,20)
    w.finalizeBody(box, false);

    w.addMotorJoint(anchor, box, 10, 1); // rate 10, ratio 1

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
