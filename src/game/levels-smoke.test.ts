// Smoke test: every level constructs (instances, lines, joints, behaviors)
// and survives 120 simulation frames without throwing.
import { describe, it, expect } from 'vitest';
import { PhysicsWorld, PlanckWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel, LEVELS } from './level-loader';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

function makeContext(): GameContext {
  const physics = new PlanckWorld(
    (objectsJson as unknown as { materials: ConstructorParameters<typeof PlanckWorld>[0] }).materials,
  );
  const audio = { playSfx: () => {}, playMusic: () => {} } as unknown as GameAudio;
  const atlas = { frameCount: () => 8, draw: () => {} } as unknown as Atlas;
  return {
    physics,
    atlas,
    level: new LevelState(),
    audio,
    objects: new GameObjects(),
    mouseX: 0,
    mouseY: 0,
    cameraX: 0,
    cameraY: 0,
    bounds: { left: -3000, top: -3000, right: 3000, bottom: 3000 },
  };
}

function stepWorld(g: GameContext): void {
  for (const go of g.objects.list) {
    if (go.body && go.physicsStationary) {
      PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
      PhysicsWorld.setVelPx(go.body, 0, 0);
      PhysicsWorld.setAngularVelocity(go.body, 0);
    }
  }
  g.physics.step();
  for (const go of g.objects.list) {
    if (go.body && !go.physicsStationary && PhysicsWorld.isDynamic(go.body)) {
      const p = PhysicsWorld.getPosPx(go.body);
      go.xpos = p.x;
      go.ypos = p.y;
      go.dir = p.rot;
    }
  }
  for (const c of g.physics.takeContacts()) {
    const a = c.a.owner as GameObj;
    const b = c.b.owner as GameObj;
    if (a?.onHitFn && !a.dead) a.onHitFn(a, b, g, c.sensor);
    if (b?.onHitFn && !b.dead) b.onHitFn(b, a, g, c.sensor);
  }
  for (const go of g.objects.list) {
    if (!go.dead && go.updateFn) go.updateFn(go, g);
  }
  g.objects.flushAdds();
  g.objects.removeDead(g.physics);
}

describe('all 36 levels load and simulate', () => {
  for (let i = 0; i < LEVELS.length; i++) {
    it(`level ${i + 1} "${LEVELS[i].name}"`, () => {
      const g = makeContext();
      const loaded = loadLevel(g, i);
      g.bounds = loaded.scrollBounds;
      expect(g.objects.list.length).toBeGreaterThan(0);
      // every level needs a ball and a player to be playable
      expect(g.objects.byName('football'), 'football').toBeTruthy();
      expect(g.objects.byName('player'), 'player').toBeTruthy();
      for (let f = 0; f < 120; f++) stepWorld(g);
    });
  }
});
