// Gate (bit-exact) — rolling friction on a slope (level-36 "ref on wheels" diagnostic). Golden
// from harness-p0rs.as: a free `football` wheel (el=1, fric=0.1, roll=0.1, r35) released from
// rest on a 4.7° slope — modeled as a flat floor with TILTED GRAVITY (1000 @ 4.7° =
// (81.935, 996.638)) so the horizontal component drives it +x exactly like the slope, with no
// tilted-floor trig. 2012 Nape rolls it: x climbs, vx grows, angVel spins up toward vx/r (true
// rolling). This locks the rolling-friction path, which the vertical-settle goldens never
// exercised (a ball settling straight down has no tangential motion to roll). A centered circle
// has localCOM=0, so its contact dynamics are independent of the (continuously accumulating)
// rotation angle — no trig feedback — hence bit-exact for the full run despite the spin.
//
// Diagnostic note: the free wheel rolls bit-exact, and reconstructions with 1–2 revolute-jointed
// wheels + a welded referee (+ a drop) all roll too — so the level-36 settle is NOT rolling
// friction / the sleep threshold / the pivot or weld joints in isolation; it needs the actual
// vehicle's masses + wake-from-sleep transient (awaiting a deterministic repro from haxe-port).
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';
import { f64hex } from './diff';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0rs.json', import.meta.url)), 'utf8'),
).lines;
const hex16 = (x: number): string => f64hex(x).slice(2);
const norm = (pair: string): string => {
  const [hi, lo] = pair.split(':');
  return hi.padStart(8, '0') + lo.padStart(8, '0');
};

// [P0RS] i <x> <vx> <angVel>
const frames = lines
  .filter((l) => l.startsWith('[P0RS] ') && !l.includes('DONE'))
  .map((l) => {
    const p = l.split(/\s+/);
    return { i: Number(p[1]), x: p[2], vx: p[3], av: p[4] };
  });

describe('rolling friction on a slope (free wheel) vs ORIGINAL Nape AS3', () => {
  it('a football wheel released on a 4.7° slope rolls + spins up, bit-for-bit over 150 steps', () => {
    const w = new NapeReplica(996.638);
    (w as unknown as { gravityx: number }).gravityx = 81.935; // 1000 @ 4.7° down-right
    const floor = w.createBody(true, 300, 400, 0, 0, 0);
    w.addPolygon(floor, [-1000, -20, 1000, -20, 1000, 20, -1000, 20], 1.0, 0.1, 0.1, 1.0, 1, 0xffff, false);
    w.finalizeBody(floor, false);
    const wheel = w.createBody(false, 150, 345, 0, 0, 0);
    w.addCircle(wheel, 0, 0, 35, 1.0, 0.1, 0.1, 1.0, 1, 0xffff, false);
    w.finalizeBody(wheel, false);

    for (const f of frames) {
      w.step(1 / 60, 10, 10);
      expect(hex16(w.getX(wheel)), `step ${f.i} x`).toBe(norm(f.x));
      expect(hex16(w.getVX(wheel)), `step ${f.i} vx`).toBe(norm(f.vx));
      expect(hex16(w.getAngVel(wheel)), `step ${f.i} angVel`).toBe(norm(f.av));
    }
  });
});
