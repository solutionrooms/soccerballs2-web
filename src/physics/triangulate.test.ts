import { describe, it, expect } from 'vitest';
import { triangulate } from './world';
import objectsJson from '../data/objects.json';

function polyArea(v: number[]): number {
  let a = 0;
  const n = v.length / 2;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    a += v[i * 2] * v[j * 2 + 1] - v[j * 2] * v[i * 2 + 1];
  }
  return Math.abs(a) / 2;
}
function triArea(t: [number, number][][]): number {
  return t.reduce(
    (s, [a, b, c]) => s + Math.abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])) / 2,
    0,
  );
}

describe('object polygon triangulation', () => {
  // The goal post colliders are concave; a fan triangulation over-covers them,
  // leaving the actual collider with gaps the ball tunnels through (scoring
  // from behind the net). Ear-clipping must cover exactly the polygon area.
  const physobjs = objectsJson.physobjs as Record<
    string,
    { bodies: { shapes: { vertices?: number[]; colCat: number }[] }[] }
  >;

  for (const name of ['goal', 'goal2']) {
    it(`${name} solid collider triangles cover the polygon area (no gaps)`, () => {
      const shape = physobjs[name].bodies[0].shapes.find((s) => s.colCat !== 0 && s.vertices);
      expect(shape?.vertices).toBeTruthy();
      const verts = shape!.vertices!;
      const tris = triangulate(verts);
      expect(tris.length).toBeGreaterThan(0);
      // ear-clip total area equals the polygon area within rounding
      expect(triArea(tris)).toBeCloseTo(polyArea(verts), 0);
    });
  }
});
