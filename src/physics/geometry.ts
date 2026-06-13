// Engine-neutral geometry helpers shared by the physics layer and renderers.
import earcut from 'earcut';

/**
 * Ear-clip triangulation of a flattened [x0,y0,x1,y1,...] outline.
 * Degenerate slivers are dropped; winding is normalized CCW (positive shoelace
 * area in screen space). Used for terrain decomposition and golden tests.
 */
export function triangulate(points: number[]): [number, number][][] {
  const indices = earcut(points);
  const tris: [number, number][][] = [];
  for (let i = 0; i < indices.length; i += 3) {
    const tri: [number, number][] = [0, 1, 2].map((k) => {
      const idx = indices[i + k];
      return [points[idx * 2], points[idx * 2 + 1]] as [number, number];
    });
    // signed area: skip slivers, normalize winding
    const area =
      (tri[1][0] - tri[0][0]) * (tri[2][1] - tri[0][1]) -
      (tri[2][0] - tri[0][0]) * (tri[1][1] - tri[0][1]);
    if (Math.abs(area) < 1) continue;
    if (area > 0) tri.reverse();
    tris.push(tri);
  }
  return tris;
}
