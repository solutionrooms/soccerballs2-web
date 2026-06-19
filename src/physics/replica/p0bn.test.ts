// Gate (bit-exact) — RESTITUTION on a terrain SEAM (the "lost bounce" bug). Golden from
// harness-p0bn.as: a bouncy ball (elasticity 1) dropped onto the shared vertex of two
// abutting terrain triangles (elasticity 0) lands with TWO active contacts and must
// rebound at the combined restitution 0.5 (≈ half the impact speed). The bug: the CCD
// re-solve ran a GLOBAL velocity sweep per TOI event, re-solving the already-bounced
// contact with its warm-started impulse and clawing the restitution back to ~0. Fixed by
// re-solving only the swept arbiter (Nape inline-solves the single pair). 40 steps.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0bn.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0BN] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0BN] i y vy
    return { i: Number(p[1]), y: p[2], vy: p[3] };
  });

describe('restitution on a 2-contact terrain seam vs ORIGINAL Nape AS3', () => {
  it('bouncy ball rebounds off the seam at the combined restitution, bit-for-bit over 40 steps', () => {
    const w = new NapeReplica(1000);
    const terr = w.createBody(true, 0, 0, 0, 0, 0);
    // two triangles abutting at the shared top vertex (200,400); terrain elasticity 0
    w.addPolygon(terr, [100, 400, 200, 400, 150, 440], 1.0, 0.5, 0.1, 0.0, 1, 0xffff, false);
    w.addPolygon(terr, [200, 400, 300, 400, 250, 440], 1.0, 0.5, 0.1, 0.0, 1, 0xffff, false);
    w.finalizeBody(terr, false);
    const ball = w.createBody(false, 200, 300, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, 1.0, 0.5, 0.1, 1.0, 1, 0xffff, false); // ball elasticity 1
    w.finalizeBody(ball, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(ball)), `step ${f.i} ballY`).toBe(norm(f.y));
      expect(hex16(w.getVY(ball)), `step ${f.i} ballVY`).toBe(norm(f.vy));
    }
  });
});
