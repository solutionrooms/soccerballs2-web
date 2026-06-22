// P0RB — lvl-19 ROLLER vs velocity-pinned HELD BEACHBALL, in NapeReplica (the ENGINE, V8).
// =============================================================================
// haxe-port isolated lvl-19 to ONE contact: the roller (ball_large uid_315038, r35, football el1,
// m1.924) rolling LEFT past x~545 strikes the PLAYER'S HELD BALL — a beachball r12, m0.009 (213x
// lighter), velocity force-zeroed + re-teleported to (545,423) EVERY frame (game state-1 hold).
// In the live REPLICA build: ball present -> crate shoved OUT of the pit (270); absent -> crate IN
// (351). Genuine 2012 (oracle harness-p0rb.as, NO-bullet = the faithful config, since the game
// never sets isBullet — confirmed src/GameObj* + nape-shim Body.hx:82): ball present -> crate IN
// (343.9); absent -> IN (346.9). So 2012 keeps the crate IN with the held ball; the replica flips
// it OUT. THIS TEST asks: does the ENGINE itself reproduce the OUT flip (=> engine bug, my remit),
// or only the shim build does (=> shim bug)?
//
// Faithful scene: terrain tris + crate 2-tris from the p0sf golden geometry; block uid_897828
// @747,275 present, destroyed after step 6 (the green-switch release); held beachball pinned at
// (545,423) vel0 each frame. NO bullet (matches the shim: finalizeBody(_, false)).
// =============================================================================
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';

const geo: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0sf-fullscene.json', import.meta.url)), 'utf8'),
).lines;
const dv = new DataView(new ArrayBuffer(8));
const toNum = (pair: string): number => {
  const [hi, lo] = pair.split(':');
  dv.setUint32(0, parseInt(hi, 16) >>> 0);
  dv.setUint32(4, parseInt((lo || '0').padStart(8, '0'), 16) >>> 0);
  return dv.getFloat64(0);
};

// materials (density, friction, rolling, elasticity)
const GRASS = { d: 1, f: 0.5, r: 0.5, e: 0 };
const MUD = { d: 1, f: 100, r: 100, e: 0 };
const AVG = { d: 0.5, f: 0.1, r: 0.1, e: 0.2 };
const FOOT = { d: 0.5, f: 0.1, r: 0.1, e: 1 };
const BEACH = { d: 0.02, f: 0.1, r: 0.1, e: 1 };

interface Frame { f: number; rx: number; ry: number; rvx: number; rvy: number; cx: number; cy: number; }

function run(withBall: boolean): { frames: Frame[]; finalCx: number; finalCy: number } {
  const w = new NapeReplica(1000);
  const centroids: Record<string, [number, number]> = {};
  for (const ln of geo) { const p = ln.split(/\s+/); if (p[0] === '[LINE]') centroids[p[1]] = [toNum(p[2]), toNum(p[3])]; }
  for (const key of Object.keys(centroids)) {
    const [cx, cy] = centroids[key]; const grass = Number(key) <= 4;
    const fr = grass ? GRASS.f : MUD.f;
    const h = w.createBody(true, cx, cy, 0, 0, 0);
    for (const ln of geo) {
      const p = ln.split(/\s+/); if (p[0] !== '[LTRI]' || p[1] !== key) continue;
      const v = p.slice(2).map(Number);
      w.addPolygon(h, [v[0] - cx, v[1] - cy, v[2] - cx, v[3] - cy, v[4] - cx, v[5] - cy], 1, fr, fr, 0, 1, 15, false);
    }
    w.finalizeBody(h, false);
  }
  // static blocks present at f0 (uid_666082, uid_091881)
  const addQuad = (x: number, y: number, verts: number[], stat: boolean) => {
    const h = w.createBody(stat, x, y, 0, 0, 0);
    w.addPolygon(h, verts, AVG.d, AVG.f, AVG.f, AVG.e, 8, 15, false);
    w.finalizeBody(h, false);
    return h;
  };
  addQuad(322, 126, [0, 0, 30, 0, 30, 30, 0, 30], true);
  addQuad(324, -22, [0, 0, 30, 0, 30, 30, 0, 30], true);
  const block = addQuad(747, 275, [0, 0, 30, 0, 30, 30, 0, 30], true); // uid_897828 — destroyed after step 6

  // crate: 2 tris from the golden ([CTRI] -24 20 -24 -20 24 -20  /  24 -20 24 20 -24 20)
  const crate = w.createBody(false, 398, 416, 0, 0, 0);
  for (const ln of geo) {
    const p = ln.split(/\s+/); if (p[0] !== '[CTRI]') continue;
    const v = p.slice(1).map(Number);
    w.addPolygon(crate, [v[0], v[1], v[2], v[3], v[4], v[5]], AVG.d, AVG.f, AVG.f, AVG.e, 8, 15, false);
  }
  w.finalizeBody(crate, false);

  const roller = w.createBody(false, 762, 237, 0, 0, 0);
  w.addCircle(roller, 0, 0, 35, FOOT.d, FOOT.f, FOOT.r, FOOT.e, 4, 15, false);
  w.finalizeBody(roller, false);

  let held = -1;
  if (withBall) {
    held = w.createBody(false, 545, 423, 0, 0, 0);
    w.addCircle(held, 0, 0, 12, BEACH.d, BEACH.f, BEACH.r, BEACH.e, 4, 15, false);
    w.finalizeBody(held, false);
  }

  const frames: Frame[] = [];
  for (let i = 1; i <= 250; i++) {
    if (withBall) { w.setTransform(held, 545, 423, 0); w.setVel(held, 0, 0); w.setAngVel(held, 0); }
    w.step(1 / 60, 10, 10);
    if (i === 6) w.destroyBody(block);
    frames.push({ f: i, rx: w.getX(roller), ry: w.getY(roller), rvx: w.getVX(roller), rvy: w.getVY(roller), cx: w.getX(crate), cy: w.getY(crate) });
  }
  return { frames, finalCx: w.getX(crate), finalCy: w.getY(crate) };
}

const verdict = (cx: number) => (cx > 375 ? 'OUT-right' : cx < 321 ? 'OUT-left(BUG)' : 'IN-pit');

describe('P0RB — roller vs pinned held beachball: does the ENGINE flip the crate OUT?', () => {
  // GUARD: the ENGINE, fed a faithful scene + pinned beachball, must keep the crate IN the pit —
  // matching genuine 2012 (oracle harness-p0rb.as, no-bullet: present 343.9, absent 346.9) to ~0.1px.
  // The live REPLICA build flips it OUT (270.6); since the engine here does NOT, the divergence is
  // shim-introduced, not engine. If this ever starts producing crate-OUT, the engine has regressed.
  it('engine keeps crate IN (= genuine 2012 343.9), with the held ball and without', () => {
    const present = run(true);
    const absent = run(false);
    console.log(`NapeReplica present (held ball): crate (${present.finalCx.toFixed(1)},${present.finalCy.toFixed(1)}) => ${verdict(present.finalCx)}  [2012 oracle: 343.9 IN]`);
    console.log(`NapeReplica absent  (no ball)  : crate (${absent.finalCx.toFixed(1)},${absent.finalCy.toFixed(1)}) => ${verdict(absent.finalCx)}  [2012 oracle: 346.9 IN]`);
    const fa = absent.frames, fp = present.frames;
    let split = -1;
    for (let i = 70; i < 110; i++) {
      if (Math.abs(fp[i].rvx - fa[i].rvx) + Math.abs(fp[i].rvy - fa[i].rvy) > 1e-6) { split = fp[i].f; break; }
    }
    console.log(`engine: roller first reacts to held ball at f${split}  (genuine 2012 @x545 = f82)`);
    // engine reproduces genuine 2012: crate IN the pit (321 < x < 375), ~343.9, both modes
    expect(present.finalCx).toBeGreaterThan(321);
    expect(present.finalCx).toBeLessThan(375);
    expect(absent.finalCx).toBeGreaterThan(321);
    expect(absent.finalCx).toBeLessThan(375);
    expect(Math.abs(present.finalCx - 343.9)).toBeLessThan(3); // matches the genuine-2012 oracle
    expect(split).toBe(82); // roller reacts at f82 like 2012 (@x545); the live build's f80 is the 555 footOffset
  });
});
