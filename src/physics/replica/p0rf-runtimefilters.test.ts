// BEHAVIOURAL — the remaining runtime filter setters (the bit-exact solver path is locked
// by p0sw/p0se). Covers: setBodyCollisionGroup (solver), setBodySensorMask /
// setBodySensorGroup (sensor-overlap events). See sb2_developer_messages.md.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

// scan the flat takeContacts() buffer [hA,hB,flag,...] for a SENSOR event (flag === 1)
function hasSensorEvent(buf: number[]): boolean {
  for (let i = 0; i + 2 < buf.length; i += 3) if (buf[i + 2] === 1) return true;
  return false;
}

describe('runtime filter setters', () => {
  it('setBodyCollisionGroup drops a resting ball when the group no longer matches', () => {
    const w = new NapeReplica(1000);
    const block = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(block, [-50, -10, 50, -10, 50, 10, -50, 10], ...MAT);
    w.finalizeBody(block, false);
    const ball = w.createBody(false, 200, 376, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);
    for (let i = 0; i < 30; i++) w.step(1 / 60, 10, 10);
    const yResting = w.getY(ball);
    expect(yResting).toBeLessThan(385);

    w.setBodyCollisionGroup(block, 0); // group 0 → (0 & ball.colMask) = 0 → no longer collides
    for (let i = 0; i < 40; i++) w.step(1 / 60, 10, 10);
    expect(w.getY(ball), 'ball should fall when the block group no longer matches').toBeGreaterThan(yResting + 100);
  });

  it('setBodySensorMask gates sensor-overlap events', () => {
    // Two overlapping sensor shapes that sense each other (senGroup/senMask cross-match).
    const build = (): { w: NapeReplica; a: number } => {
      const w = new NapeReplica(0); // no gravity — keep them overlapping
      const a = w.createBody(false, 200, 200, 0, 0, 0); // dynamic (collectEvents needs ≥1 dynamic)
      w.addCircle(a, 0, 0, 20, 1.0, 0.5, 0.1, 0.0, 8, 4, true); // sensor: senGroup=8, senMask=4
      w.finalizeBody(a, false);
      const b = w.createBody(true, 200, 200, 0, 0, 0);
      w.addCircle(b, 0, 0, 20, 1.0, 0.5, 0.1, 0.0, 4, 8, true); // sensor: senGroup=4, senMask=8
      w.finalizeBody(b, false);
      return { w, a };
    };
    // baseline: masks cross-match → a sensor BEGIN event fires
    const base = build();
    base.w.step(1 / 60, 10, 10);
    expect(hasSensorEvent(base.w.takeContacts()), 'sensor event should fire when masks match').toBe(true);

    // mask → 0 before the first step → no sensor event
    const off = build();
    off.w.setBodySensorMask(off.a, 0);
    off.w.step(1 / 60, 10, 10);
    expect(hasSensorEvent(off.w.takeContacts()), 'sensor event must NOT fire after senMask → 0').toBe(false);
  });

  it('setBodySensorGroup gates sensor-overlap events', () => {
    const w = new NapeReplica(0);
    const a = w.createBody(false, 200, 200, 0, 0, 0);
    w.addCircle(a, 0, 0, 20, 1.0, 0.5, 0.1, 0.0, 8, 4, true);
    w.finalizeBody(a, false);
    const b = w.createBody(true, 200, 200, 0, 0, 0);
    w.addCircle(b, 0, 0, 20, 1.0, 0.5, 0.1, 0.0, 4, 8, true);
    w.finalizeBody(b, false);
    w.setBodySensorGroup(a, 1); // a.senGroup 8 → 1; b.senMask is 8 → (a.senGroup=1 & 8)=0 → no sense
    w.step(1 / 60, 10, 10);
    expect(hasSensorEvent(w.takeContacts()), 'sensor event must NOT fire after senGroup mismatch').toBe(false);
  });
});
