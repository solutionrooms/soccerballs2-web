// geom-triangulate.ts — faithful port of 2012 nape's GeomPoly.triangularDecomposition.
// ============================================================================
// WHY: lvl-19 root cause — the shim triangulated terrain with ear-clipping, but 2012 nape uses
// MONOTONE decomposition + monotone triangulation, which produces a DIFFERENT triangle set. Terrain
// triangles are separate collision shapes, so the cover choice changes which edge a body contacts
// (the lvl-19 crate caught a phantom notch and tipped OUT instead of into the pit). The replica must
// feed the engine the SAME triangles 2012 produces, so the faithful triangulator lives here (it IS
// 2012 nape) and the shim's GeomPoly delegates to it.
//
// Pipeline (nape/geom/GeomPoly.as:376): ZPP_Monotone.decompose(verts).extract_partitions() → for
// each monotone piece ZPP_Triangular.triangulate(piece).extract() → triangles.
//
// FAITHFULNESS: `decompose` (which diagonals are added) and `triangulateMonotone` (which triangles
// per piece) are ported faithfully — they fix the triangle SET. Face extraction uses a standard
// angular walk (the faces are determined by the subdivision, so any correct walk yields the same
// set). Gated bit-exact (as a set) vs original-goldens/tri-geompoly.json captured from the SWF.
// ============================================================================

class PV {
  x: number;
  y: number;
  prev!: PV;
  next!: PV;
  helper: PV | null = null;
  type = 0; // 0 START, 1 END, 2 MERGE, 3 SPLIT, 4 REGULAR
  diagonals: PV[] = [];
  constructor(x: number, y: number) { this.x = x; this.y = y; }
}

// ZPP_Monotone.below — for DISTINCT vertices (after collinear/dup removal there are no coincident
// points, so the bisector tie-break path is never reached): y then x.
function below(a: PV, b: PV): boolean {
  if (a.y < b.y) return true;
  if (a.y > b.y) return false;
  return a.x < b.x;
}

// ZPP_PartitionVertex.rightdistance
function rightdistance(p: PV, q: PV): number {
  const flip = p.next.y > p.y;
  const ax = p.next.x - p.x, ay = p.next.y - p.y;
  const bx = q.x - p.x, by = q.y - p.y;
  return (flip ? -1 : 1) * (by * ax - bx * ay);
}

// ZPP_PartitionVertex.vert_lt — is edge p (p→p.next) left of vertex q?
function vert_lt(p: PV, q: PV): boolean {
  if (q === p || q === p.next) return true;
  if (p.y === p.next.y) {
    const lo = Math.min(p.x, p.next.x);
    return lo <= q.x;
  }
  return rightdistance(p, q) <= 0;
}

// ZPP_PartitionVertex.edge_lt — total order on edges for the sweep status set.
function edge_lt(p: PV, q: PV): boolean {
  if (p === q && p.next === q.next) return false;
  if (p === q.next) return !vert_lt(p, q);
  if (q === p.next) return vert_lt(q, p);
  if (p.y === p.next.y) {
    if (q.y === q.next.y) return Math.max(p.x, p.next.x) > Math.max(q.x, q.next.x);
    return rightdistance(q, p) > 0;
  }
  const d = rightdistance(p, q);
  const lp = d < 0;
  const lq = rightdistance(p, q.next) < 0;
  if (lp === lq) return lp;
  if (q.y === q.next.y) return d > 0;
  return rightdistance(q, p) >= 0;
}

function left_vertex(v: PV): boolean {
  const p = v.prev;
  return p.y > v.y || (p.y === v.y && v.next.y < v.y);
}

// ---- build the doubly-linked ring, winding-normalized + collinear/dup removed ----
function buildRing(flat: number[]): PV | null {
  const n = flat.length >> 1;
  if (n < 3) return null;
  // signed area (the 2x form used by nape: Σ x·(next.y − prev.y))
  let area2 = 0;
  for (let i = 0; i < n; i++) {
    const px = flat[((i - 1 + n) % n) * 2 + 1];
    const ny = flat[((i + 1) % n) * 2 + 1];
    area2 += flat[i * 2] * (ny - px);
  }
  const order: number[] = [];
  for (let i = 0; i < n; i++) order.push(i);
  if (area2 <= 0) order.reverse(); // normalize so internal winding is consistent (area2 > 0)
  const verts: PV[] = order.map((i) => new PV(flat[i * 2], flat[i * 2 + 1]));
  for (let i = 0; i < verts.length; i++) {
    verts[i].next = verts[(i + 1) % verts.length];
    verts[i].prev = verts[(i - 1 + verts.length) % verts.length];
  }
  let head: PV = verts[0];
  // remove duplicate (within 1e-8) and collinear vertices (ZPP_PartitionedPoly.remove_collinear)
  const eq = (a: PV, b: PV) => { const dx = a.x - b.x, dy = a.y - b.y; return dx * dx + dy * dy < 1e-8; };
  let v = head;
  let first = true;
  let count = verts.length;
  while ((first || v !== head) && count > 3) {
    first = false;
    if (eq(v, v.next)) { // duplicate → drop v
      if (v === head) head = v.next;
      v.prev.next = v.next; v.next.prev = v.prev; count--; v = v.next; continue;
    }
    let p = v.prev;
    while (eq(v, p)) p = p.prev;
    const ax = v.x - p.x, ay = v.y - p.y;
    const bx = v.next.x - v.x, by = v.next.y - v.y;
    if (by * ax - bx * ay !== 0) { v = v.next; }
    else { // collinear → drop v
      if (v === head) head = v.next;
      v.prev.next = v.next; v.next.prev = v.prev; count--; v = v.next;
    }
  }
  return head;
}

function ringToArray(head: PV): PV[] {
  const out: PV[] = []; let v = head;
  do { out.push(v); v = v.next; } while (v !== head);
  return out;
}

// ---- ZPP_Monotone.decompose: add make-monotone diagonals ----
function addDiagonal(a: PV, b: PV) { a.diagonals.push(b); b.diagonals.push(a); }

function decompose(head: PV): void {
  const verts = ringToArray(head);
  for (const v of verts) {
    const ax = v.next.x - v.x, ay = v.next.y - v.y;
    const bx = v.prev.x - v.x, by = v.prev.y - v.y;
    const convex = by * ax - bx * ay > 0;
    v.type = below(v.prev, v)
      ? (below(v.next, v) ? (convex ? 0 : 3) : 4)
      : (below(v, v.next) ? (convex ? 1 : 2) : 4);
  }
  // sweep order: descending (y, x) — nape sorts by `above` (= below(b,a)) and pops head-first
  const order = verts.slice().sort((a, b) => (a.y !== b.y ? b.y - a.y : b.x - a.x));
  // edge status: array kept sorted ascending by edge_lt; helper tracked per edge-vertex
  const status: PV[] = [];
  const insert = (e: PV) => { let i = 0; while (i < status.length && edge_lt(status[i], e)) i++; status.splice(i, 0, e); };
  const removeEdge = (e: PV) => { const i = status.indexOf(e); if (i >= 0) status.splice(i, 1); };
  // edge directly left of v: first edge in ascending order with !vert_lt(edge, v)
  const leftEdge = (v: PV): PV | null => { for (const e of status) if (!vert_lt(e, v)) return e; return null; };

  for (const v of order) {
    switch (v.type) {
      case 0: // START
        v.helper = v; insert(v); break;
      case 1: { // END
        const e = v.prev;
        if (e.helper && e.helper.type === 2) addDiagonal(v, e.helper);
        removeEdge(e); break;
      }
      case 2: { // MERGE
        const e = v.prev;
        if (e.helper && e.helper.type === 2) addDiagonal(v, e.helper);
        removeEdge(e);
        const ej = leftEdge(v);
        if (ej) { if (ej.helper && ej.helper.type === 2) addDiagonal(v, ej.helper); ej.helper = v; }
        break;
      }
      case 3: { // SPLIT
        const ej = leftEdge(v);
        if (ej) { if (ej.helper) addDiagonal(v, ej.helper); ej.helper = v; }
        insert(v); v.helper = v; break;
      }
      case 4: { // REGULAR
        if (left_vertex(v)) {
          const e = v.prev;
          if (e.helper && e.helper.type === 2) addDiagonal(v, e.helper);
          removeEdge(e); insert(v); v.helper = v;
        } else {
          const ej = leftEdge(v);
          if (ej) { if (ej.helper && ej.helper.type === 2) addDiagonal(v, ej.helper); ej.helper = v; }
        }
        break;
      }
    }
  }
}

// ---- extract faces (monotone pieces / triangles) from the polygon + diagonals, via a DCEL ----
// Build all directed half-edges (boundary v↔v.next and every diagonal, both ways), sort each
// vertex's outgoing edges by angle, and trace faces: at the head of u→v, the next face-edge keeps
// the interior on the left — it's the neighbour immediately CLOCKWISE from the reverse (v→u), i.e.
// the previous entry in the CCW-sorted ring around v. Every interior face is traced exactly once;
// the lone outer face (opposite orientation to the polygon ring) is discarded by area sign.
function shoelace(face: PV[]): number {
  let a = 0; const n = face.length;
  for (let i = 0; i < n; i++) { const p = face[i], q = face[(i + 1) % n]; a += p.x * q.y - q.x * p.y; }
  return a;
}
function extractFaces(head: PV): PV[][] {
  const verts = ringToArray(head);
  const idx = new Map<PV, number>(); verts.forEach((v, i) => idx.set(v, i));
  // CCW-sorted neighbour ring per vertex (boundary + diagonals, deduped)
  const adj = new Map<PV, PV[]>();
  for (const v of verts) {
    const nb = [...new Set<PV>([v.next, v.prev, ...v.diagonals])];
    nb.sort((p, q) => Math.atan2(p.y - v.y, p.x - v.x) - Math.atan2(q.y - v.y, q.x - v.x));
    adj.set(v, nb);
  }
  // orientation of the outer ring (to keep interior faces, discard the outer one)
  const ringArea = shoelace(verts);
  const ringSign = ringArea > 0 ? 1 : -1;
  const key = (a: PV, b: PV) => idx.get(a)! + '>' + idx.get(b)!;
  const visited = new Set<string>();
  const faces: PV[][] = [];
  for (const sv of verts) {
    for (const sw of adj.get(sv)!) {
      if (visited.has(key(sv, sw))) continue;
      const face: PV[] = [];
      let u = sv, v = sw;
      let guard = verts.length * 6 + 12;
      while (guard-- > 0) {
        visited.add(key(u, v));
        face.push(u);
        const ring = adj.get(v)!;
        const j = ring.indexOf(u);                 // reverse edge v→u
        const w = ring[(j - 1 + ring.length) % ring.length]; // immediately clockwise = next around face
        u = v; v = w;
        if (u === sv && v === sw) break;
      }
      if (face.length >= 3 && (shoelace(face) > 0 ? 1 : -1) === ringSign) faces.push(face);
    }
  }
  return faces;
}

// ---- monotone-polygon triangulation (standard stack algorithm, emits triangles directly) ----
// Input: a y-monotone face in ring order. Output: triangles [ax,ay,bx,by,cx,cy]. The triangle SET
// is determined by the algorithm (matches nape's ZPP_Triangular for a given monotone piece).
function triangulateMonotone(face: PV[]): number[][] {
  const n = face.length;
  if (n < 3) return [];
  if (n === 3) return [[face[0].x, face[0].y, face[1].x, face[1].y, face[2].x, face[2].y]];
  // sweep order along the monotone (y) axis: top = min by below, bottom = max
  const sorted = face.slice().sort((a, b) => (below(a, b) ? -1 : below(b, a) ? 1 : 0));
  const top = sorted[0], bot = sorted[n - 1];
  // chain side of each vertex: 0 via next-chain from top, 1 via prev-chain (top/bot are on both)
  const idx = new Map<PV, number>(); face.forEach((v, i) => idx.set(v, i));
  const fnext = (v: PV) => face[(idx.get(v)! + 1) % n];
  const fprev = (v: PV) => face[(idx.get(v)! - 1 + n) % n];
  const side = new Map<PV, number>();
  for (let v = fnext(top); v !== bot; v = fnext(v)) side.set(v, 0);
  for (let v = fprev(top); v !== bot; v = fprev(v)) side.set(v, 1);
  const tris: number[][] = [];
  const emit = (a: PV, b: PV, c: PV) => tris.push([a.x, a.y, b.x, b.y, c.x, c.y]);
  const stack: PV[] = [sorted[0], sorted[1]];
  for (let j = 2; j < n - 1; j++) {
    const u = sorted[j];
    const su = side.get(u), st = side.get(stack[stack.length - 1]);
    if (su !== st) {
      // opposite chain: connect u to every vertex on the stack
      while (stack.length > 1) { const a = stack.pop()!; emit(u, a, stack[stack.length - 1]); }
      stack.pop();
      stack.push(sorted[j - 1]);
      stack.push(u);
    } else {
      // same chain: pop while the diagonal u→stacktop stays inside (convex turn for this chain)
      let last = stack.pop()!;
      while (stack.length > 0) {
        const w = stack[stack.length - 1];
        const cross = (last.x - u.x) * (w.y - u.y) - (last.y - u.y) * (w.x - u.x);
        const convex = su === 1 ? cross > 0 : cross < 0;
        if (!convex) break;
        emit(u, last, w); last = stack.pop()!;
      }
      stack.push(last); stack.push(u);
    }
  }
  // bottom vertex closes the rest
  const u = bot;
  while (stack.length > 1) { const a = stack.pop()!; emit(u, a, stack[stack.length - 1]); }
  return tris;
}

/** DEBUG: the monotone pieces from decompose+face-extraction (before triangulation), for gating
 *  against nape's GeomPoly.monotoneDecomposition(). Each piece is a list of [x,y]. */
export function _monoPieces(flat: number[]): number[][][] {
  const head = buildRing(flat);
  if (head === null) return [];
  decompose(head);
  return extractFaces(head).map((face) => face.map((v) => [v.x, v.y]));
}

/** Faithful 2012 nape GeomPoly.triangularDecomposition. Input flat [x0,y0,x1,y1,...]; returns an
 *  array of triangles, each [ax,ay,bx,by,cx,cy]. Order is not guaranteed to match nape; the SET is. */
export function triangulate(flat: number[]): number[][] {
  const head = buildRing(flat);
  if (head === null) return [];
  decompose(head);
  const pieces = extractFaces(head);
  const tris: number[][] = [];
  for (const piece of pieces) tris.push(...triangulateMonotone(piece));
  return tris;
}
