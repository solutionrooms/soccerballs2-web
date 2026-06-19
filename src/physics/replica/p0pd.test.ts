// Gate (bit-exact) — POLY-POLY closest distance (ZPP_SweepDistance.distance).
// Golden from harness-p0pd.as: axis-aligned box pairs (separated face region,
// separated corner/endpoint region, overlapping) in both argument orders (to
// exercise the loc24/swap path). Asserts d + witness p3/p4 + normal p5 bit-for-bit.
// This is the distance primitive poly continuous-collision (the sweep) builds on.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0pd.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// parse "[P0PD] TAG d <bits> p3 <x> <y> p4 <x> <y> p5 <x> <y>"
const golden: Record<string, { d: string; p3x: string; p3y: string; p4x: string; p4y: string; p5x: string; p5y: string }> = {};
for (const l of lines) {
  if (!l.startsWith('[P0PD] ') || l.includes('DONE')) continue;
  const p = l.split(/\s+/);
  golden[p[1]] = { d: p[3], p3x: p[5], p3y: p[6], p4x: p[8], p4y: p[9], p5x: p[11], p5y: p[12] };
}

describe('poly-poly closest distance vs ORIGINAL Nape AS3', () => {
  const w = new NapeReplica(1000);
  const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
  const big = [-100, -20, 100, -20, 100, 20, -100, 20];
  const small = [-12, -12, 12, -12, 12, 12, -12, 12];
  const mk = (x: number, y: number, verts: number[]): number => {
    const h = w.createBody(true, x, y, 0, 0, 0);
    w.addPolygon(h, verts, ...MAT);
    w.finalizeBody(h, false);
    return h;
  };
  const floor = mk(200, 300, big);
  const bFace = mk(200, 250, small);
  const bCorner = mk(320, 250, small);
  const bPen = mk(200, 272, small);

  const cases: [string, number, number][] = [
    ['FACE', bFace, floor], ['FACEr', floor, bFace],
    ['CORNER', bCorner, floor], ['CORNERr', floor, bCorner],
    ['PEN', bPen, floor], ['PENr', floor, bPen],
  ];

  for (const [tag, a, b] of cases) {
    it(`${tag} matches bit-for-bit`, () => {
      const r = w.distanceBetween(a, b)!;
      const g = golden[tag];
      expect(hex16(r.d)).toBe(norm(g.d));
      expect(hex16(r.p3x)).toBe(norm(g.p3x));
      expect(hex16(r.p3y)).toBe(norm(g.p3y));
      expect(hex16(r.p4x)).toBe(norm(g.p4x));
      expect(hex16(r.p4y)).toBe(norm(g.p4y));
      expect(hex16(r.p5x)).toBe(norm(g.p5x));
      expect(hex16(r.p5y)).toBe(norm(g.p5y));
    });
  }
});
