// Gate (behavioural) — a velocity-set REFRESHES waket on an awake body (keep-awake nudge). The
// level-8 weight switch holds green only while ONGOING contact fires; the game keeps the resting
// block awake by nudging velocity.y -= 1e-8 on each ONGOING frame. That nudge is far below
// bodyAtRest's thresholds, so it can only work if setVel refreshes waket EVERY call — not just
// wakes an already-sleeping body. Nape's velocity/angularVel setters invalidate_wake (waket set
// unconditionally, ZPP_Space.as:5347). Without it: block sleeps ~frame 60 → ONGOING stops (gated
// to awake arbiters) → the nudge (fired only on ONGOING) stops → asleep forever → switch goes red.
// Test the real CONDITIONAL loop (nudge only when ONGOING fired): with the fix it never sleeps.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

function lastOngoingFrame(nudge: boolean): number {
  const w = new NapeReplica(1000);
  const floor = w.createBody(true, 200, 400, 0, 0, 0);
  w.addPolygon(floor, [-150, -20, 150, -20, 150, 20, -150, 20], ...MAT);
  w.finalizeBody(floor, false);
  const block = w.createBody(false, 200, 360, 0, 0, 0);
  w.addPolygon(block, [-20, -20, 20, -20, 20, 20, -20, 20], ...MAT);
  w.finalizeBody(block, false);

  let last = 0;
  for (let f = 1; f <= 150; f++) {
    w.step(1 / 60, 10, 10);
    const ongoing = w.takeOngoing(); // [hA,hB,flag,...]
    if (ongoing.length > 0) {
      last = f;
      if (nudge) w.setVel(block, w.getVX(block), w.getVY(block) - 1e-8); // game's keep-awake nudge, ON ONGOING only
    }
  }
  return last;
}

describe('keep-awake nudge: setVel refreshes waket on an awake body (level-8 weight switch)', () => {
  it('the conditional nudge keeps ONGOING firing (no sleep); without it, ONGOING dies ~frame 60', () => {
    const withNudge = lastOngoingFrame(true);
    const noNudge = lastOngoingFrame(false);
    expect(noNudge, 'without the nudge the block sleeps and ONGOING stops').toBeLessThan(100);
    expect(withNudge, 'the nudge prevents sleep so ONGOING fires to the end').toBe(150);
  });
});
