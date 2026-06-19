// Gate (bit-exact) — runtime sensorEnabled toggle (game shape.sensorEnabled = true).
// Golden from harness-p0se.as: a ball rests on a static block; at step 30 (still awake) the
// block's shape becomes a SENSOR, leaving the solver, so the ball free-falls through.
// Validates that setBodySensorEnabled drops the already-touching contact, bit-for-bit.
// No rotation/trig. 50 steps. See sb2_developer_messages.md.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0se.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0SE] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0SE] i y vy
    return { i: Number(p[1]), y: p[2], vy: p[3] };
  });

describe('runtime sensorEnabled toggle vs ORIGINAL Nape AS3', () => {
  it('ball resting on a block free-falls when the block becomes a sensor at step 30, bit-for-bit', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
    const block = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(block, [-50, -10, 50, -10, 50, 10, -50, 10], ...MAT);
    w.finalizeBody(block, false);
    const ball = w.createBody(false, 200, 376, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);

    for (const f of frames) {
      if (f.i === 30) w.setBodySensorEnabled(block, true); // block becomes a sensor
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(ball)), `step ${f.i} ballY`).toBe(norm(f.y));
      expect(hex16(w.getVY(ball)), `step ${f.i} ballVY`).toBe(norm(f.vy));
    }
  });
});
