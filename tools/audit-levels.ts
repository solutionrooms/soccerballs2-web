// All-levels audit: catches the classes of bugs found during playtesting —
// unregistered behaviors (editor art leaking through), unresolvable
// switch/joint/path wiring, missing atlas clips, missing sfx, broken win
// conditions, and dynamic objects escaping the level in simulation.
// Run: npx tsx tools/audit-levels.ts
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { PhysicsWorld } from '../src/physics/world';
import { GameObjects, GameContext, GameObj } from '../src/game/gameobj';
import { LevelState } from '../src/game/game-state';
import { loadLevel, LEVELS, REGISTRY } from '../src/game/level-loader';
import { logicLinks, hasSwitchFunction } from '../src/game/behaviors/switches';
import { hasPathLine } from '../src/game/behaviors/movers';
import objectsJson from '../src/data/objects.json';
import atlasJson from '../src/data/atlas.json';
import type { GameAudio } from '../src/audio/audio';
import type { Atlas } from '../src/render/atlas';

const objects = objectsJson as unknown as {
  physobjs: Record<
    string,
    {
      initFunction: string | null;
      sfxBreak: string;
      sfxHit: string;
      bodies: { fixed: boolean; graphics: { clip: string }[]; shapes: unknown[] }[];
    }
  >;
  polymats: Record<string, { initFunction: string }>;
};
const atlasObjects = (atlasJson as { objects: Record<string, unknown> }).objects;
const ROOT = join(import.meta.dirname, '..');

function makeContext(): GameContext {
  const physics = new PhysicsWorld(
    (objectsJson as unknown as { materials: ConstructorParameters<typeof PhysicsWorld>[0] }).materials,
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
    if (a?.onHitFn && !a.dead) a.onHitFn(a, b, g, c.sensor);
    if (b?.onHitFn && !b.dead) b.onHitFn(b, a, g, c.sensor);
  }
  for (const go of g.objects.list) {
    if (!go.dead && go.updateFn) go.updateFn(go, g);
  }
  g.objects.flushAdds();
  g.objects.removeDead(g.physics);
}

const totals = new Map<string, number>();
let levelsWithIssues = 0;

for (let li = 0; li < LEVELS.length; li++) {
  const def = LEVELS[li];
  const issues: string[] = [];

  // ---- static checks on level data ----
  const seenMissingInit = new Set<string>();
  for (const inst of def.instances) {
    const po = objects.physobjs[inst.type];
    if (!po) {
      issues.push(`unknown physobj type "${inst.type}"`);
      continue;
    }
    if (po.initFunction && !REGISTRY[po.initFunction] && !seenMissingInit.has(po.initFunction)) {
      seenMissingInit.add(po.initFunction);
      issues.push(`UNREGISTERED init "${po.initFunction}" (type ${inst.type})`);
    }
    const clip = po.bodies[0]?.graphics[0]?.clip;
    // rig-rendered characters reference SWF rig clips, not atlas objects
    const RIG_CLIPS = new Set(['player', 'ref', 'keeper', 'opponent', 'opponentWalk']);
    if (clip && !atlasObjects[clip] && !RIG_CLIPS.has(clip)) {
      issues.push(`missing atlas clip "${clip}" (type ${inst.type})`);
    }
    for (const sfx of [po.sfxBreak, po.sfxHit]) {
      if (sfx && !existsSync(join(ROOT, `public/assets/audio/sfx/${sfx}.ogg`))) {
        issues.push(`missing sfx "${sfx}" (type ${inst.type})`);
      }
    }
  }
  for (const line of def.lines) {
    const matName = line.params['line_material'] ?? '';
    const polymat = objects.polymats[matName];
    if (!polymat) issues.push(`unknown polymat "${matName}"`);
  }

  // ---- load and inspect wiring ----
  const g = makeContext();
  let loaded;
  try {
    loaded = loadLevel(g, li);
  } catch (e) {
    issues.push(`LOAD THREW: ${e}`);
    report(li, def.name, issues);
    continue;
  }
  g.bounds = loaded.scrollBounds;

  // path objects resolve their lines
  for (const go of g.objects.list) {
    if (go.type === 'path_object') {
      const lineId = go.param('path_line');
      if (!lineId) issues.push(`path_object ${go.id} has no path_line`);
      else if (!hasPathLine(lineId)) issues.push(`path_object ${go.id}: line "${lineId}" not registered`);
    }
  }

  // logic joints resolve + targets respond
  for (const joint of def.joints) {
    const goA = g.objects.list.find((o) => o.id === joint.obj0) ?? null;
    const goB = g.objects.list.find((o) => o.id === joint.obj1) ?? null;
    if (joint.type === 'logic') {
      if (!goA) issues.push(`logic joint: switch "${joint.obj0}" not found`);
      if (!goB) issues.push(`logic joint: target "${joint.obj1}" not found`);
      // targets without a switchFunction are inert in the original too
      // (Game.DoSwitch only calls registered handlers) — only flag types the
      // original DID handle
      const ORIGINAL_HANDLED = new Set(['helptext_text', 'switchable_block', 'path_object', 'cog']);
      if (goA && goB && !hasSwitchFunction(goB) && !goB.dead && ORIGINAL_HANDLED.has(goB.type)) {
        issues.push(`logic target ${goB.type} (${joint.obj1}) has NO switch handler — switch does nothing`);
      }
      if (goA && joint.obj1 && !(logicLinks.get(goA) ?? []).length) {
        issues.push(`switch ${goA.type} (${joint.obj0}) has no wired links`);
      }
    } else {
      // dangling ids exist in the shipped XML too (deleted editor objects) —
      // the original engine skipped them silently; only report ids that exist
      // nowhere in the level data
      const inData = (id: string) => def.instances.some((i) => i.id === id) || def.lines.some((l) => l.id === id);
      if (!goA && joint.obj0 && inData(joint.obj0)) issues.push(`${joint.type} joint: body0 "${joint.obj0}" not created`);
      if (!goB && joint.obj1 && inData(joint.obj1)) issues.push(`${joint.type} joint: body1 "${joint.obj1}" not created`);
      if (goA && goB && goA.body && goB.body && !goA.body.isDynamic() && !goB.body.isDynamic()) {
        issues.push(`${joint.type} joint ${joint.obj0}-${joint.obj1}: both bodies static (joint inert)`);
      }
    }
  }

  // win condition + required objects
  if (!g.objects.byName('football')) issues.push('no football');
  if (!g.objects.byName('player')) issues.push('no player');
  if (g.level.totalGoals === 0) issues.push('no goals registered — level cannot be won');

  // ---- dynamic 10s idle simulation ----
  const startPos = new Map<GameObj, { x: number; y: number }>();
  for (const go of g.objects.list) startPos.set(go, { x: go.xpos, y: go.ypos });
  try {
    for (let f = 0; f < 600; f++) stepWorld(g);
  } catch (e) {
    issues.push(`SIM THREW: ${e}`);
  }
  // objects jointed (directly or transitively) to a kinematic path mover are
  // SUPPOSED to move — exclude them from idle-drift checks
  const moving = new Set<unknown>();
  for (const go of g.objects.list) {
    if (go.body?.getType() === 'kinematic') {
      const stack = [go.body];
      while (stack.length) {
        const b = stack.pop()!;
        if (moving.has(b)) continue;
        moving.add(b);
        for (let je = b.getJointList(); je; je = je.next) {
          if (je.other) stack.push(je.other);
        }
      }
    }
  }
  const margin = 200;
  for (const go of g.objects.list) {
    if (go.dead || !go.body || !go.body.isDynamic() || go.physicsStationary) continue;
    if (go.name === 'football') continue; // ball is parked at player's feet
    if (moving.has(go.body)) continue; // riding/welded to a moving platform
    if (go.type.startsWith('ball_')) continue; // loose balls legitimately roll
    if (go.ypos > loaded.scrollBounds.bottom + margin) {
      issues.push(`${go.type} (${go.id || 'anon'}) FELL OUT of the level (y=${go.ypos | 0})`);
    }
    const s = startPos.get(go);
    if (s && Math.hypot(go.xpos - s.x, go.ypos - s.y) > 150 && go.type !== 'spikyball') {
      issues.push(`${go.type} (${go.id || 'anon'}) drifted ${Math.hypot(go.xpos - s.x, go.ypos - s.y) | 0}px while idle`);
    }
  }

  report(li, def.name, issues);
}

function report(li: number, name: string, issues: string[]): void {
  if (!issues.length) return;
  levelsWithIssues++;
  console.log(`\n== level ${li + 1} "${name}" ==`);
  for (const i of issues) {
    console.log('  - ' + i);
    const key = i.replace(/"[^"]*"|\(.*?\)|\d+/g, '#');
    totals.set(key, (totals.get(key) ?? 0) + 1);
  }
}

console.log('\n---- summary ----');
console.log(`${levelsWithIssues}/${LEVELS.length} levels with issues`);
for (const [k, v] of [...totals.entries()].sort((a, b) => b[1] - a[1])) {
  console.log(String(v).padStart(4), k);
}
