// BEHAVIOURAL — KINEMATIC bodies (referees, moving platforms/lifts/switch-walls).
// The game flips a body to KINEMATIC at runtime (SetBodyXForm) and drives it by
// velocity. A kinematic must: keep its REGISTRATION origin (no align/COM-recenter),
// take NO gravity, integrate position from its set velocity, have infinite mass
// (unaffected by impulses), still collide, and CARRY riders via its velocity in the
// contact solver. (Bit-exact goldens vs original Nape AS3 are locked separately;
// these are the fast behavioural guards.) See sb2_developer_messages.md.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elast,cat,mask,sensor
const KINEMATIC = 2; // facade BodyType code

describe('KINEMATIC bodies', () => {
  it('stationary offset-COM referee keeps its registration origin (the floating-ref bug)', () => {
    // Ref collision box: origin at the FEET (local y 0), head 80px up (local y −80),
    // so COM sits 40px above the origin. nape-haxe4 renders at the feet (388,128).
    const w = new NapeReplica(1000);
    const ref = w.createBody(true, 388, 128, 0, 0, 0); // created STATIC at the placement
    w.addPolygon(ref, [-10, -80, 10, -80, 10, 0, -10, 0], ...MAT);
    w.finalizeBody(ref, false);
    w.setBodyType(ref, KINEMATIC); // SetBodyXForm flips it; velocity stays 0
    for (let i = 0; i < 30; i++) w.step(1 / 60, 10, 10);
    expect(w.isDynamic(ref)).toBe(false); // static=false dyn=false → kinematic
    // MUST stay at the registration origin (388,128), NOT jump to the COM (388,88).
    expect(Math.abs(w.getX(ref) - 388)).toBeLessThan(1e-9);
    expect(Math.abs(w.getY(ref) - 128)).toBeLessThan(1e-9);
    expect(w.getVY(ref)).toBe(0); // no gravity — it does not fall
  });

  it('moving platform takes no gravity, moves by its velocity, and carries a rider', () => {
    const w = new NapeReplica(1000);
    // Wide kinematic platform; top surface at y=390.
    const plat = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(plat, [-100, -10, 100, -10, 100, 10, -100, 10], ...MAT);
    w.finalizeBody(plat, false);
    w.setBodyType(plat, KINEMATIC);
    // A dynamic box resting on the platform top (bottom at y=390).
    const rider = w.createBody(false, 200, 382, 0, 0, 0);
    w.addPolygon(rider, [-8, -8, 8, -8, 8, 8, -8, 8], ...MAT);
    w.finalizeBody(rider, false);

    for (let i = 0; i < 60; i++) {
      w.setVel(plat, 120, 0); // game re-drives velocity each frame
      w.step(1 / 60, 10, 10);
    }
    // Platform: integrated 120 px/s for 1s → ~+120px in x, NO vertical drift (no gravity).
    expect(w.getX(plat)).toBeGreaterThan(315);
    expect(w.getX(plat)).toBeLessThan(325);
    expect(Math.abs(w.getY(plat) - 400)).toBeLessThan(1e-9);
    // Rider: carried right by friction (advanced well past its start), still on top.
    // eslint-disable-next-line no-console
    console.log(`[kinematic] platform x=${w.getX(plat).toFixed(1)}  rider x=${w.getX(rider).toFixed(1)} y=${w.getY(rider).toFixed(1)} vx=${w.getVX(rider).toFixed(1)}`);
    expect(w.getX(rider)).toBeGreaterThan(250); // clearly carried, not left behind
    expect(w.getX(rider)).toBeLessThan(w.getX(plat) + 5); // doesn't outrun the platform
    expect(Math.abs(w.getY(rider) - 382)).toBeLessThan(2); // stayed on top (didn't fall through)
  });
});
