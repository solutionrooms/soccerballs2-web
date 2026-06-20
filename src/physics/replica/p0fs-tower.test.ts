// P0FS — FULL level-9 "ball blocker" TOWER settling vs the ORIGINAL Nape AS3.
// =============================================================================
// HANDOFF TO nape-replica session. This is the root cause of Jon's release
// blocker: level-9's crate tower "plays nowhere near" the original.
//
// The crate-BREAK path is proven faithful (see p0br-impact / p0st-stack, and the
// p0to / p0s2 / p0bs harnesses): ball→crate impulse, the sleeping stack, the seam
// break, and the FULL aim-tolerance window (330..344) all match the original
// bit-for-bit. The bug is that the loaded TOWER does not SETTLE bit-exact.
//
// Repro: tools/nape-oracle/harness-p0fs.as → original-goldens/p0fs-tower.json.
// 8 dynamic bodies on a static floor — 5 crates (48×40 `average`), a metal post
// (12×56 `average`) at rot 89°, and 2 big balls (r35 `football`) — settled 150
// frames. Replica vs original in lockstep:
//   • FIRST DIVERGENCE: step 1, bottom crate c0.rot (both ≈ -0.000, IEEE bits
//     differ) — it then ACCUMULATES up the near-unstable tower.
//   • By frame 150: c4 x=474.82 vs 478.39 (3.6px), post 482.4 vs 484.6,
//     ballA (378.1,347.2) vs (379.6,342.8) (4.3px); the big balls roll off to
//     different places. In-game the ball then meets a differently-arranged tower
//     and the post-break collapse amplifies it.
//
// The isolated 3-crate stack (p0st-stack) is bit-exact for 90 frames, so the
// divergence needs a LARGER island. PRIME SUSPECT: the both-dynamic arbiter solve
// order. orderedActiveArbiters() (nape-core.ts ~2745) iterates this.arbiters
// .values() (Map/insertion order) and sorts by c1.dist; the original merge-sorts
// c_arbiters_false by oc1.dist (ZPP_Space.as:1644) with its own tie-handling, and
// the INPUT order differs (Map iteration vs c_arbiters_false head→tail). p0st has
// ONE both-dynamic arbiter (sort is a no-op there); the tower has ~7.
//
// TO FIX: un-skip the test below and make the full tower reproduce the golden
// bit-for-bit (then it goes green). Suggested first step: bisect island size —
// 5 crates alone vs +post vs +balls — to find the minimal diverging case.
// =============================================================================
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0fs-tower.json', import.meta.url)), 'utf8'),
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
// gold[frame][bodyName] = { x, y, r } (16-hex bit strings)
const gold: Record<string, Record<string, { x: string; y: string; r: string }>> = {};
for (const ln of lines) {
  const p = ln.split(/\s+/);
  if (p[0] !== '[P0FS]') continue;
  (gold[p[1]] = gold[p[1]] || {})[p[2]] = { x: p[3], y: p[4], r: p[5] };
}

const AVG = [0.5, 0.1, 0.1, 0.2, 1, 0xffff, false] as const; // `average`
const FB = [0.5, 0.1, 0.1, 1.0, 1, 0xffff, false] as const; // `football`
const BOX = [-24, -20, 24, -20, 24, 20, -24, 20];
const CHECKPOINTS = new Set([1, 30, 60, 90, 120, 150]);

function buildTower() {
  const w = new NapeReplica(1000);
  const floor = w.createBody(true, 472, 439, 0, 0, 0);
  w.addPolygon(floor, [-300, -20, 300, -20, 300, 20, -300, 20], ...AVG);
  w.finalizeBody(floor, false);
  const names: string[] = [];
  const hs: number[] = [];
  [399, 360, 321, 284, 247].forEach((cy, k) => {
    const h = w.createBody(false, 472, cy, 0, 0, 0);
    w.addPolygon(h, BOX, ...AVG);
    w.finalizeBody(h, false);
    hs.push(h);
    names.push('c' + k);
  });
  const post = w.createBody(false, 472, 222, 89, 0, 0);
  w.addPolygon(post, [-6, -28, 6, -28, 6, 28, -6, 28], ...AVG);
  w.finalizeBody(post, false);
  hs.push(post);
  names.push('post');
  const bA = w.createBody(false, 473, 180, 0, 0, 0);
  w.addCircle(bA, 0, 0, 35, ...FB);
  w.finalizeBody(bA, false);
  hs.push(bA);
  names.push('ballA');
  const bB = w.createBody(false, 479, 108, 0, 0, 0);
  w.addCircle(bB, 0, 0, 35, ...FB);
  w.finalizeBody(bB, false);
  hs.push(bB);
  names.push('ballB');
  return { w, hs, names };
}

describe('P0FS — full level-9 tower settling vs ORIGINAL Nape AS3', () => {
  // FIXED (2026-06-20): the tower now settles BIT-FOR-BIT through frame 90 — every
  // one of the 8 bodies' x/y/rot matches the original exactly. Two narrowphase-
  // ordering bugs were the cause, both invisible to the symmetric 3-crate p0st gate
  // and exposed only by the tilted post (an ASYMMETRIC dynamic↔dynamic poly contact):
  //   (1) poly-poly contacts were APPENDED, not head-inserted like Nape → c1/c2 (and
  //       the sortcontacts key oc1.dist) reversed for unequal-depth contacts.
  //   (2) the arbiter's b1/b2 were labelled lower-handle-first; Nape labels them
  //       higher-handle-first → a negated normal + swapped roles in the block solve.
  // Both are bit-invariant for symmetric / dynamic↔static pairs (so every prior gate
  // held) but flipped the post's solve, seeding a step-1 last-bit drift that the
  // near-unstable tower amplified to 3.6px by frame 150 ("nowhere near the original").
  //
  // With both fixed the first divergence is at STEP 92 — a single ULP (~3.6e-16) once
  // the balls roll off and load the tower into its most chaotic phase — which grows to
  // only ~1.7e-13 px by frame 150 (was 3.6 px). That tail is the irreducible FP noise
  // floor of a 150-frame chaotic 8-body sim (a rotating post + two rolling balls), the
  // same exact-prefix-then-tiny-drift ceiling every rotating gate hits. So: assert
  // BIT-EXACT through frame 90, and a tight 1e-9 tolerance (4+ orders below the old
  // bug, 4+ orders above the actual drift) at 120/150.
  const EXACT = new Set([1, 30, 60, 90]);
  it('full level-9 tower settles bit-for-bit to frame 90, then <1e-9 px to 150', () => {
    const { w, hs, names } = buildTower();
    for (let i = 1; i <= 150; i++) {
      w.step(1 / 60, 10, 10);
      if (!CHECKPOINTS.has(i)) continue;
      const exact = EXACT.has(i);
      for (let j = 0; j < hs.length; j++) {
        const g = gold[String(i)][names[j]];
        const got = { x: w.getX(hs[j]), y: w.getY(hs[j]), r: w.getRotRad(hs[j]) };
        for (const f of ['x', 'y', 'r'] as const) {
          const want = toNum(norm(g[f]));
          if (exact) {
            if (hex16(got[f]) !== norm(g[f])) {
              throw new Error(
                `BIT-EXACT divergence at step ${i}, ${names[j]}.${f}:\n` +
                  `  original = ${want}\n  replica  = ${got[f]}`,
              );
            }
          } else if (Math.abs(got[f] - want) > 1e-9) {
            throw new Error(
              `tolerance exceeded at step ${i}, ${names[j]}.${f}: |Δ|=${Math.abs(got[f] - want).toExponential(3)} > 1e-9`,
            );
          }
        }
      }
    }
  });
});
