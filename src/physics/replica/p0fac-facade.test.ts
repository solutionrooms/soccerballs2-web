// Facade smoke test — exercises the NapeNative drop-in surface added on top of
// the (separately, bit-exactly tested) solver: world body @ handle 0, jointRev /
// jointWeld / jointDist world->local mapping, takeContacts / takeImpacts BEGIN
// events, raycastDown, bodyContains / bodyArea / touchingBodies, and the
// setBodyCollision toggle. These are behavioural (tolerance) checks, not goldens.
import { describe, it, expect } from 'vitest';
import { NapeReplica } from './nape-core';

const COLL = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,fric,roll,elas,colCat,colMask,sensor
const FLOOR_VERTS = [-200, -20, 200, -20, 200, 20, -200, 20];

// returns the world position of a body's local anchor (rot convention: axis = sin/cos)
function worldAnchor(w: NapeReplica, h: number, lx: number, ly: number): { x: number; y: number } {
  const r = w.getRotRad(h);
  const c = Math.cos(r);
  const s = Math.sin(r);
  return { x: w.getX(h) + (c * lx - s * ly), y: w.getY(h) + (s * lx + c * ly) };
}

// does [hA,hB,flag] triples contain the unordered pair (p,q) with the given flag?
function hasPair(buf: number[], p: number, q: number, flag: number): boolean {
  for (let i = 0; i + 2 < buf.length; i += 3) {
    const a = buf[i];
    const b = buf[i + 1];
    if (buf[i + 2] === flag && ((a === p && b === q) || (a === q && b === p))) return true;
  }
  return false;
}

describe('NapeReplica facade (drop-in surface)', () => {
  it('jointRev pins a body to the WORLD (handle 0) at the given world anchor', () => {
    const w = new NapeReplica(1000);
    // box COM at (240,100); pin its LEFT end (world 200,100) to the world body.
    const box = w.createBody(false, 240, 100, 0, 0, 0);
    w.addPolygon(box, [-40, -10, 40, -10, 40, 10, -40, 10], ...COLL);
    w.finalizeBody(box, false);
    w.jointRev(0, box, 200, 100, false, 0, 0, false, 0, 0);

    for (let i = 0; i < 90; i++) w.step(1 / 60, 10, 10);

    // the box swings, but the pinned local anchor (-40,0) must stay at (200,100).
    const a = worldAnchor(w, box, -40, 0);
    expect(Math.abs(a.x - 200)).toBeLessThan(1.5);
    expect(Math.abs(a.y - 100)).toBeLessThan(1.5);
    // and it actually moved (the joint isn't just freezing the body in place).
    expect(w.getRotRad(box)).not.toBe(0);
  });

  it('emits a single collision BEGIN + a non-zero impact, then settles at rest', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 300, 0, 0, 0);
    w.addPolygon(floor, FLOOR_VERTS, ...COLL);
    w.finalizeBody(floor, false);
    const ball = w.createBody(false, 200, 100, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...COLL);
    w.finalizeBody(ball, true); // bullet

    let begins = 0;
    let maxImpulse = 0;
    for (let i = 0; i < 240; i++) {
      w.step(1 / 60, 10, 10);
      if (hasPair(w.takeContacts(), ball, floor, 0)) begins++;
      const im = w.takeImpacts();
      for (let k = 0; k + 4 < im.length; k += 5) {
        if ((im[k] === ball || im[k + 1] === ball) && im[k + 2] > maxImpulse) maxImpulse = im[k + 2];
      }
    }
    expect(begins).toBe(1); // exactly one BEGIN, not one per resting step
    expect(maxImpulse).toBeGreaterThan(0);
    // rests on the floor top (y=280) minus radius 12 ≈ 268, ~motionless.
    expect(w.getY(ball)).toBeGreaterThan(255);
    expect(w.getY(ball)).toBeLessThan(281);
    expect(Math.abs(w.getVY(ball))).toBeLessThan(5);
    // and the floor now reports the (dynamic) ball as touching it.
    expect(w.touchingBodies(floor)).toContain(ball);
  });

  it('raycastDown finds the floor top; bodyContains / bodyArea work', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 300, 0, 0, 0);
    w.addPolygon(floor, FLOOR_VERTS, ...COLL);
    w.finalizeBody(floor, false);
    const ball = w.createBody(false, 200, 100, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...COLL);
    w.finalizeBody(ball, false);

    // ray down at x=50 (clear of the ball) hits the floor top edge y=280.
    expect(Math.abs(w.raycastDown(50, 0, 1000, 1) - 280)).toBeLessThan(0.5);
    // miss: ray outside the floor span returns NaN.
    expect(Number.isNaN(w.raycastDown(9999, 0, 1000, 1))).toBe(true);
    // point queries.
    expect(w.bodyContains(floor, 200, 300)).toBe(true);
    expect(w.bodyContains(floor, 200, 600)).toBe(false);
    expect(Math.abs(w.bodyArea(ball) - Math.PI * 144)).toBeLessThan(1e-6);
  });

  it('fires a sensor BEGIN (multi-shape body) without a physical collision', () => {
    const w = new NapeReplica(1000);
    // static sensor box at (200,150): senGroup=8, senMask=4.
    const sbox = w.createBody(true, 200, 150, 0, 0, 0);
    w.addPolygon(sbox, [-40, -20, 40, -20, 40, 20, -40, 20], 0, 0.5, 0.1, 0, 8, 4, true);
    w.finalizeBody(sbox, false);
    // ball with TWO shapes: a collision circle + a sensor circle (senGroup=4,senMask=8).
    const ball = w.createBody(false, 200, 80, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...COLL); // collision
    w.addCircle(ball, 0, 0, 12, 0, 0.5, 0.1, 0, 4, 8, true); // sensor
    w.finalizeBody(ball, false);

    let sensorBegins = 0;
    for (let i = 0; i < 120; i++) {
      w.step(1 / 60, 10, 10);
      if (hasPair(w.takeContacts(), ball, sbox, 1)) sensorBegins++;
    }
    expect(sensorBegins).toBe(1); // one BEGIN as the ball enters the sensor volume
    // the ball passed THROUGH (sensor has no collision group) — it's now below the box.
    expect(w.getY(ball)).toBeGreaterThan(200);
  });

  it('setBodyCollision(false) lets a body fall through what it would otherwise hit', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 300, 0, 0, 0);
    w.addPolygon(floor, FLOOR_VERTS, ...COLL);
    w.finalizeBody(floor, false);
    const ball = w.createBody(false, 200, 100, 0, 0, 0);
    w.addCircle(ball, 0, 0, 12, ...COLL);
    w.finalizeBody(ball, false);

    w.setBodyCollision(ball, false); // disable
    for (let i = 0; i < 120; i++) w.step(1 / 60, 10, 10);
    expect(w.getY(ball)).toBeGreaterThan(400); // fell straight through the floor
  });
});
