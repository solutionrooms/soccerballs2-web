// Headless physics acceptance: load level 1, kick the ball at the goal, and
// assert the goal sensor fires — proves the Nape->planck mapping produces a
// playable trajectory with the original kick constants.
import { describe, it, expect } from 'vitest';
import { PhysicsWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel } from './level-loader';
import { footballLaunch } from './behaviors/core';
import { VARS } from './defs';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

function makeContext(): GameContext {
  const physics = new PhysicsWorld(
    (objectsJson as unknown as { materials: ConstructorParameters<typeof PhysicsWorld>[0] }).materials,
  );
  // update-path stubs: audio is fire-and-forget, atlas only needs frameCount
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
    bounds: { left: -2000, top: -2000, right: 2000, bottom: 2000 },
  };
}

function stepWorld(g: GameContext): void {
  for (const go of g.objects.list) {
    if (go.body && go.physicsStationary) {
      PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
      PhysicsWorld.setVelPx(go.body, 0, 0);
      go.body.setAngularVelocity(0);
    }
  }
  g.physics.step();
  for (const go of g.objects.list) {
    if (go.body && !go.physicsStationary && go.body.isDynamic()) {
      const p = PhysicsWorld.getPosPx(go.body);
      go.xpos = p.x;
      go.ypos = p.y;
      go.dir = p.rot;
    }
  }
  for (const c of g.physics.takeContacts()) {
    const a = c.a.owner as GameObj;
    const b = c.b.owner as GameObj;
    if (a?.onHitFn) a.onHitFn(a, b, g, c.sensor);
    if (b?.onHitFn) b.onHitFn(b, a, g, c.sensor);
  }
  for (const go of g.objects.list) {
    if (!go.dead && go.updateFn) go.updateFn(go, g);
  }
  g.objects.flushAdds();
  g.objects.removeDead(g.physics);
}

describe('level 1 headless simulation', () => {
  it('ball rests on the terrain (gravity + floor collision work)', () => {
    const g = makeContext();
    loadLevel(g, 0);
    const ball = g.objects.byName('football')!;
    expect(ball).toBeTruthy();
    // free the ball and let it fall onto the pitch
    ball.state = 2;
    ball.physicsStationary = false;
    ball.body!.setAwake(true);
    for (let i = 0; i < 240; i++) stepWorld(g);
    // pitch surface is ~y=422; ball radius 12 -> rest around y=410
    expect(ball.ypos).toBeGreaterThan(380);
    expect(ball.ypos).toBeLessThan(440);
  });

  it('a kick toward the goal scores (goal sensor fires)', () => {
    const g = makeContext();
    loadLevel(g, 0);
    const ball = g.objects.byName('football')!;
    const goal = g.objects.byName('goal')!;
    expect(goal).toBeTruthy();
    expect(g.level.totalGoals).toBe(1);

    // ball at player's feet (state 1 snap happens on first update); aim at
    // the goal so the player faces it and the ball sits on the kick-side foot
    g.mouseX = goal.xpos;
    g.mouseY = goal.ypos - 60;
    stepWorld(g);
    stepWorld(g);
    expect(ball.state).toBe(1);

    // kick: aim straight at the goal mouth, mid power (original constants)
    const dx = goal.xpos - ball.xpos;
    const dy = goal.ypos - 30 - ball.ypos;
    const dist = Math.hypot(dx, dy);
    const spd = Math.min(VARS.kick_power1, Math.max(VARS.kick_power0, (dist / 300) * VARS.kick_power1));
    footballLaunch(ball, (dx / dist) * spd, (dy / dist) * spd);
    ball.refB = g.objects.byName('player'); // Football_Launch caller sets lastPlayerToHaveBall

    for (let i = 0; i < 360 && g.level.numGoalsScored === 0; i++) stepWorld(g);
    expect(g.level.numGoalsScored).toBe(1);
  });

  it('ref gets hit when the ball is kicked at him', () => {
    const g = makeContext();
    loadLevel(g, 0);
    const ball = g.objects.byName('football')!;
    const ref = g.objects.byName('ref')!;
    expect(ref).toBeTruthy();
    g.mouseX = ref.xpos; // face the ref so the ball sits on the kick side
    g.mouseY = ref.ypos - 40;
    stepWorld(g);
    stepWorld(g);

    const dx = ref.xpos - ball.xpos;
    const dy = ref.ypos - 40 - ball.ypos;
    const dist = Math.hypot(dx, dy);
    footballLaunch(ball, (dx / dist) * 120, (dy / dist) * 120);
    ball.refB = g.objects.byName('player');

    for (let i = 0; i < 360 && g.level.numRefsHit === 0; i++) stepWorld(g);
    expect(g.level.numRefsHit).toBe(1);
  });
});

describe('level 2 switch chain', () => {
  it('firing the switch moves the welded wall posts away untouched', () => {
    const g = makeContext();
    loadLevel(g, 1);
    stepWorld(g);
    const sw = g.objects.list.find((o) => o.type === 'switch_once')!;
    const posts = g.objects.list.filter((o) => o.type === 'post_movable');
    expect(sw).toBeTruthy();
    expect(posts).toHaveLength(2);
    const start = posts.map((p) => ({ x: p.xpos, y: p.ypos }));

    // let the posts settle and fall asleep on their welds first
    for (let i = 0; i < 120; i++) stepWorld(g);

    // ball hits the switch
    const ball = g.objects.byName('football')!;
    sw.onHitFn!(sw, ball, g, false);
    for (let i = 0; i < 180; i++) stepWorld(g);

    // path_object drags the welded posts away without the ball touching them
    // (the level-2 path runs vertically — the wall slides up out of the way)
    const moved = posts.map((p, i) => Math.hypot(p.xpos - start[i].x, p.ypos - start[i].y));
    expect(Math.max(...moved)).toBeGreaterThan(100);
  });
});
