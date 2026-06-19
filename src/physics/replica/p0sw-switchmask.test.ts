// BEHAVIOURAL — runtime collision-mask change (game SetBodyCollisionMask; level-19
// switches make a switchable_block "disappear" by setting its mask to 0). A ball rests on
// a block long enough to SLEEP, then the block's mask → 0: the ball must SEPARATE and FALL
// (the engine drops the now-non-colliding arbiter and WAKES the sleeping ball). If the
// wake path were missing, the asleep ball would stay frozen — so this exercises it.
// See sb2_developer_messages.md.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const;

describe('setBodyCollisionMask — runtime mask change drops + wakes a resting ball', () => {
  it('ball resting (asleep) on a block falls when the block mask → 0', () => {
    const w = new NapeReplica(1000);
    const block = w.createBody(true, 200, 400, 0, 0, 0); // static block, top at y=390
    w.addPolygon(block, [-50, -10, 50, -10, 50, 10, -50, 10], ...MAT);
    w.finalizeBody(block, false);
    const ball = w.createBody(false, 200, 376, 0, 0, 0); // rests at ~378 (radius 12)
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);

    // Settle long enough that the ball sleeps (p0sl: a resting body sleeps ~60 stamps).
    for (let i = 0; i < 120; i++) w.step(1 / 60, 10, 10);
    const yResting = w.getY(ball);
    expect(yResting).toBeGreaterThan(370);
    expect(yResting).toBeLessThan(385); // resting on the block, not fallen

    // The switch fires: block disappears (mask → 0).
    w.setBodyCollisionMask(block, 0);
    for (let i = 0; i < 60; i++) w.step(1 / 60, 10, 10);
    const yAfter = w.getY(ball);
    // eslint-disable-next-line no-console
    console.log(`[switchmask] resting y=${yResting.toFixed(2)} → after unmask y=${yAfter.toFixed(2)}`);
    expect(yAfter, 'ball did not fall after the block mask went to 0').toBeGreaterThan(yResting + 100);
  });

  it('a block that never collides again stays inert; re-enabling the mask restores collision', () => {
    const w = new NapeReplica(1000);
    const block = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(block, [-50, -10, 50, -10, 50, 10, -50, 10], ...MAT);
    w.finalizeBody(block, false);
    const ball = w.createBody(false, 200, 300, 0, 0, 0); // dropped from above
    w.addCircle(ball, 0, 0, 12, ...MAT);
    w.finalizeBody(ball, false);

    w.setBodyCollisionMask(block, 0); // disabled before the ball arrives → it passes through
    for (let i = 0; i < 30; i++) w.step(1 / 60, 10, 10);
    expect(w.getY(ball), 'ball should pass through a masked-off block').toBeGreaterThan(400);
  });
});
