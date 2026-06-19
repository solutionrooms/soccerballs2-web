// Gate (bit-exact) — wake-on-removal (sand-block mechanic). Golden from harness-p0rm.as:
// a dynamic ball settles ASLEEP on a static block; at step 120 the block is removed from
// the space (game RemovePhysObj → space.bodies.remove). 2012 Nape WAKES the resting ball
// (removed_shape → body.wake(), ZPP_Space.as:2353/2388) so it falls — verified against the
// shipped SWF, NOT inferred. The bug: destroyBody dropped the arbiter but left the partner
// asleep → frozen in mid-air. Fixed by waking the dropped arbiter/constraint partners.
// No rotation/trig. 180 steps (settle → sleep → remove → free-fall).
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0rm.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0RM] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0RM] i y vy
    return { i: Number(p[1]), y: p[2], vy: p[3] };
  });

describe('wake-on-body-removal (sand-block mechanic) vs ORIGINAL Nape AS3', () => {
  it('ball asleep on a block wakes and free-falls when the block is removed, bit-for-bit over 180 steps', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
    const block = w.createBody(true, 300, 300, 0, 0, 0);
    w.addPolygon(block, [-50, -15, 50, -15, 50, 15, -50, 15], ...MAT);
    w.finalizeBody(block, false);
    const ball = w.createBody(false, 300, 235, 0, 0, 0);
    w.addCircle(ball, 0, 0, 35, ...MAT);
    w.finalizeBody(ball, false);

    for (const f of frames) {
      if (f.i === 120) w.destroyBody(block); // block destroyed before this step
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(ball)), `step ${f.i} ballY`).toBe(norm(f.y));
      expect(hex16(w.getVY(ball)), `step ${f.i} ballVY`).toBe(norm(f.vy));
    }
  });
});
