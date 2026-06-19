// REGRESSION (behavioural, not a golden) — guards the replica side of the live
// "-Dreplica ball passes through terrain" bug. The game builds terrain as ONE static
// Body holding MANY triangles (GeomPoly.triangularDecomposition of a concave
// Catmull-Rom loop). Every shipped replica test uses a single 4-vert rectangle floor,
// so multi-triangle, concave-derived terrain was UNTESTED on the replica. This proves
// the replica DOES collide a falling ball against a well-formed triangulated terrain
// body — i.e. the fall-through bug is in the geometry/setup reaching the replica
// (the shim), not in the replica's collision math. See sb2_developer_messages.md.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

// material tuple, same as p0wk: density, friction, rolling, elasticity, colCat, colMask, sensor
const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

// A wavy terrain surface (a shallow valley), y-down screen coords. base is the flat bottom.
const XS = [0, 70, 140, 210, 280, 350, 420, 490, 560, 630, 700];
const BASE = 520;
const height = (x: number): number => 380 + 60 * Math.pow((x - 350) / 350, 2); // 380 centre → 440 edges

// Decompose the heightfield into convex triangles, two per column (TL,TR,BR)+(TL,BR,BL).
// Force POSITIVE shoelace so winding matches the replica's working rectangle floor.
const shoelace = (ax: number, ay: number, bx: number, by: number, cx: number, cy: number): number =>
  ax * (by - cy) + bx * (cy - ay) + cx * (ay - by);
const tri = (ax: number, ay: number, bx: number, by: number, cx: number, cy: number): number[] =>
  shoelace(ax, ay, bx, by, cx, cy) >= 0 ? [ax, ay, bx, by, cx, cy] : [ax, ay, cx, cy, bx, by];

function terrainTriangles(): number[][] {
  const tris: number[][] = [];
  for (let i = 0; i < XS.length - 1; i++) {
    const xl = XS[i];
    const xr = XS[i + 1];
    tris.push(tri(xl, height(xl), xr, height(xr), xr, BASE)); // TL,TR,BR
    tris.push(tri(xl, height(xl), xr, BASE, xl, BASE)); // TL,BR,BL
  }
  return tris;
}

describe('ball vs triangulated terrain (the -Dreplica fall-through bug)', () => {
  it('rests on a well-formed triangle decomposition (replica supports terrain bodies)', () => {
    const w = new NapeReplica(1000);
    const ground = w.createBody(true, 0, 0, 0, 0, 0); // static, at origin; verts are absolute
    const tris = terrainTriangles();
    for (const t of tris) w.addPolygon(ground, t, ...MAT);
    w.finalizeBody(ground, false);
    const ball = w.createBody(false, 345, 100, 0, 0, 0); // above column [280,350], interior
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);
    for (let i = 0; i < 180; i++) w.step(1 / 60, 10, 10);
    const finalY = w.getY(ball);
    // surface at x=345 ≈ 380.05; ball radius 12 → rests near 368. If collision is broken
    // the ball blows past BASE(520) and keeps falling.
    // eslint-disable-next-line no-console
    console.log(`[terrain] ${tris.length} triangles — ball settled at y=${finalY.toFixed(2)} (rest≈368, base=520)`);
    expect(finalY, 'ball fell through the triangulated terrain').toBeLessThan(420);
    expect(finalY).toBeGreaterThan(340);
  });
});
