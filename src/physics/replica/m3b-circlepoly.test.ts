// Milestone M3b gate — circle-polygon narrowphase vs the ORIGINAL Nape AS3.
// Golden from harness-m3b.as: a circle on a box FACE (edge contact, exact) and a
// circle off a box CORNER (vertex contact, fast-inv-sqrt). Each line:
//   [M3CP-<EDGE|VERT>] body1 body2 nx ny penetration  (raw IEEE-754 bits)
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m3b-circlepoly.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
const MAT = [1.0, 0.5, 0.1, 0.3, 1, 0xffff, false] as const;
const BOX = [-20, -12, 20, -12, 20, 12, -20, 12];

function manifold(cx: number, cy: number): { nx: number; ny: number; penetration: number } {
  const w = new NapeReplica(0);
  const hc = w.createBody(false, cx, cy, 0, 0, 0); // body1 (circle)
  w.addCircle(hc, 0, 0, 15, ...MAT);
  w.finalizeBody(hc, false);
  const hp = w.createBody(false, 200, 200, 0, 0, 0); // body2 (box)
  w.addPolygon(hp, BOX, ...MAT);
  w.finalizeBody(hp, false);
  return w.circlePolyManifold(hc, hp)!;
}

function check(tag: string, cx: number, cy: number): void {
  const l = lines.find((x) => x.startsWith(`[M3CP-${tag}]`))!.split(/\s+/); // tag b1 b2 nx ny pen
  const exp = { nx: norm(l[3]), ny: norm(l[4]), pen: norm(l[5]) };
  const m = manifold(cx, cy);
  const got = { nx: hex16(m.nx), ny: hex16(m.ny), pen: hex16(m.penetration) };
  for (const k of ['nx', 'ny', 'pen'] as const) {
    if (got[k] !== exp[k]) throw new Error(`${tag} ${k}: original=${exp[k]} replica=${got[k]}`);
  }
}

describe('M3b — circle-polygon narrowphase vs ORIGINAL Nape AS3', () => {
  it('EDGE face contact (exact) matches the original bit-for-bit', () => {
    check('EDGE', 200, 175);
  });
  it('VERTEX/corner contact (fast-inv-sqrt) matches the original bit-for-bit', () => {
    check('VERT', 175, 175);
  });
});
