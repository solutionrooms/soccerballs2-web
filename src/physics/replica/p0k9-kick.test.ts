// P0K9 — DIAGNOSTIC: Jon's live level-9 kick (the "break BOTH crates" bug).
// =============================================================================
// Jon's report: on the ORIGINAL, a direct full-power kick into the crate tower
// breaks the bottom crate AND the one above, across a WIDE aim window. On the
// REWRITE, only ONE crate breaks — aim a fraction low → bottom only; a fraction
// high → the one above only; NEVER both. So the rewrite forms ONE effective
// ball↔crate impact where the original forms TWO.
//
// Because the inbound flight is a free circle (bit-exact, no rotation feedback,
// no wall/floor deflection) and the settled tower is bit-exact, the ball arrives
// at the tower IDENTICALLY in both builds. So any difference is PURELY in the
// impact contact/solve — the cleanest possible isolation.
//
// Golden (harness-p0k9.as → original-goldens/p0k9-kick.json): the original Nape
// AS3, same scene + kick. Per frame it traces:
//   [P0K9] i  ball.x ball.y ball.vx ball.vy  c0 c1 c2 c3 c4
// where cK = Vec2(crateK.normalImpulse(ball).x, .y).length  — the GAME's break
// input (z DROPPED). Break iff cK / ballMass >= 150.
//
// At impact (golden frame 26): c0 = 120.7  AND  c1 = 144.2  → BOTH break.
// Jon's live rewrite: c0 ≈ 365, c1 = 0 → only the bottom breaks.
//
// This test rebuilds the harness scene + kick on NapeReplica and prints a
// side-by-side table over the impact window, so we can see:
//   (a) does the ball ARRIVE identically (trajectory bit-exact to impact)?
//   (b) at impact, does the replica give c1 EXACTLY 0 (H1: contact never
//       generated) or small-but-nonzero (H2: generated but starved by the solve)?
// =============================================================================
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0k9-kick.json', import.meta.url)), 'utf8'),
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

interface GK {
  i: number;
  bx: string; by: string; bvx: string; bvy: string;
  c: string[]; // 5 crate break-inputs (hi:lo)
}
const gold: GK[] = lines
  .filter((l) => l.startsWith('[P0K9] ') && !l.includes('DONE') && !l.includes('ERROR'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0K9] i bx by bvx bvy c0 c1 c2 c3 c4
    return { i: Number(p[1]), bx: p[2], by: p[3], bvx: p[4], bvy: p[5], c: p.slice(6, 11) };
  });

const AVG = [0.5, 0.1, 0.1, 0.2, 1, 0xffff, false] as const; // `average`
const FB = [0.5, 0.1, 0.1, 1.0, 1, 0xffff, false] as const; // `football`
const BOX = [-24, -20, 24, -20, 24, 20, -24, 20];

// Build the EXACT harness-p0k9 scene, settle the tower 10 frames, then return the
// world + crate handles (ball added by the caller, matching the harness order).
function buildTower(settleN: number) {
  const w = new NapeReplica(1000);
  const floor = w.createBody(true, 472, 439, 0, 0, 0);
  w.addPolygon(floor, [-120, -20, 120, -20, 120, 20, -120, 20], ...AVG);
  w.finalizeBody(floor, false);
  const crates: number[] = [];
  [399, 360, 321, 284, 247].forEach((cy) => {
    const h = w.createBody(false, 472, cy, 0, 0, 0);
    w.addPolygon(h, BOX, ...AVG);
    w.finalizeBody(h, false);
    crates.push(h);
  });
  const post = w.createBody(false, 472, 222, 89, 0, 0);
  w.addPolygon(post, [-6, -28, 6, -28, 6, 28, -6, 28], ...AVG);
  w.finalizeBody(post, false);
  const bA = w.createBody(false, 473, 180, 0, 0, 0);
  w.addCircle(bA, 0, 0, 35, ...FB);
  w.finalizeBody(bA, false);
  const bB = w.createBody(false, 479, 108, 0, 0, 0);
  w.addCircle(bB, 0, 0, 35, ...FB);
  w.finalizeBody(bB, false);
  for (let s = 0; s < settleN; s++) w.step(1 / 60, 10, 10);
  // crate sleep state (reach into the engine's body map — read-only diagnostic)
  const sleeping = crates.map((h) => Boolean((w as any).bodies?.get(h)?.sleeping));
  return { w, crates, sleeping };
}

// The GAME's per-crate break input: sqrt(x²+y²) of normalImpulse (z dropped).
function breakInput(w: NapeReplica, crate: number, ball: number): number {
  const [x, y] = w.normalImpulse(crate, ball);
  return Math.sqrt(x * x + y * y);
}

interface Row {
  i: number;
  bx: number; by: number; bvx: number; bvy: number;
  ni: number[]; // faithful normalImpulse Vec2 length per crate (what the ORIGINAL game reads)
  imp: (number | null)[]; // takeImpacts |jn| per crate THIS frame (what the LIVE shim reads), null = absent
  begin: boolean[]; // takeContacts BEGIN per crate THIS frame (what makes OnHit_Breakable fire)
}

function runKick(vy: number, settleN: number) {
  const { w, crates, sleeping } = buildTower(settleN);
  const ball = w.createBody(false, 110, 446, 0, 0, 0);
  w.addCircle(ball, 0, 0, 12, ...FB);
  w.finalizeBody(ball, false);
  w.setVel(ball, 798, vy);
  const ballMass = w.getMass(ball);
  const idxOf = (h: number) => crates.indexOf(h);
  const rows: Row[] = [];
  for (let i = 1; i <= 70; i++) {
    w.step(1 / 60, 10, 10);
    // Drain the engine buffers EXACTLY as the shim's dispatchEvents() does.
    const im = w.takeImpacts(); // [hA,hB,|jn|,nx,ny, ...]
    const cs = w.takeContacts(); // [hA,hB,sensorFlag, ...]
    const imp: (number | null)[] = [null, null, null, null, null];
    for (let k = 0; k + 4 < im.length; k += 5) {
      const a = im[k], b = im[k + 1], j = im[k + 2];
      const ci = a === ball ? idxOf(b) : b === ball ? idxOf(a) : -1;
      if (ci >= 0) imp[ci] = j; // shim returns Vec2(nx·j,ny·j).length === |j| (unit normal)
    }
    const begin = [false, false, false, false, false];
    for (let k = 0; k + 2 < cs.length; k += 3) {
      const a = cs[k], b = cs[k + 1];
      const ci = a === ball ? idxOf(b) : b === ball ? idxOf(a) : -1;
      if (ci >= 0) begin[ci] = true;
    }
    rows.push({
      i,
      bx: w.getX(ball), by: w.getY(ball), bvx: w.getVX(ball), bvy: w.getVY(ball),
      ni: crates.map((c) => breakInput(w, c, ball)),
      imp, begin,
    });
  }
  return { rows, ballMass, sleeping };
}

describe('P0K9 — level-9 kick: does the replica break BOTH crates? (diagnostic)', () => {
  // GREEN GATE: the engine breaks BOTH crates, bit-exact to the original.
  // The ball arrives bit-exact (free-flight circle) and at the impact frame BOTH the
  // faithful normalImpulse AND the shim's takeImpacts buffer report c0 and c1 above the
  // break threshold — matching the golden. So the engine + shim-buffer logic are NOT the
  // cause of Jon's live "only one crate breaks" bug; that divergence is live-side
  // (level-9 scene construction or the break handler / dispatch), flagged to haxe-port.
  it('ENGINE breaks BOTH crates, bit-exact vs original (golden p0k9-kick, vy=-381)', () => {
    const { rows, ballMass } = runKick(-381, 10); // harness/golden settle = 10 frames
    const THR = 150 * ballMass;
    // (1) trajectory bit-exact through the impact frame (identical arrival)
    for (const g of gold) {
      const r = rows[g.i - 1];
      if (g.i > 26) break;
      const got = [hex16(r.bx), hex16(r.by), hex16(r.bvx), hex16(r.bvy)];
      const want = [norm(g.bx), norm(g.by), norm(g.bvx), norm(g.bvy)];
      got.forEach((h, k) => {
        if (h !== want[k]) throw new Error(`trajectory diverged at frame ${g.i} field ${k}`);
      });
    }
    // (2) at impact (frame 26) both crate break-inputs match the golden bit-for-bit
    const g26 = gold[25];
    const r26 = rows[25];
    for (const k of [0, 1] as const) {
      if (hex16(r26.ni[k]) !== norm(g26.c[k])) {
        throw new Error(
          `crate c${k} break-input mismatch at frame 26: ` +
            `original=${toNum(norm(g26.c[k]))} replica=${r26.ni[k]}`,
        );
      }
    }
    // (3) both clear the break threshold → the engine breaks BOTH crates
    for (const k of [0, 1] as const) {
      if (!(r26.ni[k] >= THR)) throw new Error(`engine failed to break crate c${k} (NI=${r26.ni[k]} < ${THR})`);
    }
  });

  // ROOT CAUSE of the live "only one crate breaks": the level-9 crates each carry TWO
  // collision shapes (confirmed in BOTH the replica AND nape-haxe4 builds via sb2DynShapes),
  // so a ball↔crate body-pair produces TWO contact arbiters. The faithful break input is the
  // SUM over them — which `engine.normalImpulse(ref, other)` does (it loops every arbiter of
  // the pair). But the shim buffers impulses in a Map keyed by body-pair
  // (Space.hx `_impulse.set(pairKey(ha,hb), …)` fed by `takeImpacts`), so the 2nd arbiter
  // OVERWRITES the 1st; when that arbiter's jn≈0 the reported impulse collapses to ~0 → the
  // crate never breaks. nape-haxe4's `Body.normalImpulse` sums, so the old build broke both.
  // FIX (shim, flagged to haxe-port): `Space.impulseBetween` must call `engine.normalImpulse`
  // instead of reading the per-pair `_impulse` map. This gate proves the engine method sums.
  it('engine.normalImpulse SUMS multi-shape arbiters (a per-body-pair map would drop one)', () => {
    const w = new NapeReplica(1000);
    const AVGm = [0.5, 0.1, 0.1, 0.2, 1, 0xffff, false] as const;
    const FBm = [0.5, 0.1, 0.1, 1.0, 1, 0xffff, false] as const;
    const BOXv = [-24, -20, 24, -20, 24, 20, -24, 20];
    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...AVGm);
    w.finalizeBody(floor, false);
    const crate = w.createBody(false, 200, 361, 0, 0, 0);
    w.addPolygon(crate, BOXv, ...AVGm); // shape 1
    w.addPolygon(crate, BOXv, ...AVGm); // shape 2 (two-shape crate, as in level 9)
    w.finalizeBody(crate, false);
    const ball = w.createBody(false, 120, 361, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...FBm);
    w.finalizeBody(ball, false);
    w.setVel(ball, 700, 0);
    let summed = 0;
    let mapEmulated = 0;
    for (let i = 1; i <= 10; i++) {
      w.step(1 / 60, 10, 10);
      const im = w.takeImpacts();
      w.takeContacts();
      const [x, y] = w.normalImpulse(crate, ball);
      const ni = Math.sqrt(x * x + y * y);
      // emulate the shim's per-body-pair map (later entry overwrites earlier)
      let surv: number | null = null;
      for (let k = 0; k + 4 < im.length; k += 5) {
        if ((im[k] === ball && im[k + 1] === crate) || (im[k] === crate && im[k + 1] === ball)) surv = im[k + 2];
      }
      if (ni > summed) summed = ni;
      if (surv != null && surv > mapEmulated) mapEmulated = surv;
    }
    const THR = 150 * w.getMass(ball);
    // The faithful summed impulse breaks the crate; the overwriting map (the live shim) does not.
    if (!(summed >= THR)) throw new Error(`normalImpulse should break the 2-shape crate (got ${summed} < ${THR})`);
    if (mapEmulated >= THR) {
      throw new Error(`expected the per-pair map to UNDER-report (drop an arbiter); got ${mapEmulated} ≥ ${THR}`);
    }
  });
});
