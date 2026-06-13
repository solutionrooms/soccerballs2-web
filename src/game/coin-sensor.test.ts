// Regression: the ball collects pickup coins via the sensor contact, at any
// speed (no tunneling). Coins are sensor-only (col 0,0 sen 8,4); the ball is
// col 4,15 sen 4,11.
import './nape-test-setup';
import { describe, it, expect } from 'vitest';
import { NapePhysWorld, type PhysWorld, type ShapeDef } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel } from './level-loader';
import { PhysicsWorld } from '../physics/world';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

const mats = (objectsJson as unknown as { materials: ConstructorParameters<typeof NapePhysWorld>[0] }).materials;
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

function ctx(): GameContext {
  return {
    physics: new NapePhysWorld(mats), atlas: { frameCount: () => 8, draw: () => {} } as unknown as Atlas,
    level: new LevelState(), audio: { playSfx: () => {}, playMusic: () => {} } as unknown as GameAudio,
    objects: new GameObjects(), mouseX: 0, mouseY: 0, cameraX: 0, cameraY: 0,
    bounds: { left: -3000, top: -3000, right: 3000, bottom: 3000 },
  };
}
function step(g: GameContext): void {
  for (const go of g.objects.list) if (go.body && go.physicsStationary) {
    PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
    PhysicsWorld.setVelPx(go.body, 0, 0); PhysicsWorld.setAngularVelocity(go.body, 0);
  }
  g.physics.step();
  for (const go of g.objects.list) if (go.body && !go.physicsStationary && PhysicsWorld.isDynamic(go.body)) {
    const p = PhysicsWorld.getPosPx(go.body); go.xpos = p.x; go.ypos = p.y; go.dir = p.rot;
  }
  for (const c of g.physics.takeContacts()) {
    const a = c.a.owner as GameObj, b = c.b.owner as GameObj;
    if (a?.onHitFn) a.onHitFn(a, b, g, c.sensor);
    if (b?.onHitFn) b.onHitFn(b, a, g, c.sensor);
  }
  for (const go of g.objects.list) if (!go.dead && go.updateFn) go.updateFn(go, g);
  g.objects.flushAdds(); g.objects.removeDead(g.physics);
}

describe('coin collection', () => {
  it('the ball-coin sensor contact fires', () => {
    expect(sensorFires(new NapePhysWorld(mats))).toBe(true);
  });

  for (const speed of [200, 884, 1500, 2500]) {
    it(`collects a coin at ${speed}px/s (no tunneling)`, () => {
      const g = ctx();
      loadLevel(g, 8); // level 9 has coins
      const coin = g.objects.list.filter((o) => o.name === 'pickup' && o.body)[0];
      const ball = g.objects.byName('football')!;
      ball.refA = null; ball.state = 2; ball.physicsStationary = false;
      const t = speed / 60;
      PhysicsWorld.setPosPx(ball.body!, coin.xpos - 3 * t, coin.ypos, 0);
      PhysicsWorld.setVelPx(ball.body!, speed, 0);
      const before = g.level.coinsCollectedThisLevel;
      for (let i = 0; i < 30; i++) step(g);
      expect(g.level.coinsCollectedThisLevel).toBeGreaterThan(before);
    });
  }
});
