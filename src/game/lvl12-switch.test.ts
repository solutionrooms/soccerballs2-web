// Regression: level 12's StopGo switch (right side), when hit by the ball,
// moves its welded platform (path_object mover -> post_movable -> cannon).
import './nape-test-setup';
import { describe, it, expect } from 'vitest';
import { PhysicsWorld, NapePhysWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel } from './level-loader';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

const mats = (objectsJson as unknown as { materials: ConstructorParameters<typeof NapePhysWorld>[0] }).materials;

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

describe('level 12 switch platform', () => {
  it('hitting the StopGo switch moves the welded platform', () => {
    const g = ctx();
    loadLevel(g, 11); // level 12
    for (let i = 0; i < 30; i++) step(g);
    const byId = (id: string): GameObj | undefined => g.objects.list.find((o) => o.id === id);
    const path = byId('uid_416160'); // path mover
    const post = byId('uid_820282'); // welded post (visible platform)
    const sw = byId('uid_218971'); // switch_StopGo
    expect(path && post && sw).toBeTruthy();
    const pre = { x: post!.xpos, y: post!.ypos };
    const ball = g.objects.byName('football')!;
    ball.refA = null; ball.state = 2; ball.physicsStationary = false;
    PhysicsWorld.setPosPx(ball.body!, sw!.xpos, sw!.ypos, 0); // ball overlaps the switch
    PhysicsWorld.setVelPx(ball.body!, 0, 0);
    for (let i = 0; i < 60; i++) step(g);
    const moved = Math.hypot(post!.xpos - pre.x, post!.ypos - pre.y);
    expect(moved).toBeGreaterThan(5);
  });
});
