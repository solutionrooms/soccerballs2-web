// End-to-end facade test: the SAME real-data sensor path as coin-sensor.test.ts,
// but driven through NapePhysWorld backed by the REPLICA (setReplicaEngine) — so
// it needs no nape.js. Proves the whole adapter chain works on real game filters:
// NapePhysWorld.createBody -> replica.addCircle (dual col/sensor copies) -> step ->
// collectEvents sensor pass -> takeContacts -> ContactEvent{sensor}.
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { NapePhysWorld, setReplicaEngine, type PhysWorld, type ShapeDef } from '../world';
import objectsJson from '../../data/objects.json';

const mats = (objectsJson as unknown as { materials: ConstructorParameters<typeof NapePhysWorld>[0] }).materials;
// coin: sensor-only (col 0,0, sen 8,4); ball: col 4,15, sen 4,11 (same as coin-sensor.test.ts)
const coinShape: ShapeDef = { type: 'circle', colCat: 0, colMask: 0, senCat: 8, senMask: 4, material: 'football', pos: [0, 0], radius: 12 };
const ballShape: ShapeDef = { type: 'circle', colCat: 4, colMask: 15, senCat: 4, senMask: 11, material: 'football', pos: [0, 0], radius: 12 };

function sensorFires(w: PhysWorld): boolean {
  w.createBody({ name: 'pickup' }, 100, 100, 0, 1, [coinShape], { fixed: true });
  w.createBody({ name: 'football' }, 100, 100, 0, 1, [ballShape], { fixed: false });
  for (let i = 0; i < 5; i++) {
    w.step();
    for (const c of w.takeContacts()) {
      const names = [(c.a.owner as { name: string }).name, (c.b.owner as { name: string }).name];
      if (names.includes('pickup') && names.includes('football')) return true;
    }
  }
  return false;
}

describe('facade end-to-end on the replica (no nape.js)', () => {
  beforeAll(() => setReplicaEngine(true));
  afterAll(() => setReplicaEngine(false));

  it('the ball-coin sensor contact fires through the NapePhysWorld->replica adapter', () => {
    expect(sensorFires(new NapePhysWorld(mats))).toBe(true);
  });

  it('a ball collides with a static floor and settles (collision + impulse path)', () => {
    const w = new NapePhysWorld(mats) as PhysWorld;
    const floor: ShapeDef = { type: 'polygon', colCat: 1, colMask: 15, senCat: 0, senMask: 0, material: 'football', pos: [0, 0], vertices: [-200, -20, 200, -20, 200, 20, -200, 20] };
    const ballC: ShapeDef = { type: 'circle', colCat: 4, colMask: 15, senCat: 0, senMask: 0, material: 'football', pos: [0, 0], radius: 12 };
    w.createBody({ name: 'floor' }, 200, 300, 0, 1, [floor], { fixed: true });
    const ball = w.createBody({ name: 'football' }, 200, 100, 0, 1, [ballC], { fixed: false, bullet: true });
    let impacts = 0;
    w.onImpact(() => { impacts++; });
    for (let i = 0; i < 240; i++) w.step();
    const p = w.getPosPx(ball);
    expect(p.y).toBeGreaterThan(255); // rests near floor top (280) - radius (12)
    expect(p.y).toBeLessThan(281);
    expect(impacts).toBeGreaterThan(0); // onImpact drained from takeImpacts
  });
});
