// Milestone M3c gate — polygon-polygon narrowphase vs the ORIGINAL Nape AS3.
// Golden from harness-m3c.as: two overlapping axis-aligned boxes (face-face → two
// contacts). We assert the arbiter normal and the SET of contacts (penetration +
// clipped position) bit-for-bit; contact ORDER is the arbiter list order (handled
// for warm-starting in M4), so the set is matched order-independently here.
import { describe, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/m3c-polypoly.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};
const MAT = [1.0, 0.5, 0.1, 0.3, 1, 0xffff, false] as const;
const BOX = [-20, -12, 20, -12, 20, 12, -20, 12];

describe('M3c — polygon-polygon narrowphase vs ORIGINAL Nape AS3', () => {
  it('normal + both clipped contacts (penetration, position) match the original bit-for-bit', () => {
    const head = lines.find((l) => l.startsWith('[M3PP] '))!.split(/\s+/); // [M3PP] b1 b2 n nx ny cnt count
    const expN = { nx: norm(head[4]), ny: norm(head[5]) };
    const expCount = Number(head[7]);
    const goldenContacts = lines
      .filter((l) => l.startsWith('[M3PP-C]'))
      .map((l) => {
        const p = l.split(/\s+/); // [M3PP-C] idx pen <pen> pos <px> <py>
        return { pen: norm(p[3]), px: norm(p[5]), py: norm(p[6]) };
      });

    const w = new NapeReplica(0);
    const hA = w.createBody(false, 200, 200, 0, 0, 0); // body1
    w.addPolygon(hA, BOX, ...MAT);
    w.finalizeBody(hA, false);
    const hB = w.createBody(false, 200, 184, 0, 0, 0); // body2
    w.addPolygon(hB, BOX, ...MAT);
    w.finalizeBody(hB, false);

    const m = w.polyPolyManifold(hA, hB)!;
    if (hex16(m.nx) !== expN.nx) throw new Error(`nx: original=${expN.nx} replica=${hex16(m.nx)}`);
    if (hex16(m.ny) !== expN.ny) throw new Error(`ny: original=${expN.ny} replica=${hex16(m.ny)}`);
    if (m.contacts.length !== expCount) throw new Error(`contact count: original=${expCount} replica=${m.contacts.length}`);

    // order-independent: every replica contact must match a distinct golden one
    const remaining = [...goldenContacts];
    for (const c of m.contacts) {
      const got = { pen: hex16(c.penetration), px: hex16(c.px), py: hex16(c.py) };
      const idx = remaining.findIndex((g) => g.pen === got.pen && g.px === got.px && g.py === got.py);
      if (idx < 0) {
        throw new Error(`unmatched replica contact pen=${got.pen} px=${got.px} py=${got.py}`);
      }
      remaining.splice(idx, 1);
    }
  });
});
