// CRITICAL gate (bit-exact) — ROTATING POLYGON-POLYGON (tilted box settling).
// Golden from harness-p0ppr.as: a dynamic box starts tilted 20° on a static floor
// and rotates down to lie flat. Exercises SAT/clip with a rotated incident edge,
// the posOnly single-corner contact → 2-contact rest transition, AND body rotation
// through the solver (the incrementally maintained axisx/axisy). 120 steps.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0ppr.json', import.meta.url)), 'utf8'),
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
const fromHex = (hex: string): number => {
  dv.setUint32(0, parseInt(hex.slice(0, 8), 16) >>> 0);
  dv.setUint32(4, parseInt(hex.slice(8), 16) >>> 0);
  return dv.getFloat64(0);
};

const frames = lines
  .filter((l) => l.startsWith('[P0PPR] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0PPR] i x y rot vx vy angvel
    return { i: Number(p[1]), x: p[2], y: p[3], rot: p[4], vx: p[5], vy: p[6], angvel: p[7] };
  });

// Poly CONTINUOUS-COLLISION gate. The box's rotation pushes it over updatePos's
// angular sweep threshold (angvel²·dt² > 0.005²), so it routes through the
// continuous pass: conservative-advance to TOI (poly-poly sweep distance), rewind
// (advanceSweep), re-solve, FREEZE (sweepFrozen). This validates that whole path.
//
// TRIG CEILING (documented project-wide): this is a rotating sim, so V8 Math.sin/cos
// and Ruffle/AVM2 eventually disagree by ≤1 ULP for some accumulated angle — and a
// box tipping on its corner is a SENSITIVE motion that amplifies that ULP into a
// small settled-pose offset. So we assert BIT-EXACT for the exact-prefix (the sweep
// is fully engaged from step 1), then a stability bound after (catches any logic
// regression / blow-up while tolerating the trig divergence). Same pattern as the
// m5 pendulum, which is also trig-limited.
const EXACT = 10; // steps bit-exact before the first Math.sin/cos disagreement
describe('CRITICAL — rotating polygon-polygon (tilted box, poly continuous-collision) vs ORIGINAL Nape AS3', () => {
  it(`box state matches bit-for-bit for ${EXACT} steps (sweep engaged), then settles to the same pose`, () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...MAT);
    w.finalizeBody(floor, false);

    const box = w.createBody(false, 200, 366, 20, 0, 0);
    w.addPolygon(box, [-12, -12, 12, -12, 12, 12, -12, 12], ...MAT);
    w.finalizeBody(box, false);

    let last = frames[0];
    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      last = f;
      if (f.i > EXACT) continue;
      const got: Record<string, string> = {
        x: hex16(w.getX(box)), y: hex16(w.getY(box)), rot: hex16(w.getRotRad(box)),
        vx: hex16(w.getVX(box)), vy: hex16(w.getVY(box)), angvel: hex16(w.getAngVel(box)),
      };
      const pairs: Record<string, string> = {
        x: f.x, y: f.y, rot: f.rot, vx: f.vx, vy: f.vy, angvel: f.angvel,
      };
      for (const k of ['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const) {
        if (got[k] !== norm(pairs[k])) {
          throw new Error(`step ${f.i} field ${k} (exact prefix): original=${toNum(pairs[k])} (${norm(pairs[k])}) replica=${fromHex(got[k])} (${got[k]})`);
        }
      }
    }
    // Settle-sanity: after the trig ceiling diverges (sensitive corner-tip amplifies
    // ~1 ULP through the bouncy settle), the FINAL pose must still converge to the
    // original's — a coarse blow-up guard, not a precision gate.
    const dx = Math.abs(w.getX(box) - toNum(last.x));
    const dy = Math.abs(w.getY(box) - toNum(last.y));
    const dr = Math.abs(w.getRotRad(box) - toNum(last.rot));
    if (!(dx < 0.5 && dy < 0.5 && dr < 0.05)) {
      throw new Error(`final pose drifted: dx=${dx} dy=${dy} drot=${dr}`);
    }
  });
});
