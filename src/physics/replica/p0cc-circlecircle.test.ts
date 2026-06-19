// P0b-1 gate (bit-exact) — circle-CIRCLE contact wired into the solver (ptype 2).
// Golden from harness-p0cc.as: a dynamic ball balanced on a static circle (centre
// above → vertical normal), settling via the circle-circle position correction.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0cc-circlecircle.json', import.meta.url)), 'utf8'),
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
  .filter((l) => l.startsWith('[P0CC] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

describe('P0b-1 — circle-circle contact (ball on a static circle) vs ORIGINAL Nape AS3', () => {
  it('ball state matches the original bit-for-bit at every one of 60 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const post = w.createBody(true, 200, 300, 0, 0, 0);
    w.addCircle(post, 0, 0, 30, ...MAT);
    w.finalizeBody(post, false);

    const ball = w.createBody(false, 200, 257, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      const got = {
        x: hex16(w.getX(ball)), y: hex16(w.getY(ball)), rot: hex16(w.getRotRad(ball)),
        vx: hex16(w.getVX(ball)), vy: hex16(w.getVY(ball)), angvel: hex16(w.getAngVel(ball)),
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
