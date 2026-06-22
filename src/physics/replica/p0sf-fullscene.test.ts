// P0SF — lvl-19 FULL-SCENE: does the REPLICA ENGINE (V8) reproduce real 2012 (Ruffle/AVM2)?
// =============================================================================
// Genuine 2012 (oracle, harness-p0sf.as): the released ball rolls left, knocks the crate, and
// the CRATE tips into the pit (settles 347,463 rot -89°), ball rests on top — "crate in hole".
// Live replica build: the crate is shoved OUT of the pit (upright, ~x280) and the BALL takes the
// pit — they SWAP. The ball is a centered circle (no trig feedback, bit-exact); the crate is a
// SQUARE that tips 96°, so its geometry depends on sin/cos(rot) — the FIRST trig-sensitive body.
//
// This test rebuilds the EXACT oracle scene (terrain tris from GeomPoly.triangularDecomposition +
// the crate's 2 game-Triangulate tris, all carried in the golden) in NapeReplica, which runs in
// V8 — the SAME runtime as the live game. So:
//   - If NapeReplica's crate ALSO ends out of the pit (≠ oracle) → the divergence is the engine
//     vs Ruffle, i.e. the trig ceiling (V8 vs AVM2 sin/cos on the rotating crate) → irreducible.
//   - If NapeReplica's crate ends IN the pit (≈ oracle 347) → V8==Ruffle here → the live bug is
//     NOT the engine (shim/scene-build — the dev's side).
// Scope: terrain + crate + roller only (the static objects/other balls are off the crate+ball
// path: posts/blocks/ref up high, players filter-pass balls, goal too far left, sand ramp too
// high). It is a diagnostic, NOT a bit-exact gate (a 96°-rotating poly is trig-limited by design).
// =============================================================================
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0sf-fullscene.json', import.meta.url)), 'utf8'),
).lines;
const dv = new DataView(new ArrayBuffer(8));
const toNum = (pair: string): number => {
  const [hi, lo] = pair.split(':');
  dv.setUint32(0, parseInt(hi, 16) >>> 0);
  dv.setUint32(4, parseInt((lo || '0').padStart(8, '0'), 16) >>> 0);
  return dv.getFloat64(0);
};

// materials (el, friction, rolling, density)  — single friction (static==dynamic for all here)
const GRASS = { d: 1, f: 0.5, r: 0.5, e: 0 };
const MUD = { d: 1, f: 100, r: 100, e: 0 };
const AVG = { d: 0.5, f: 0.1, r: 0.1, e: 0.2 };
const FOOT = { d: 0.5, f: 0.1, r: 0.1, e: 1 };

// rebuild terrain + crate + roller; `o` overrides crate/terrain material props. returns final crate.
function build(o: { cf?: number; ce?: number; cd?: number; gf?: number; mf?: number; crateQuad?: boolean; fallingBall?: boolean } = {}) {
  const w = new NapeReplica(1000);
  const cf = o.cf ?? AVG.f, ce = o.ce ?? AVG.e, cd = o.cd ?? AVG.d;
  const gf = o.gf ?? GRASS.f, mf = o.mf ?? MUD.f;
  const centroids: Record<string, [number, number]> = {};
  for (const ln of lines) { const p = ln.split(/\s+/); if (p[0] === '[LINE]') centroids[p[1]] = [toNum(p[2]), toNum(p[3])]; }
  for (const key of Object.keys(centroids)) {
    const [cx, cy] = centroids[key]; const grass = Number(key) <= 4;
    const fr = grass ? gf : mf;
    const h = w.createBody(true, cx, cy, 0, 0, 0);
    for (const ln of lines) {
      const p = ln.split(/\s+/); if (p[0] !== '[LTRI]' || p[1] !== key) continue;
      const v = p.slice(2).map(Number);
      w.addPolygon(h, [v[0] - cx, v[1] - cy, v[2] - cx, v[3] - cy, v[4] - cx, v[5] - cy], 1, fr, fr, 0, 1, 15, false);
    }
    w.finalizeBody(h, false);
  }
  const crate = w.createBody(false, 398, 416, 0, 0, 0);
  if (o.crateQuad) {
    w.addPolygon(crate, [-24, -20, 24, -20, 24, 20, -24, 20], cd, cf, cf, ce, 8, 15, false);
  } else {
    for (const ln of lines) {
      const p = ln.split(/\s+/); if (p[0] !== '[CTRI]') continue;
      const v = p.slice(1).map(Number);
      w.addPolygon(crate, [v[0], v[1], v[2], v[3], v[4], v[5]], cd, cf, cf, ce, 8, 15, false);
    }
  }
  w.finalizeBody(crate, false);
  const ball = w.createBody(false, 762, 237, 0, 0, 0);
  w.addCircle(ball, 0, 0, 35, FOOT.d, FOOT.f, FOOT.r, FOOT.e, 4, 15, false);
  w.finalizeBody(ball, false);
  // hypothesis: the shim leaves ball_large@338,88 UNSUPPORTED (block uid_666082 missing/wrong),
  // so it free-falls straight into the pit and occupies it before the crate arrives.
  let fb = -1;
  if (o.fallingBall) {
    fb = w.createBody(false, 338, 88, 0, 0, 0);
    w.addCircle(fb, 0, 0, 35, FOOT.d, FOOT.f, FOOT.r, FOOT.e, 4, 15, false);
    w.finalizeBody(fb, false);
  }
  for (let i = 1; i <= 400; i++) w.step(1 / 60, 10, 10);
  return { cx: w.getX(crate), cy: w.getY(crate), crot: (w.getRotRad(crate) * 180) / Math.PI,
    bx: w.getX(ball), by: w.getY(ball), fbx: fb >= 0 ? w.getX(fb) : NaN, fby: fb >= 0 ? w.getY(fb) : NaN };
}
const verdict = (cx: number) => cx > 375 ? 'crate OUT right' : cx < 321 ? 'crate OUT left (=LIVE BUG)' : 'crate IN pit';

describe('P0SF — full-scene crate-in-pit: NapeReplica(V8) vs oracle(Ruffle)', () => {
  it('faithful scene → NapeReplica reproduces genuine crate-in-pit', () => {
    const oc: Record<number, { cx: number; cy: number; crot: number }> = {};
    for (const ln of lines) {
      const m = ln.match(/^\[P0SF\] (\d+) R \S+ \S+ \S+ \S+ \S+ C (\S+) (\S+) \S+ \S+ (\S+)/);
      if (m) oc[+m[1]] = { cx: toNum(m[2]), cy: toNum(m[3]), crot: toNum(m[4]) };
    }
    const r = build();
    console.log(`FAITHFUL: replica crate (${r.cx.toFixed(1)},${r.cy.toFixed(1)}) vs oracle (${oc[400].cx.toFixed(1)},${oc[400].cy.toFixed(1)}) => ${verdict(r.cx)}`);
    // engine-faithful guard: with the genuine scene + fixed dt 1/60, the replica engine lands the
    // crate IN the pit, ≈ oracle — so the live "crate shoved out" bug is NOT the engine.
    expect(r.cx).toBeGreaterThan(321);
    expect(r.cx).toBeLessThan(375);
    expect(Math.abs(r.cx - oc[400].cx)).toBeLessThan(1);
    expect(Math.abs(r.cy - oc[400].cy)).toBeLessThan(1);
  });

  it('SWEEP — which scene-build property flips the crate OUT of the pit (reproduces the live bug)?', () => {
    const cases: [string, any][] = [
      ['baseline (faithful)', {}],
      ['crate friction 0.1→0.5', { cf: 0.5 }],
      ['crate friction 0.1→1.0', { cf: 1.0 }],
      ['crate friction 0.1→0.0', { cf: 0.0 }],
      ['crate elasticity 0.2→0.0', { ce: 0.0 }],
      ['crate elasticity 0.2→0.5', { ce: 0.5 }],
      ['crate density 0.5→1.0 (2× mass)', { cd: 1.0 }],
      ['crate density 0.5→0.25', { cd: 0.25 }],
      ['grass friction 0.5→0.1', { gf: 0.1 }],
      ['grass friction 0.5→1.0', { gf: 1.0 }],
      ['mud friction 100→1', { mf: 1 }],
      ['crate as single QUAD (not 2 tris)', { crateQuad: true }],
      ['UNSUPPORTED ball_large@338,88 falls', { fallingBall: true }],
    ];
    console.log('scenario                              | crate final (x,y) rot°   | verdict');
    for (const [name, opt] of cases) {
      const r = build(opt);
      const extra = opt.fallingBall ? `  [fallen ball @ (${r.fbx.toFixed(0)},${r.fby.toFixed(0)})]` : '';
      console.log(`${name.padEnd(37)} | (${r.cx.toFixed(1)},${r.cy.toFixed(1)}) ${r.crot.toFixed(0)}°`.padEnd(66) + `| ${verdict(r.cx)}${extra}`);
    }
  });
});
