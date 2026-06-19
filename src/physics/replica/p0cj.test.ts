// Gate (behavioural) — collide_joined=false (the level-36 "ref on wheels" lock). The shipped game
// sets collide_joined=false on ALL 98 joints (PhysicsBase.as:142 default; every level), so jointed
// bodies must NOT collide (Nape joint.ignore=true). The metalpost chassis sits INSIDE the wheel it's
// revolute-jointed to — if they collide, that internal contact fights the joint and locks the
// assembly so it never rolls (verified: identical setup STUCK with internal collision on, ROLLS with
// it off). Fix: jointRev/jointWeld/jointDist register the body pair in ignoredPairs; narrowphase, CCD
// and sensor events skip it. This is replica-only logic (no Nape oracle for "did they collide"), so
// behavioural: a chassis-in-wheel revolute on a 4.2° slope must roll, not lock.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

function box(hw: number, hh: number): number[] { return [-hw, -hh, hw, -hh, hw, hh, -hw, hh]; }

describe('jointed bodies do not collide (collide_joined=false) — chassis-in-wheel rolls, not locks', () => {
  it('a wheel with a chassis embedded inside it (revolute) rolls down a 4.2° slope', () => {
    const e = new NapeReplica(1000);
    const ground = e.createBody(true, 530, 400, 4.2, 0, 0);
    e.addPolygon(ground, box(900, 40), 1, 0.5, 0, 0, 1, 15, false);
    e.finalizeBody(ground, false);
    const wheel = e.createBody(false, 474, 300, 0, 0, 0);
    e.addCircle(wheel, 0, 0, 35, 0.5, 0.1, 0.1, 1, 4, 15, false);
    e.finalizeBody(wheel, false);
    // chassis box (12×56) centred ON the wheel centre → fully embedded; same collision mask
    // ⇒ would collide and lock if collide_joined weren't honoured.
    const chassis = e.createBody(false, 474, 299, 90, 0, 0);
    e.addPolygon(chassis, box(6, 28), 0.5, 0.1, 0, 0.2, 8, 15, false);
    e.finalizeBody(chassis, false);
    e.jointRev(chassis, wheel, 474, 300, false, 0, 0, false, 0, 0);

    const x0 = e.getX(wheel);
    for (let f = 1; f <= 400; f++) e.step(1 / 60, 10, 10);
    const moved = e.getX(wheel) - x0;
    const angVel = e.getAngVel(wheel);
    // rolls away and spins up — NOT the stuck state (≈70px slid then av≈0)
    expect(Math.abs(moved), 'rolled far').toBeGreaterThan(200);
    expect(Math.abs(angVel), 'spun up to a roll').toBeGreaterThan(3);
  });
});
