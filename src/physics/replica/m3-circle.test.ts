// Milestone M3a gate — circle-circle narrowphase vs the ORIGINAL Nape AS3.
// Golden from harness-m3.as: two overlapping circles, the collision arbiter's
// normal and contact penetration. The normal is NOT unit-length (0.99977) and
// the penetration isn't the exact geometric value — Nape normalizes with a
// Quake fast-inverse-sqrt, and the replica must reproduce that approximation
// bit-for-bit.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m3-circle.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

const MAT = [1.0, 0.5, 0.1, 0.3, 1, 0xffff, false] as const;

describe('M3a — circle-circle narrowphase vs ORIGINAL Nape AS3', () => {
  it('manifold normal + penetration match the original bit-for-bit (incl. fast-inv-sqrt)', () => {
    const l = lines.find((x) => x.startsWith('[M3CC]'))!.split(/\s+/); // [M3CC] b1 b2 nx ny pen
    const exp = { nx: norm(l[3]), ny: norm(l[4]), pen: norm(l[5]) };

    const w = new NapeReplica(0);
    const ha = w.createBody(false, 100, 100, 0, 0, 0); // handle 1 == golden body1
    w.addCircle(ha, 0, 0, 20, ...MAT);
    w.finalizeBody(ha, false);
    const hb = w.createBody(false, 130, 100, 0, 0, 0); // handle 2 == golden body2
    w.addCircle(hb, 0, 0, 20, ...MAT);
    w.finalizeBody(hb, false);

    const m = w.circleCircleManifold(ha, hb)!;
    const got = { nx: hex16(m.nx), ny: hex16(m.ny), pen: hex16(m.penetration) };
    for (const k of ['nx', 'ny', 'pen'] as const) {
      if (got[k] !== exp[k]) throw new Error(`${k}: original=${exp[k]} replica=${got[k]}`);
    }
  });
});
