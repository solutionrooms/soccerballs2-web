// Regression: level 9's intended shot — an up-right kick that banks off the
// floating rock and passes to the player above — must reach. It used to fall
// ~44px short because poly_mud's friction of 100 (an unphysical data artifact)
// over-gripped the smooth ball on the bounce and killed its upward velocity.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PhysicsWorld, NapePhysWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel } from './level-loader';
import { footballLaunch } from './behaviors/core';
import { VARS } from './defs';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

(function loadNape() {
  const path = fileURLToPath(new URL('../../public/assets/nape.js', import.meta.url));
  const src = readFileSync(path, 'utf8');
  const mod: { exports: Record<string, unknown> } = { exports: {} };
  new Function('exports', 'module', 'window', 'global', 'self', src)(mod.exports, mod, undefined, globalThis, undefined);
  (globalThis as Record<string, unknown>).NapeWorld = mod.exports.NapeWorld;
})();

function makeCtx(): GameContext {
  const mats = (objectsJson as unknown as { materials: ConstructorParameters<typeof NapePhysWorld>[0] }).materials;
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

describe('level 9 bank shot', () => {
  it('an up-right bank off the rock can pass to the player above', () => {
    let reaches = false;
    for (let deg = 56; deg <= 75 && !reaches; deg += 2) {
      const g = makeCtx();
      loadLevel(g, 8);
      for (let i = 0; i < 90; i++) step(g);
      const b = g.objects.byName('football')!;
      const up = g.objects.allByName('player').filter((p) => p.ypos < 300).reduce((x, y) => (x.ypos < y.ypos ? x : y), { ypos: 1e9 } as GameObj);
      const kicker = b.refA;
      b.xpos = 112; PhysicsWorld.setPosPx(b.body!, 112, b.ypos, 0); // aim-right => ball on player's right
      const a = (deg * Math.PI) / 180;
      footballLaunch(b, Math.cos(a) * VARS.kick_power1, -Math.sin(a) * VARS.kick_power1);
      for (let i = 0; i < 220; i++) {
        step(g);
        if (b.refA === up && (b.state === 4 || b.state === 1)) { reaches = true; break; }
        if (b.refA === kicker && b.state === 4 && i > 20) break;
      }
    }
    expect(reaches).toBe(true);
  });
});
