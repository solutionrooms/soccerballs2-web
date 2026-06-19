// Gate (bit-exact) — MULTI-SHAPE bodies (E2).
// Golden from harness-p0ms.as: a static body with TWO polygon pads (left + right,
// gap between). A ball over the left pad lands on shapes[0]; a ball over the RIGHT
// pad lands on shapes[1] (the case a shapes[0]-only narrowphase would miss → would
// fall through); a ball over the gap free-falls. Validates per-shape-pair
// narrowphase + arbiter keying. 30 steps, bit-for-bit.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0ms.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const frames = lines
  .filter((l) => l.startsWith('[P0MS] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0MS] i L <y> R <y> G <y>
    return { i: Number(p[1]), ly: p[3], ry: p[5], gy: p[7] };
  });

describe('multi-shape bodies vs ORIGINAL Nape AS3', () => {
  it('balls land on shapes[0] AND shapes[1]; gap ball free-falls, bit-for-bit', () => {
    const w = new NapeReplica(1000);
    const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

    const pad = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(pad, [-80, -20, -20, -20, -20, 20, -80, 20], ...MAT); // shapes[0] left
    w.addPolygon(pad, [20, -20, 80, -20, 80, 20, 20, 20], ...MAT); // shapes[1] right
    w.finalizeBody(pad, false);

    const bL = w.createBody(false, 150, 360, 0, 0, 0);
    w.addCircle(bL, 0, 0, 12, ...MAT);
    w.finalizeBody(bL, false);
    const bR = w.createBody(false, 250, 360, 0, 0, 0);
    w.addCircle(bR, 0, 0, 12, ...MAT);
    w.finalizeBody(bR, false);
    const bG = w.createBody(false, 200, 360, 0, 0, 0);
    w.addCircle(bG, 0, 0, 12, ...MAT);
    w.finalizeBody(bG, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getY(bL))).toBe(norm(f.ly));
      expect(hex16(w.getY(bR))).toBe(norm(f.ry));
      expect(hex16(w.getY(bG))).toBe(norm(f.gy));
    }
  });
});
