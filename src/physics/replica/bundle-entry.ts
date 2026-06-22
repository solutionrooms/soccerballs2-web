// Bundle entry — exposes the UNCHANGED NapeReplica on the global scope so the
// Haxe game (compiled to JS) can construct it through a JS extern. Built with
// esbuild to haxe-port/.../nape-replica.js. This file does NOT modify nape-core.ts;
// the bit-exact engine ships verbatim.
import { NapeReplica } from './nape-core';
import { triangulate } from './geom-triangulate';

// Faithful 2012 nape GeomPoly.triangularDecomposition (monotone, NOT ear-clipping). The shim's
// nape.geom.GeomPoly.triangularDecomposition delegates here so terrain is triangulated the way 2012
// does (fixed lvl-19: ear-clipping produced a different tri set → the crate caught a phantom pit-edge
// notch and tipped OUT). Static on the global NapeReplica: NapeReplica.triangulate(flat) → tris.
//   in:  flat verts of one (possibly concave) outline, [x0,y0,x1,y1,...]
//   out: array of triangles, each [ax,ay,bx,by,cx,cy]. Triangle SET matches nape bit-exact.
(NapeReplica as unknown as { triangulate: typeof triangulate }).triangulate = triangulate;

(globalThis as unknown as { NapeReplica: typeof NapeReplica }).NapeReplica = NapeReplica;
