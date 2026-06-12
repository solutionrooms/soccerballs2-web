// Terrain polygon rendering: texture-pattern fill clipped to the line polygon
// (the original pre-rasterized triangulated fills from the Fill/FillSoil
// texture pages), plus the FillEdge/FillSoilEdge strip along the outline.
import type { Atlas } from '../render/atlas';
import type { LoadedLine } from './level-loader';
import { triangulate } from '../physics/world';


const patternCache = new Map<string, CanvasPattern | null>();

function getPattern(ctx: CanvasRenderingContext2D, atlas: Atlas, clip: string, frame: number): CanvasPattern | null {
  const key = `${clip}#${frame}`;
  let p = patternCache.get(key);
  if (p !== undefined) return p;
  const f = atlas.frame(clip, frame);
  const page = f ? atlas.page(f.page) : undefined;
  if (!f || !page) {
    patternCache.set(key, null);
    return null;
  }
  const off = document.createElement('canvas');
  off.width = f.w;
  off.height = f.h;
  off.getContext('2d')!.drawImage(page, f.x, f.y, f.w, f.h, 0, 0, f.w, f.h);
  p = ctx.createPattern(off, 'repeat');
  patternCache.set(key, p);
  return p;
}

// triangulation cache (the original pre-rasterized once per level load)
const triCache = new WeakMap<LoadedLine, [number, number][][]>();

export function renderTerrainLine(
  ctx: CanvasRenderingContext2D,
  atlas: Atlas,
  line: LoadedLine,
): void {
  const pts = line.points;
  if (pts.length < 6) return;
  const pattern = getPattern(ctx, atlas, line.go.dobjName, line.go.frame);

  // Ear-clip triangles exactly like the original's GeomPoly decomposition —
  // a raw path fill breaks on the self-touching cave/island outlines.
  let tris = triCache.get(line);
  if (!tris) {
    tris = triangulate(pts);
    triCache.set(line, tris);
  }

  ctx.save();
  ctx.beginPath();
  for (const tri of tris) {
    ctx.moveTo(tri[0][0], tri[0][1]);
    ctx.lineTo(tri[1][0], tri[1][1]);
    ctx.lineTo(tri[2][0], tri[2][1]);
    ctx.closePath();
  }
  if (pattern) {
    ctx.fillStyle = pattern;
  } else {
    ctx.fillStyle = line.go.dobjName === 'FillSoil' ? '#8a5a2b' : '#3f8f33';
  }
  ctx.fill();
  ctx.restore();

  // TODO(M5): faithful surface detail — the original draws grass_rough tuft
  // sprites along up-facing segments (PreRenderPhysicsLineObject_Movable_
  // GrassSurface) and uses the FillEdge/FillSoilEdge 256x256 tiles as banded
  // fills, NOT as outline strips. Port PreRenderPhysicsLineObject_Static
  // before re-adding edge art here.
}
