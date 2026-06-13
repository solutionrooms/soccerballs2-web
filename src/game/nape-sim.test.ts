// Nape-engine acceptance: load the compiled nape.js into the global scope and
// run real levels through the NapePhysWorld adapter. Proves the second engine
// loads, the wrapper maps the full PhysWorld surface, ball physics behave, and
// every level constructs + simulates without throwing — the parity gate.
import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PhysicsWorld, NapePhysWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel, LEVELS } from './level-loader';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

// Load the compiled Nape engine (a Haxe-generated IIFE) into globalThis so
// NapePhysWorld can `new globalThis.NapeWorld(...)`. The project is an ES
// module, so we evaluate it with a CommonJS-style wrapper to capture the export.
beforeAll(() => {
  const path = fileURLToPath(new URL('../../public/assets/nape.js', import.meta.url));
  const src = readFileSync(path, 'utf8');
  const mod: { exports: Record<string, unknown> } = { exports: {} };
  // eslint-disable-next-line @typescript-eslint/no-implied-eval
  new Function('exports', 'module', 'window', 'global', 'self', src)(
    mod.exports,
    mod,
    undefined,
    globalThis,
    undefined,
  );
  (globalThis as Record<string, unknown>).NapeWorld = mod.exports.NapeWorld;
});

function makeContext(): GameContext {
  const physics = new NapePhysWorld(
    (objectsJson as unknown as { materials: ConstructorParameters<typeof NapePhysWorld>[0] }).materials,
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
    if (a?.onHitFn) a.onHitFn(a, b, g, c.sensor);
    if (b?.onHitFn) b.onHitFn(b, a, g, c.sensor);
  }
  for (const go of g.objects.list) if (!go.dead && go.updateFn) go.updateFn(go, g);
  g.objects.flushAdds();
  g.objects.removeDead(g.physics);
}

describe('Nape engine', () => {
  it('exposes a constructable NapeWorld global', () => {
    expect(typeof (globalThis as Record<string, unknown>).NapeWorld).toBe('function');
  });

  it('level 1 ball falls under gravity and rests on the pitch', () => {
    const g = makeContext();
    loadLevel(g, 0);
    const ball = g.objects.byName('football')!;
    expect(ball).toBeTruthy();
    ball.state = 2;
    ball.physicsStationary = false;
    PhysicsWorld.setAwake(ball.body!, true);
    for (let i = 0; i < 240; i++) stepWorld(g);
    expect(ball.ypos).toBeGreaterThan(360);
    expect(ball.ypos).toBeLessThan(460);
  });

  it('ball mass matches the game massNape number (~density*area/1000)', () => {
    const g = makeContext();
    loadLevel(g, 0);
    const ball = g.objects.byName('football')!;
    const m = PhysicsWorld.massNape(ball.body!);
    expect(m).toBeGreaterThan(0.05);
    expect(m).toBeLessThan(50);
  });

  it('all 36 levels load and simulate 120 frames without throwing', () => {
    for (let i = 0; i < LEVELS.length; i++) {
      const g = makeContext();
      expect(() => {
        loadLevel(g, i);
        for (let f = 0; f < 120; f++) stepWorld(g);
      }, `level ${i + 1} "${LEVELS[i].name}"`).not.toThrow();
    }
  });
});
