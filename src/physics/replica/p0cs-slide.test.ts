// P0CS — a metal-crate-sized box (48×40, `average`) sliding FAST horizontally across
// a static floor, decelerating under friction, vs the ORIGINAL Nape AS3.
// =============================================================================
// Coverage hole this fills: a box with large TANGENTIAL velocity on static terrain
// — the "sandy rebound" essence (a crate knocked sideways travels a friction-bounded
// distance; in-vs-past a hole is decided by HOW FAR it slides). No prior gate
// exercised it: p0pp settles a box vertically (≈0 friction motion), p0ppr tumbles a
// poly, p0st/p0fs are vertical stacks. It is also exactly where the 2026-06-20
// head-insert (unshift) poly-poly contact-order change could have moved the friction
// Gauss-Seidel order. Result: BIT-EXACT for 120 steps (crate slides 80 → 716.1976
// px), so the slide is faithful and the lvl-9 ordering fix did NOT perturb it —
// which rules the engine's crate-slide OUT as the cause of a "crate overshoots the
// hole" divergence (that must be upstream: the impact velocity / the ball's rebound
// path / terrain geometry, not the slide itself).
// =============================================================================
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0cs-slide.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
const dv = new DataView(new ArrayBuffer(8));
const toNum = (h: string): number => {
  dv.setUint32(0, parseInt(h.slice(0, 8), 16) >>> 0);
  dv.setUint32(4, parseInt(h.slice(8), 16) >>> 0);
  return dv.getFloat64(0);
};

interface G { x: string; y: string; r: string; vx: string }
const gold: Record<string, G> = {};
for (const ln of lines) {
  const p = ln.split(/\s+/); // [P0CS] i x y r vx
  if (p[0] !== '[P0CS]' || !p[5]) continue;
  gold[p[1]] = { x: p[2], y: p[3], r: p[4], vx: p[5] };
}

const AVG = [0.5, 0.1, 0.1, 0.2, 1, 0xffff, false] as const; // `average`
const BOX = [-24, -20, 24, -20, 24, 20, -24, 20];

describe('P0CS — fast-sliding crate (friction) vs ORIGINAL Nape AS3', () => {
  it('crate slides 80→716.1976 px bit-for-bit over 120 steps', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 300, 440, 0, 0, 0);
    w.addPolygon(floor, [-300, -20, 300, -20, 300, 20, -300, 20], ...AVG);
    w.finalizeBody(floor, false);
    const crate = w.createBody(false, 80, 400, 0, 0, 0);
    w.addPolygon(crate, BOX, ...AVG);
    w.finalizeBody(crate, false);
    w.setVel(crate, 420, 0);

    for (let i = 1; i <= 120; i++) {
      w.step(1 / 60, 10, 10);
      const g = gold[String(i)];
      const got: Record<string, string> = {
        x: hex16(w.getX(crate)), y: hex16(w.getY(crate)),
        r: hex16(w.getRotRad(crate)), vx: hex16(w.getVX(crate)),
      };
      for (const f of ['x', 'y', 'r', 'vx'] as const) {
        if (got[f] !== norm(g[f])) {
          throw new Error(`step ${i} ${f}: original=${toNum(norm(g[f]))} replica=${toNum(got[f])}`);
        }
      }
    }
  });
});
