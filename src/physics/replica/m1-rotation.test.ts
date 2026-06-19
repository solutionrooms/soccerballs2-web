// Milestone M1a gate — rotation + central applyImpulse vs the ORIGINAL Nape AS3.
//
// Golden captured from the real original engine under Ruffle via
// tools/nape-oracle/harness-m1.as (SPIN: a spun circle under gravity; KICK: a
// circle given a central impulse). Values are raw IEEE-754 bits ("hi:lo").
//
// Regenerate:
//   ffdec -replace .../SoccerBalls2.swf tools/nape-oracle/m1-oracle.swf \
//         Preloader tools/nape-oracle/harness-m1.as
//   node tools/nape-oracle/capture-lines.mjs tools/nape-oracle/m1-oracle.swf \
//        src/physics/replica/original-goldens/m1-rotation.json M1
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m1-rotation.json', import.meta.url)), 'utf8'),
).lines;

const DT = 1 / 60;
const hex16 = (x: number): string => f64hex(x).slice(2);
// harness "hi:lo" half-words -> 16-hex big-endian (matches hex16)
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
// 16-hex IEEE-754 -> double (for reconstructing the original's exact vertices)
const fromHex16 = (h: string): number => {
  const dv = new DataView(new ArrayBuffer(8));
  dv.setUint32(0, parseInt(h.slice(0, 8), 16));
  dv.setUint32(4, parseInt(h.slice(8, 16), 16));
  return dv.getFloat64(0);
};

function addCircleBody(w: NapeReplica, x: number, y: number): number {
  const h = w.createBody(false, x, y, 0, 0.015, 0.015);
  w.addCircle(h, 0, 0, 12, 1.0, 0.5, 0.1, 0.3, 1, 0xffff, false);
  w.finalizeBody(h, false);
  return h;
}

describe('M1 — rotation + impulse + polygon mass vs ORIGINAL Nape AS3', () => {
  it('SPIN: mass, inertia and 180 steps (y, vy, rot, angvel) match the original', () => {
    const w = new NapeReplica(1000);
    const h = addCircleBody(w, 100, 50);
    w.setAngVel(h, 5.0);

    const spin = lines.filter((l) => l.startsWith('[SPIN]'));
    const props = spin[0].split(/\s+/); // [SPIN] props <mass> <inertia>
    expect(hex16(w.getMass(h))).toBe(norm(props[2]));
    expect(hex16(w.getInertia(h))).toBe(norm(props[3]));

    const steps = spin.slice(1);
    expect(steps.length).toBe(180);
    const names = ['y', 'vy', 'rot', 'angvel'];
    for (const line of steps) {
      const f = line.split(/\s+/); // [SPIN] <i> <y> <vy> <rot> <angvel>
      w.step(DT, 10, 10);
      const got = [w.getY(h), w.getVY(h), w.getRotRad(h), w.getAngVel(h)].map(hex16);
      for (let k = 0; k < 4; k++) {
        if (got[k] !== norm(f[2 + k])) {
          throw new Error(`SPIN step ${f[1]} ${names[k]}: original=${norm(f[2 + k])} replica=${got[k]}`);
        }
      }
    }
  });

  it('KICK: central applyImpulse + 60 steps (x, y, vx, vy) match the original', () => {
    const w = new NapeReplica(1000);
    const h = addCircleBody(w, 400, 50);
    w.applyImpulse(h, 37, -53);

    const kick = lines.filter((l) => l.startsWith('[KICK]'));
    expect(kick.length).toBe(61); // step 0 (post-impulse) .. 60
    const names = ['x', 'y', 'vx', 'vy'];
    let stepped = 0;
    for (const line of kick) {
      const f = line.split(/\s+/); // [KICK] <i> <x> <y> <vx> <vy>
      const i = Number(f[1]);
      while (stepped < i) {
        w.step(DT, 10, 10);
        stepped++;
      }
      const got = [w.getX(h), w.getY(h), w.getVX(h), w.getVY(h)].map(hex16);
      for (let k = 0; k < 4; k++) {
        if (got[k] !== norm(f[2 + k])) {
          throw new Error(`KICK step ${i} ${names[k]}: original=${norm(f[2 + k])} replica=${got[k]}`);
        }
      }
    }
  });

  it('POLY: box mass, inertia and 120 steps (y, vy, rot, angvel) match the original', () => {
    const poly = lines.filter((l) => l.startsWith('[POLY]'));

    // reconstruct the exact vertices Nape stored (same order it traced them)
    const verts: number[] = [];
    for (const vl of poly.filter((l) => l.startsWith('[POLY] vert'))) {
      const f = vl.split(/\s+/); // [POLY] vert <j> <x> <y>
      verts[Number(f[2]) * 2] = fromHex16(norm(f[3]));
      verts[Number(f[2]) * 2 + 1] = fromHex16(norm(f[4]));
    }
    expect(verts.length).toBe(8);

    const w = new NapeReplica(1000);
    const h = w.createBody(false, 100, 50, 0, 0.015, 0.015);
    w.addPolygon(h, verts, 1.0, 0.5, 0.1, 0.3, 1, 0xffff, false);
    w.finalizeBody(h, false);
    w.setAngVel(h, 3.0);

    const props = poly.find((l) => l.startsWith('[POLY] props'))!.split(/\s+/);
    expect(hex16(w.getMass(h))).toBe(norm(props[2]));
    expect(hex16(w.getInertia(h))).toBe(norm(props[3]));

    const steps = poly.filter((l) => /^\[POLY\] \d/.test(l));
    expect(steps.length).toBe(120);
    const names = ['y', 'vy', 'rot', 'angvel'];
    for (const line of steps) {
      const f = line.split(/\s+/); // [POLY] <i> <y> <vy> <rot> <angvel>
      w.step(DT, 10, 10);
      const got = [w.getY(h), w.getVY(h), w.getRotRad(h), w.getAngVel(h)].map(hex16);
      for (let k = 0; k < 4; k++) {
        if (got[k] !== norm(f[2 + k])) {
          throw new Error(`POLY step ${f[1]} ${names[k]}: original=${norm(f[2 + k])} replica=${got[k]}`);
        }
      }
    }
  });
});
