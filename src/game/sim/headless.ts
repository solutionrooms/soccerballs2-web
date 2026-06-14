// Headless simulation primitives shared by the route solver (tools/solve-routes.ts),
// the regression test (routes.test.ts) and the in-game visual replay. No rendering,
// no DOM: a real Nape world stepped exactly like GameScene.update so a route that
// wins here wins in the browser too.
//
// Requires globalThis.NapeWorld to be loaded first (import '../nape-test-setup' in
// Node; the browser preloads it via ensureNapeLoaded()).
import { PhysicsWorld, NapePhysWorld, type PhysWorld, type MaterialDef } from '../../physics/world';
import { GameObjects, GameContext, GameObj } from '../gameobj';
import { LevelState } from '../game-state';
import { loadLevel, LoadedLevel, LEVELS } from '../level-loader';
import objectsJson from '../../data/objects.json';
import { VARS } from '../defs';
import type { Atlas } from '../../render/atlas';
import type { GameAudio } from '../../audio/audio';

const MATERIALS = (objectsJson as unknown as { materials: Record<string, MaterialDef> }).materials;

// Minimal stand-ins. renderFn is never called headless; the only atlas method any
// updateFn touches is frameCount (smoke puff lifetime), and audio is fire-and-forget.
const MOCK_ATLAS = { frameCount: () => 8, draw: () => {}, drawTinted: () => {} } as unknown as Atlas;
const MOCK_AUDIO = { playSfx: () => {}, playMusic: () => {}, setMusicOn: () => {} } as unknown as GameAudio;

export interface HeadlessGame {
  g: GameContext;
  loaded: LoadedLevel;
}

// NOTE: a fresh Nape world per trial leaks (~0.8MB retained per loadLevel — Nape's
// static pools never return the bodies, and Space.clear() was DCE-stripped so the
// world can't be reset). The solver works around this by recycling worker
// processes after a bounded number of trials (see tools/solve-worker.ts), keeping
// each process in the fast zone. Tests run few enough trials per process to be
// unaffected.

/** Build a fresh headless context with a new Nape world. */
export function createHeadlessContext(): GameContext {
  const physics: PhysWorld = new NapePhysWorld(MATERIALS);
  return {
    physics,
    atlas: MOCK_ATLAS,
    level: new LevelState(),
    audio: MOCK_AUDIO,
    objects: new GameObjects(),
    mouseX: 0,
    mouseY: 0,
    cameraX: 0,
    cameraY: 0,
    bounds: { left: -2000, top: -2000, right: 2000, bottom: 2000 },
    aimOverride: null,
  };
}

/**
 * Load a level headless and step until the ball is held and ready to kick.
 * Mirrors GameScene.onEnter (failKicks/goldKicks/scrollBounds/phase='play').
 */
export function loadLevelHeadless(index: number): HeadlessGame {
  const g = createHeadlessContext();
  const loaded = loadLevel(g, index);
  g.level.maxKicks = loaded.def.failKicks;
  g.level.goldKicks = loaded.def.goldKicks;
  g.bounds = loaded.scrollBounds;
  g.level.phase = 'play';
  // ball spawns in state 0; one update snaps it to the nearest player (state 1)
  for (let i = 0; i < 8 && !ballReady(g); i++) stepWorld(g);
  return { g, loaded };
}

/** One fixed 60 Hz tick: park stationary -> step -> write back -> contacts -> object logic.
 *  Byte-for-byte the physics/logic block of GameScene.update (lines 182-213); win/fail
 *  detection is intentionally left to the caller (levelWon/levelLost). */
export function stepWorld(g: GameContext): void {
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
  for (const go of g.objects.list) {
    if (!go.dead && go.updateFn) go.updateFn(go, g);
  }
  g.objects.flushAdds();
  g.objects.removeDead(g.physics);
}

/** The ball is held by a player and can be kicked this frame. */
export function ballReady(g: GameContext): boolean {
  const ball = g.objects.byName('football');
  return !!ball && ball.state === 1 && !!ball.refA && ball.refA.state === 1;
}

/** Win condition, mirroring GameScene.update lines 218-219 (Game.as:1524-1556). */
export function levelWon(g: GameContext): boolean {
  const lv = g.level;
  const gotRefs = lv.totalRefs === 0 || lv.numRefsHit >= lv.totalRefs;
  return lv.totalGoals > 0 && lv.numGoalsScored >= lv.totalGoals && gotRefs;
}

/** The level has been failed (ran out of kicks; updateFootball froze the ball at state 999). */
export function levelLost(g: GameContext): boolean {
  return (g.level.phase === 'complete' || g.level.phase === 'end') && !g.level.success && !levelWon(g);
}

/**
 * Commit a kick this frame: set the touch-pad aim override (exact angle + power)
 * and raise doKick, exactly as a real tap would. updatePlayer consumes both in the
 * object-logic phase of the next stepWorld; the ball launches a few animation frames
 * later on the release_ball label. Must only be called when ballReady(g).
 *
 * @param angleDeg screen-space kick angle (0 = +x / right, 90 = +y / down).
 * @param power01  0..1 -> impulse magnitude kick_power0..kick_power1 (80..200).
 */
export function applyKick(g: GameContext, angleDeg: number, power01: number): void {
  const a = (angleDeg * Math.PI) / 180;
  g.aimOverride = { dx: Math.cos(a), dy: Math.sin(a), power01: clamp01(power01) };
  g.level.doKick = true;
}

/** Distance from the ball to the nearest UNMET win objective — an unscored goal
 *  or an un-hit referee (most levels require hitting the ref as well as scoring).
 *  This is the solver's gradient toward whatever still needs doing. */
// SOLVER_GOAL_ONLY=1 makes the heuristic ignore ref distance (some levels solve
// better when the search isn't pulled toward the ref); the win condition still
// requires the ref. Used to run multiple heuristic configs and accumulate.
const GOAL_ONLY = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env?.SOLVER_GOAL_ONLY === '1';

export function ballGoalDistance(g: GameContext): number {
  const ball = g.objects.byName('football');
  if (!ball) return Infinity;
  let best = Infinity;
  for (const goal of g.objects.allByName('goal')) {
    if (goal.state !== 0) continue; // already scored
    const d = Math.hypot(goal.xpos - ball.xpos, goal.ypos - ball.ypos);
    if (d < best) best = d;
  }
  if (!GOAL_ONLY) {
    for (const ref of g.objects.allByName('ref')) {
      if (ref.state !== 0) continue; // already hit
      const d = Math.hypot(ref.xpos - ball.xpos, ref.ypos - ball.ypos);
      if (d < best) best = d;
    }
  }
  return best;
}

export function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/** Impulse magnitude for a given power01 (for reporting / ball-path tools). */
export function powerToImpulse(power01: number): number {
  return VARS.kick_power0 + (VARS.kick_power1 - VARS.kick_power0) * clamp01(power01);
}

export { LEVELS };
