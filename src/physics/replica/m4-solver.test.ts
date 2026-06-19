// Milestone M4 / M4-CCD gate — the contact solver, vs the ORIGINAL Nape AS3.
// Golden from harness-m4.as: a dynamic circle (r12, elasticity 0) dropped under
// gravity 1000 onto a STATIC polygon floor (top at y=280) from a large height,
// 180 steps. The ball reaches ~580 px/s before impact, so the ORIGINAL arrests
// it at the moment of contact via its continuous-collision (TOI) pass
// (ZPP_Space.continuousCollisions → ZPP_SweepDistance.staticSweep) at step 35.
//
// Our DISCRETE solver is gated bit-for-bit by m4d-discrete.test.ts. Here we
// assert the two segments the discrete pipeline fully owns — free-fall before
// contact (steps 1–34) and the settled resting equilibrium (steps 39–180) —
// match the original bit-for-bit. The impact transient (steps 35–38) is the
// continuous-collision milestone (M4-CCD), still to implement; it is asserted
// separately below as a skipped test documenting exactly what CCD must reproduce.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m4-solver.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
// decode a "hi:lo" big-endian double back to a Number, for readable diffs
const dv = new DataView(new ArrayBuffer(8));
const toNum = (pair: string): number => {
  const [hi, lo] = pair.split(':');
  dv.setUint32(0, parseInt(hi, 16) >>> 0);
  dv.setUint32(4, parseInt(lo, 16) >>> 0);
  return dv.getFloat64(0);
};

interface Frame {
  i: number;
  x: string;
  y: string;
  rot: string;
  vx: string;
  vy: string;
  angvel: string;
}

const frames: Frame[] = lines
  .filter((l) => l.startsWith('[M4] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [M4] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

// steps the DISCRETE solver fully owns: free-fall before contact, settled rest.
const isCcdImpact = (i: number): boolean => i >= 35 && i <= 38;

function runDrop() {
  const w = new NapeReplica(1000);
  // Material(elasticity 0, friction 0.5, rolling 0.1, density 1.0). Density is
  // stored internally as arg/1000, so we pass 1.0 → internal 0.001 (matching
  // the harness's Material(..,1.0,..)).
  const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
  const floor = w.createBody(true, 200, 300, 0, 0, 0);
  w.addPolygon(floor, [-200, -20, 200, -20, 200, 20, -200, 20], ...MAT);
  w.finalizeBody(floor, false);
  const ball = w.createBody(false, 200, 100, 0, 0, 0);
  w.addCircle(ball, 0, 0, 12, ...MAT);
  w.finalizeBody(ball, false);
  return { w, ball };
}

function assertFrame(f: (typeof frames)[number], got: Record<string, string>) {
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

describe('M4 — contact solver (large drop) vs ORIGINAL Nape AS3', () => {
  it('free-fall (steps 1–34) and settled rest (steps 39–180) match bit-for-bit', () => {
    const { w, ball } = runDrop();
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      if (isCcdImpact(f.i)) continue; // CCD transient — covered by the skipped test
      assertFrame(f, {
        x: hex16(w.getX(ball)),
        y: hex16(w.getY(ball)),
        rot: hex16(w.getRotRad(ball)),
        vx: hex16(w.getVX(ball)),
        vy: hex16(w.getVY(ball)),
        angvel: hex16(w.getAngVel(ball)),
      });
    }
  });

  // M4-CCD: the impact (step 35) is arrested by the continuous-collision pass
  // (continuousCollisions → staticSweep, reusing the distance query). The full
  // trajectory — including the impact transient — now matches bit-for-bit.
  it('full trajectory incl. impact (all 180 steps, every field) matches bit-for-bit', () => {
    const { w, ball } = runDrop();
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      assertFrame(f, {
        x: hex16(w.getX(ball)),
        y: hex16(w.getY(ball)),
        rot: hex16(w.getRotRad(ball)),
        vx: hex16(w.getVX(ball)),
        vy: hex16(w.getVY(ball)),
        angvel: hex16(w.getAngVel(ball)),
      });
    }
  });
});
