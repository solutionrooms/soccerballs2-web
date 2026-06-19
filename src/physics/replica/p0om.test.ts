// Gate (bit-exact) — offset-COM body position semantics. Golden from harness-p0om.as: a
// DYNAMIC body with a feet-origin offset polygon (verts y∈[−80,0], like the game's character
// bodies) is placed at (200,416) and dropped onto a static floor (top y=480). The game/shim
// never call body.align(), so real Nape keeps body.position at the PLACEMENT ORIGIN (≈416,
// falling to ≈480 at rest) with the COM (origin+(0,−40)) tracked separately. The bug:
// finalizeBody auto-align()ed every dynamic body onto its COM (a vestige of the defunct
// Box2D-parity NapeWorld.hx), so getX/getY returned the COM (376→440) not the origin — which
// broke the level-7 opponent_patrol turn-around (|marker.y − opp.y| < 20). Fixed by dropping
// align(); the offset-COM integration/solver was already faithful (origin-referenced). The
// shipped SWF reports the ORIGIN — verified here, NOT inferred. localCOMx=0 + vertical gravity
// ⇒ no gravity-torque ⇒ rotation≡0, no trig. 120 steps (fall → settle).
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0om.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// [P0OM] i <px> <py> <rot>
const frames = lines
  .filter((l) => l.startsWith('[P0OM] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), px: p[2], py: p[3], rot: p[4] };
  });

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elasticity,group,mask,sensor

describe('offset-COM body reports the placement origin (no auto-align) vs ORIGINAL Nape AS3', () => {
  it('a feet-origin bar dropped at y=416 reports the origin (not the COM), bit-for-bit over 120 steps', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 500, 0, 0, 0);
    w.addPolygon(floor, [-150, -20, 150, -20, 150, 20, -150, 20], ...MAT);
    w.finalizeBody(floor, false);
    const bar = w.createBody(false, 200, 416, 0, 0, 0);
    w.addPolygon(bar, [-10, -80, 10, -80, 10, 0, -10, 0], ...MAT);
    w.finalizeBody(bar, false);

    // sanity: the very first reported position is the origin (416-ish), never the COM (376)
    expect(w.getY(bar)).toBeCloseTo(416, 3);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getX(bar)), `step ${f.i} bar x`).toBe(norm(f.px));
      expect(hex16(w.getY(bar)), `step ${f.i} bar y`).toBe(norm(f.py));
      expect(hex16(w.getRotRad(bar)), `step ${f.i} bar rot`).toBe(norm(f.rot)); // bar.rotation is radians
    }
    // at rest the origin sits on the floor top (≈480), proving origin- not COM-reporting
    expect(w.getY(bar)).toBeCloseTo(480.06, 1);
  });
});
