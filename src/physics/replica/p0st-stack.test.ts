// P0-STACK gate — a DYNAMIC polygon stack vs the ORIGINAL Nape AS3.
// Golden from harness-p0st.as: three dynamic 24×24 boxes stacked axis-aligned on
// a STATIC floor (level-9 "ball blocker" crate-pile reduced to physics essence),
// 90 steps. This is the FIRST conformance scenario to exercise (a) dynamic-vs-
// dynamic polygon face-face contacts and (b) a multi-arbiter both-dynamic island
// (>=2 entries in c_arbiters_false), i.e. the penetration-depth arbiter sort
// (ZPP_Space.as:1644). Both paths are uncovered by p0pp/p0ppr (box on STATIC
// floor, single arbiter). Material is identical to p0pp so any divergence is
// attributable purely to the dynamic-stack path.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0st-stack.json', import.meta.url)), 'utf8'),
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

interface Frame { i: number; tag: string; x: string; y: string; rot: string; vx: string; vy: string; angvel: string }
const frames: Frame[] = lines
  .filter((l) => l.startsWith('[P0ST] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/); // [P0ST] i tag x y rot vx vy angvel
    return { i: Number(p[1]), tag: p[2], x: p[3], y: p[4], rot: p[5], vx: p[6], vy: p[7], angvel: p[8] };
  });

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;
const BOX = [-12, -12, 12, -12, 12, 12, -12, 12];

function build() {
  const w = new NapeReplica(1000);
  const floor = w.createBody(true, 200, 400, 0, 0, 0);
  w.addPolygon(floor, [-100, -20, 100, -20, 100, 20, -100, 20], ...MAT);
  w.finalizeBody(floor, false);
  const mk = (cy: number) => {
    const h = w.createBody(false, 200, cy, 0, 0, 0);
    w.addPolygon(h, BOX, ...MAT);
    w.finalizeBody(h, false);
    return h;
  };
  const b1 = mk(367);
  const b2 = mk(342);
  const b3 = mk(317);
  return { w, byTag: { b1, b2, b3 } as Record<string, number> };
}

describe('P0-STACK — dynamic polygon stack (3 crates) vs ORIGINAL Nape AS3', () => {
  it('all three boxes match the original bit-for-bit for 90 steps', () => {
    const { w, byTag } = build();
    const state = (h: number) => ({
      x: hex16(w.getX(h)), y: hex16(w.getY(h)), rot: hex16(w.getRotRad(h)),
      vx: hex16(w.getVX(h)), vy: hex16(w.getVY(h)), angvel: hex16(w.getAngVel(h)),
    });
    for (let i = 1; i <= 90; i++) {
      w.step(1 / 60, 10, 10);
      for (const f of frames.filter((fr) => fr.i === i)) {
        const got = state(byTag[f.tag]);
        for (const k of ['x', 'y', 'rot', 'vx', 'vy', 'angvel'] as const) {
          const exp = norm(f[k]);
          if (got[k] !== exp) {
            throw new Error(
              `FIRST DIVERGENCE at step ${i}, box ${f.tag}, field ${k}:\n` +
                `  original = ${toNum(exp)}  (${exp})\n` +
                `  replica  = ${toNum(got[k])}  (${got[k]})`,
            );
          }
        }
      }
    }
  });
});
