// Milestone M4-CCD-a gate (bit-exact) — the closest-distance query
// (ZPP_SweepDistance.distance), the primitive the continuous-collision sweep
// builds on. Golden from harness-m4cd.as calls the ORIGINAL internal `distance`
// directly for circle-vs-polygon (face/vertex/penetrating) and circle-vs-circle
// configurations, tracing the signed distance + witness points (p3 on shape A,
// p4 on shape B, p5 normal). We reproduce each bit-for-bit.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m4cd-distance.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
// parse "[M4CD] TAG d <d> p3 <x> <y> p4 <x> <y> p5 <x> <y>" → map of tag→fields
const golden = new Map<string, Record<string, string>>();
for (const l of lines) {
  if (!l.startsWith('[M4CD] ') || l.includes('DONE')) continue;
  const p = l.split(/\s+/);
  golden.set(p[1], { d: p[3], p3x: p[5], p3y: p[6], p4x: p[8], p4y: p[9], p5x: p[11], p5y: p[12] });
}

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
const BOX = [-100, -20, 100, -20, 100, 20, -100, 20];

function world() {
  const w = new NapeReplica(0); // no gravity
  const mk = (cx: number, cy: number, shape: 'circle' | 'poly', rOrVerts: number | number[]) => {
    const h = w.createBody(true, cx, cy, 0, 0, 0);
    if (shape === 'circle') w.addCircle(h, 0, 0, rOrVerts as number, ...MAT);
    else w.addPolygon(h, rOrVerts as number[], ...MAT);
    w.finalizeBody(h, false);
    return h;
  };
  return { w, mk };
}

describe('M4-CCD-a — closest-distance query (ZPP_SweepDistance.distance) vs ORIGINAL Nape AS3', () => {
  const check = (tag: string, hA: number, hB: number, w: NapeReplica) => {
    const r = w.distanceBetween(hA, hB)!;
    const got = {
      d: hex16(r.d), p3x: hex16(r.p3x), p3y: hex16(r.p3y),
      p4x: hex16(r.p4x), p4y: hex16(r.p4y), p5x: hex16(r.p5x), p5y: hex16(r.p5y),
    };
    const exp = golden.get(tag)!;
    for (const k of ['d', 'p3x', 'p3y', 'p4x', 'p4y', 'p5x', 'p5y'] as const) {
      if (got[k] !== norm(exp[k])) {
        throw new Error(`${tag} field ${k}: original=${norm(exp[k])} replica=${got[k]}`);
      }
    }
  };

  it('FACE / VERT / PEN / CC distances + witness points match bit-for-bit', () => {
    {
      const { w, mk } = world();
      check('FACE', mk(200, 250, 'circle', 12), mk(200, 300, 'poly', BOX), w);
    }
    {
      const { w, mk } = world();
      check('VERT', mk(320, 250, 'circle', 12), mk(200, 300, 'poly', BOX), w);
    }
    {
      const { w, mk } = world();
      check('PEN', mk(200, 275, 'circle', 12), mk(200, 300, 'poly', BOX), w);
    }
    {
      const { w, mk } = world();
      check('CC', mk(100, 100, 'circle', 12), mk(150, 100, 'circle', 15), w);
    }
  });
});
