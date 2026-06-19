// Gate (behavioural) — keeper-duck wake fix. setBodyCollisionAboveTop toggles collision only
// on shapes whose top reaches above a threshold (the keeper's tall idle shape ducks; the short
// crouch shape stays solid). The bug: it changed the masks but — alone among the collision-
// filter setters — never called dropStaleArbiters, so a body asleep on the tall shape stayed
// frozen mid-air when the keeper ducked (the destroyBody / sand-block class). The wake
// MECHANISM itself (drop now-non-colliding arbiters + wake the resting partner on a filter
// change) is bit-exact vs the shipped SWF via p0sw; what is replica-specific here is the
// per-shape above-threshold SELECTION, which has no Nape equivalent to oracle — so this is a
// behavioural check: a ball asleep on the TALL shape wakes and falls on duck, while a ball on
// the SHORT shape is untouched.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elasticity,group,mask,sensor

describe('keeper-duck wakes a body asleep on the disabled (tall) shape', () => {
  it('ducking drops the tall shape so its sleeping rider falls; the short shape keeps its rider', () => {
    const w = new NapeReplica(1000);
    // keeper: one static body, two shapes. TALL shape (left) top at world y=300 ⇒ topPx=100;
    // SHORT shape (right) top at world y=380 ⇒ topPx=20. Origin at (200,400).
    const keeper = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(keeper, [-55, -100, -25, -100, -25, 0, -55, 0], ...MAT); // tall: x 145..175, y 300..400
    w.addPolygon(keeper, [25, -20, 55, -20, 55, 0, 25, 0], ...MAT); // short: x 225..255, y 380..400
    w.finalizeBody(keeper, false);

    const ballTall = w.createBody(false, 160, 284, 0, 0, 0); // rests on the tall top (300)
    w.addCircle(ballTall, 0, 0, 15, ...MAT);
    w.finalizeBody(ballTall, false);
    const ballShort = w.createBody(false, 240, 364, 0, 0, 0); // rests on the short top (380)
    w.addCircle(ballShort, 0, 0, 15, ...MAT);
    w.finalizeBody(ballShort, false);

    // settle + sleep (well past the ~60-stamp rest threshold)
    for (let i = 0; i < 100; i++) w.step(1 / 60, 10, 10);

    // both are at rest: y stable over the last few steps
    const tallBefore = w.getY(ballTall);
    const shortBefore = w.getY(ballShort);
    for (let i = 0; i < 5; i++) w.step(1 / 60, 10, 10);
    expect(Math.abs(w.getY(ballTall) - tallBefore), 'tall rider asleep before duck').toBeLessThan(1e-6);
    expect(Math.abs(w.getY(ballShort) - shortBefore), 'short rider asleep before duck').toBeLessThan(1e-6);

    // DUCK: disable shapes whose top is > 50px above the origin → tall toggles off, short stays
    const tallY = w.getY(ballTall);
    const shortY = w.getY(ballShort);
    w.setBodyCollisionAboveTop(keeper, 50, false);
    for (let i = 0; i < 15; i++) w.step(1 / 60, 10, 10);

    // the tall rider WOKE and fell; the short rider is untouched (selectivity holds)
    expect(w.getY(ballTall) - tallY, 'tall rider woke and fell after duck').toBeGreaterThan(5);
    expect(Math.abs(w.getY(ballShort) - shortY), 'short rider stayed put').toBeLessThan(1e-6);
  });
});
