// Milestone M0 gate — the ported TS replica vs the ORIGINAL Nape AS3.
//
// The golden (original-goldens/m0-freefall.json) was captured by running the
// real original Nape (release_nape.swc, compiled into SoccerBalls2.swf) under
// Ruffle, driven by a tiny calling-AS3 harness (tools/nape-oracle/harness-m0.as)
// — NO game, NO transpile. The harness traces each value as raw IEEE-754 bits,
// so this asserts the replica reproduces the original engine BIT-FOR-BIT.
//
// Regenerate the golden:
//   ffdec -replace .../SoccerBalls2.swf tools/nape-oracle/m0-oracle.swf \
//         Preloader tools/nape-oracle/harness-m0.as
//   node tools/nape-oracle/capture-golden.mjs tools/nape-oracle/m0-oracle.swf \
//        src/physics/replica/original-goldens/m0-freefall.json
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

interface Golden {
  fields: string[];
  mass: string;
  steps: string[][]; // [step][x,y,vx,vy,rot,angvel] as 16-hex IEEE-754
}
const golden: Golden = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m0-freefall.json', import.meta.url)), 'utf8'),
);

const GRAVITY = 1000;
const DT = 1 / 60;

/** 16-hex-char big-endian bit pattern of a double (matches the harness/golden). */
const hex16 = (x: number): string => f64hex(x).slice(2);

// The exact M0 scenario the harness ran: one dynamic circle (radius 12, density
// 1.0), gravity 1000, default world drag 0.015, released at (100, 50).
function buildFreefall(w: NapeReplica): number {
  const h = w.createBody(false, 100, 50, 0, 0.015, 0.015);
  w.addCircle(h, 0, 0, 12, 1.0, 0.5, 0.1, 0.3, 1, 0xffff, false);
  w.finalizeBody(h, false);
  return h;
}

describe('M0 — replica vs ORIGINAL Nape AS3 (Ruffle golden)', () => {
  it('circle mass matches the original bit-for-bit', () => {
    const w = new NapeReplica(GRAVITY);
    const h = buildFreefall(w);
    expect(hex16(w.getMass(h))).toBe(golden.mass);
  });

  it('600 steps match the original bit-for-bit (x, y, vx, vy, rot, angvel)', () => {
    const w = new NapeReplica(GRAVITY);
    const h = buildFreefall(w);
    expect(golden.steps.length).toBe(600);
    for (let s = 0; s < golden.steps.length; s++) {
      w.step(DT, 10, 10);
      const got = [w.getX(h), w.getY(h), w.getVX(h), w.getVY(h), w.getRotRad(h), w.getAngVel(h)].map(hex16);
      const exp = golden.steps[s];
      for (let f = 0; f < 6; f++) {
        if (got[f] !== exp[f]) {
          throw new Error(
            `step ${s + 1} field ${golden.fields[f]}: original=${exp[f]} replica=${got[f]}`,
          );
        }
      }
    }
  });
});
