// P0SR — "sandy rebound" (lvl "19: SANDY REBOUND") f65 DIVERGENCE, vs the ORIGINAL Nape AS3.
// =============================================================================
// THE decisive contact behind the lvl-19 "crate overshoots the hole" blocker. The haxe-port
// A/B (replica :8753 vs nape-haxe4 :8754, both V8 → no trig noise) pinned the whole-level
// divergence to a SINGLE collision at frame 65: the el=1 `ball_large` (uid_315038), in pure
// free-fall (rot==0, ω==0 from f55→f64 — verified), grazes the right-side grass terrain slope
// and rebounds. The two engines SPLIT there:
//     f64 (bit-identical): pos(713.018,305.262) vel(-143.294,221.546)
//     f65 REPLICA : vel(-191.297, 166.779)
//     f65 NAPE4   : vel(-204.17 , 180.4  )   ← over-rebounds ~6.7% harder left
// This gate captures the REAL 2012 SWF answer (harness-p0sr.as, Ruffle/AVM2): vx −191.296 —
// i.e. the REPLICA is FAITHFUL to 2012 and nape-haxe4 2.0.22 is the OUTLIER. (So the live
// build is NOT under-rebounding; nape-haxe4's "carries the crate to the hole" is nape-haxe4's
// own newer-Nape restitution drift, exactly the feel-bug class the replica exists to kill.)
//
// Scene = the game's own terrain path (PhysicsBase.InitLines): the big poly_collide_grass line
// (Levels_Data.xml:2767-2775, 68 pts) → centroid-subtract → GeomPoly.triangularDecomposition()
// → 65 STATIC triangles, material poly_average (el 0, fric 0.5). The golden carries the centroid
// (bit-exact) + the triangle connectivity ([TRI] world-int triples), so we rebuild nape's EXACT
// triangle soup. Ball = solid circle r35, material football (el 1), at the f64 pre-state; the
// f64 ball is already 0.23px into edge (728,340)-(746,321) [triangle #19], so one step → f65.
// Combined restitution (1+0)/2 = 0.5. Ball moves 4.4px/frame ≪ r35 → discrete (no sweep).
//
// Bit-exact f65→f72. (f66+ slide crosses successive triangles; still bit-exact here because the
// replica never recenters polys — world verts = centroid + (P−centroid), same as AS3 nape.)
// =============================================================================
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0sr-sandyrebound.json', import.meta.url)), 'utf8'),
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

// --- centroid (bit-exact) of the grass line poly: "[P0SR] tris 65 centroid hi:lo hi:lo" ---
const cline = lines.find((l) => /^\[P0SR\] tris /.test(l))!.split(/\s+/);
const CX = toNum(norm(cline[4]));
const CY = toNum(norm(cline[5]));

// --- nape's triangle connectivity: "[TRI] k x0 y0 x1 y1 x2 y2" (world ints) ---
const TRIS: number[][] = lines
  .filter((l) => /^\[TRI\] /.test(l))
  .map((l) => l.split(/\s+/).slice(2).map(Number)); // [x0,y0,x1,y1,x2,y2]

// --- ball trajectory golden: "[P0SR] i x y rot vx vy" (bits) ---
interface G { x: string; y: string; r: string; vx: string; vy: string }
const gold: Record<string, G> = {};
for (const ln of lines) {
  const p = ln.split(/\s+/);
  if (p[0] !== '[P0SR]' || !/^\d+$/.test(p[1]) || !p[6]) continue;
  gold[p[1]] = { x: p[2], y: p[3], r: p[4], vx: p[5], vy: p[6] };
}

// poly_average: density 1, friction 0.5 (static=dyn=roll), elasticity 0; football: el 1, fric 0.1.
describe('P0SR — lvl-19 sandy-rebound f65 contact vs ORIGINAL Nape AS3', () => {
  it('el=1 ball grazes the grass slope → rebound matches 2012 (NOT nape-haxe4) bit-for-bit', () => {
    const w = new NapeReplica(1000);

    // Terrain: rebuild nape's exact triangle soup, local = worldInt − centroid (bit-exact to
    // AS3's InitLines), static body placed at the centroid.
    const terrain = w.createBody(true, CX, CY, 0, 0, 0);
    for (const t of TRIS) {
      w.addPolygon(
        terrain,
        [t[0] - CX, t[1] - CY, t[2] - CX, t[3] - CY, t[4] - CX, t[5] - CY],
        1, 0.5, 0.5, 0.0, 1, 15, false,
      );
    }
    w.finalizeBody(terrain, false);

    // Ball: ball_large solid circle r35, football material, at the f64 pre-state.
    const ball = w.createBody(false, 713.018, 305.262, 0, 0, 0);
    w.addCircle(ball, 0, 0, 35, 0.5, 0.1, 0.1, 1, 4, 15, false);
    w.finalizeBody(ball, false);
    w.setVel(ball, -143.294, 221.546);

    for (let i = 65; i <= 72; i++) {
      w.step(1 / 60, 10, 10);
      const g = gold[String(i)];
      const got: Record<string, string> = {
        x: hex16(w.getX(ball)), y: hex16(w.getY(ball)),
        r: hex16(w.getRotRad(ball)), vx: hex16(w.getVX(ball)), vy: hex16(w.getVY(ball)),
      };
      for (const f of ['x', 'y', 'r', 'vx', 'vy'] as const) {
        if (got[f] !== norm(g[f])) {
          throw new Error(`step ${i} ${f}: original=${toNum(norm(g[f]))} replica=${toNum(got[f])}`);
        }
      }
    }
  });
});
