// Switches & breakables ported from GameObj.as / GameObj_Base.as.
//
// Logic-link wiring (EdJoint Type_LogicLink, PhysicsBase.as:570-579): a level
// joint of type "logic" makes joint.obj1's logicLink0 point at joint.obj0 (the
// switch). Game.DoSwitch (Game.as:2748-2766) then fires the switchFunction of
// every object whose logicLink0 is the toggled switch. Here the loader must
// populate `logicLinks` (switch -> [targets]); targets register their
// switchFunction via `registerSwitchFunction` (this file does it for
// InitSwitchable_Disappear; other switchable families do their own).
//
// Switch frame labels: labels.json gives the switch clips (switch_Once,
// switch_twoWay, switch_StopGo, switch_weight, switch_Timer) frame labels
// "off" = 0 and "on" = 1, matching the literal frame = 0/1 writes in the AS3
// (the generic label machine is InitGameObj_Switch, GameObj_Base.as:884-917).
// We resolve via labelFrame() with the AS3 literals as fallback.
import objectsJson from '../../data/objects.json';
import { GameObj, GameContext } from '../gameobj';
import { PhysicsWorld } from '../../physics/world';
import type { ShapeDef, FixtureTag } from '../../physics/world';
import { FPS, PX_PER_METER } from '../defs';
import { labelFrame } from '../rig';
import { scaleTo } from '../utils';
import { setCollisionEnabled } from './core';

const objData = objectsJson as unknown as {
  physobjs: Record<string, { params: Record<string, string>; bodies: { shapes: ShapeDef[] }[] }>;
  gamelayers: Record<string, number>;
};

const S = PX_PER_METER;

// Utils.as:383-394 (RandBetweenInt is inclusive on both ends)
function randBetweenFloat(r0: number, r1: number): number {
  return Math.random() * (r1 - r0) + r0;
}
function randBetweenInt(r0: number, r1: number): number {
  return Math.floor(Math.random() * (r1 - r0 + 1)) + r0;
}

// ---------------------------------------------------------------------------
// Logic links — the level loader populates this from joints of type "logic":
// logicLinks.get(switchGO) = [target GameObjs] (joint obj0 -> [obj1, ...]).
// ---------------------------------------------------------------------------

export const logicLinks = new WeakMap<GameObj, GameObj[]>();

/** AS3 switchFunction takes no args and toggles internal state; `on` is the
 *  switch's new state for targets that want it (AS3 targets ignore it). */
export type SwitchTargetFn = (target: GameObj, on: boolean, g: GameContext) => void;
const switchFunctions = new WeakMap<GameObj, SwitchTargetFn>();

export function registerSwitchFunction(target: GameObj, fn: SwitchTargetFn): void {
  switchFunctions.set(target, fn);
}

// Game.as:2748-2766 — per matched target: call its switchFunction and play
// "sfx_switch" (the sfx is inside the loop, so it plays once per target).
export function hasSwitchFunction(target: GameObj): boolean {
  return switchFunctions.has(target);
}

export function activateLogicTarget(target: GameObj, on: boolean, g: GameContext): void {
  if (target.dead) return;
  const fn = switchFunctions.get(target);
  if (!fn) return;
  fn(target, on, g);
  g.audio.playSfx('sfx_switch'); // Game.as:2761
}

function doSwitch(switchGo: GameObj, on: boolean, g: GameContext): void {
  const targets = logicLinks.get(switchGo);
  if (!targets) return;
  for (const t of targets) activateLogicTarget(t, on, g);
}

// ---------------------------------------------------------------------------
// Shared switch state (AS3 member vars switchFlag / switch_timer / timer1)
// ---------------------------------------------------------------------------

interface SwitchData {
  switchFlag: boolean;
  switchTimer: number; // switch_timer, in frames
  timer1: number;
  frameOn: number;
  frameOff: number;
}
const switchData = new WeakMap<GameObj, SwitchData>();

function newSwitchData(go: GameObj): SwitchData {
  const d: SwitchData = {
    switchFlag: false,
    switchTimer: 0,
    timer1: 0,
    // labels.json: frame 0 "off", frame 1 "on" (AS3 hardcodes 0/1)
    frameOn: labelFrame(go.dobjName, 'on') || 1,
    frameOff: labelFrame(go.dobjName, 'off'),
  };
  switchData.set(go, d);
  return d;
}

// ---------------------------------------------------------------------------
// InitSwitch_Once (GameObj_Base.as:2890-2921)
// ---------------------------------------------------------------------------

// GameObj_Base.as:2890-2898
function switchOnceHit(go: GameObj, hitter: GameObj): void {
  if (go.state !== 0) return;
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  go.state = 1;
  go.frame = switchData.get(go)?.frameOn ?? 1;
}

// GameObj_Base.as:2899-2911 (also shared by InitGameObjLine_Switch, GameObj.as:1643)
function updateSwitchOnce(go: GameObj, g: GameContext): void {
  if (go.state === 1) {
    doSwitch(go, true, g);
    go.frame = switchData.get(go)?.frameOn ?? 1;
    go.state = 2;
  }
}

// GameObj_Base.as:2914-2921
export function initSwitch_Once(go: GameObj, g: GameContext): void {
  void g;
  newSwitchData(go);
  go.onHitFn = switchOnceHit;
  go.updateFn = updateSwitchOnce;
  go.state = 0;
}

// ---------------------------------------------------------------------------
// InitSwitch_2Way (GameObj_Base.as:2926-2979) — also used by switch_StopGo
// ---------------------------------------------------------------------------

// GameObj_Base.as:2926-2944
function switch2WayHit(go: GameObj, hitter: GameObj): void {
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  if (go.state !== 0) return;
  if (go.timer > 0) return; // 3-frame debounce
  go.timer = 3;
  const d = switchData.get(go)!;
  go.state = d.switchFlag ? 2 : 1;
}

// GameObj_Base.as:2945-2967
function updateSwitch2Way(go: GameObj, g: GameContext): void {
  const d = switchData.get(go)!;
  if (go.state === 1) {
    doSwitch(go, true, g);
    go.frame = d.frameOn;
    d.switchFlag = true;
    go.state = 0;
  } else if (go.state === 2) {
    doSwitch(go, false, g);
    go.frame = d.frameOff;
    d.switchFlag = false;
    go.state = 0;
  }
  go.timer--;
  if (go.timer <= 0) go.timer = 0;
}

// GameObj_Base.as:2970-2979
export function initSwitch_2Way(go: GameObj, g: GameContext): void {
  void g;
  newSwitchData(go);
  go.onHitFn = switch2WayHit;
  go.updateFn = updateSwitch2Way;
  go.state = 0;
  go.timer = 0;
}

// ---------------------------------------------------------------------------
// InitSwitch_Weight (GameObj_Base.as:2985-3053) — stays down while something
// rests on it; pops back up 4 frames after the last persistent contact.
// ---------------------------------------------------------------------------

// GameObj_Base.as:2996-3014
function switchWeightHit(go: GameObj, hitter: GameObj): void {
  if (!hitter.body) return; // AS3: goHitter.physobj == null
  if (go.state !== 0) return;
  const d = switchData.get(go)!;
  if (!d.switchFlag) go.state = 1;
}

// SwitchWeightHitPersist (GameObj_Base.as:2985-2995) runs from Nape's ongoing
// contact handler (NapeContacts.as:233-243). The web port has begin-contact
// only, so we scan the body's touching contacts each update instead.
function switchWeightPersistScan(go: GameObj): void {
  if (go.state !== 2 || !go.body) return;
  for (let edge = go.body.getContactList(); edge; edge = edge.next) {
    if (!edge.contact.isTouching()) continue;
    const other = edge.other;
    if (!other || !other.isDynamic()) continue;
    // GameObj_Base.as:2992 — micro-nudge keeps the hitter awake so contact
    // callbacks keep firing (planck: a non-zero setLinearVelocity wakes it)
    const v = PhysicsWorld.getVelPx(other);
    PhysicsWorld.setVelPx(other, v.x, v.y - 0.00000001);
    go.timer = 4; // GameObj_Base.as:2994
  }
}

// GameObj_Base.as:3015-3041
function updateSwitchWeight(go: GameObj, g: GameContext): void {
  switchWeightPersistScan(go);
  const d = switchData.get(go)!;
  if (go.state === 1) {
    doSwitch(go, true, g);
    go.frame = d.frameOn;
    d.switchFlag = true;
    go.state = 2;
    go.timer = 4;
  } else if (go.state === 2) {
    go.timer--;
    if (go.timer <= 0) {
      doSwitch(go, false, g);
      go.frame = d.frameOff;
      d.switchFlag = false;
      go.state = 0;
    }
  }
}

// GameObj_Base.as:3044-3053
export function initSwitch_Weight(go: GameObj, g: GameContext): void {
  void g;
  newSwitchData(go);
  go.onHitFn = switchWeightHit;
  go.updateFn = updateSwitchWeight;
  go.state = 0;
}

// ---------------------------------------------------------------------------
// InitSwitch_Timer (GameObj_Base.as:3058-3115) — on for switch_time seconds;
// the clip (switch_Timer, 74 frames) is a dial scrubbed from the last frame
// back to frame 1 as the time runs out.
// ---------------------------------------------------------------------------

// GameObj_Base.as:3058-3068
function switchTimerHit(go: GameObj, hitter: GameObj): void {
  if (go.state !== 0) return;
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  const d = switchData.get(go)!;
  go.state = 1;
  go.timer = d.switchTimer;
}

// GameObj_Base.as:3069-3102
function updateSwitchTimer(go: GameObj, g: GameContext): void {
  const d = switchData.get(go)!;
  if (go.state === 1) {
    doSwitch(go, true, g);
    go.frame = d.frameOn; // AS3: frame = 1
    go.state = 2;
    d.timer1 = 8;
    d.switchFlag = true;
  } else if (go.state === 2) {
    const minFrame = 1;
    const maxFrame = g.atlas.frameCount(go.dobjName) - 1;
    go.frame = Math.floor(scaleTo(minFrame, maxFrame, 0, d.switchTimer, go.timer));
    go.timer--;
    if (go.timer <= 0) {
      doSwitch(go, false, g);
      go.frame = d.frameOff;
      go.state = 0;
      d.switchFlag = false;
    }
    // GameObj_Base.as:3096-3100 — vestigial 8-frame tick (no side effect)
    d.timer1--;
    if (d.timer1 <= 0) d.timer1 = 8;
  }
}

// GameObj_Base.as:3105-3115
export function initSwitch_Timer(go: GameObj, g: GameContext): void {
  void g;
  const d = newSwitchData(go);
  // switch_time is in seconds; objects.json physobjs[type].params holds the
  // editor default (1.5) when the instance doesn't override it
  const defTime = Number(objData.physobjs[go.type]?.params['switch_time'] ?? 0) || 0;
  d.switchTimer = go.paramNum('switch_time', defTime) * FPS;
  go.onHitFn = switchTimerHit;
  go.updateFn = updateSwitchTimer;
  go.state = 0;
}

// ---------------------------------------------------------------------------
// InitSwitchable_Disappear (GameObj_Base.as:3121-3162) — switch-linked block
// that animates away (clip Switchable_Block_Disappear, 9 frames) and stops
// colliding; toggles back on the next switch pulse. Always starts solid
// (switchFlag = false, frameVel = -1 holds frame 0).
// ---------------------------------------------------------------------------

interface DisappearData {
  switchFlag: boolean;
}
const disappearData = new WeakMap<GameObj, DisappearData>();

// GameObj_Base.as:712-727 PlayAnimation — frame clamped to [0, numFrames-1]
function playFrames(go: GameObj, g: GameContext): boolean {
  const maxframe = g.atlas.frameCount(go.dobjName) - 1;
  go.frame += go.frameVel;
  if (go.frame > maxframe) {
    go.frame = maxframe;
    return true;
  }
  if (go.frame < 0) {
    go.frame = 0;
    return true;
  }
  return false;
}

// GameObj_Base.as:3121-3132 (the AS3 switchFunction — toggles via its own
// switchFlag, ignoring the switch's state)
function switchableDisappearSwitched(go: GameObj): void {
  if (go.state !== 0) return;
  const d = disappearData.get(go)!;
  go.state = d.switchFlag ? 2 : 1;
}

// GameObj_Base.as:3133-3153
function updateSwitchableDisappear(go: GameObj, g: GameContext): void {
  const d = disappearData.get(go)!;
  if (go.state === 0) {
    playFrames(go, g);
  } else if (go.state === 1) {
    setCollisionEnabled(go, false); // SetBodyCollisionMask(0, 0)
    go.state = 0;
    d.switchFlag = true;
    go.frameVel = 1;
  } else if (go.state === 2) {
    setCollisionEnabled(go, true); // SetBodyCollisionMask(0, 15) — shapes' colMask is 15
    go.state = 0;
    d.switchFlag = false;
    go.frameVel = -1;
  }
}

// GameObj_Base.as:3154-3162
export function initSwitchable_Disappear(go: GameObj, g: GameContext): void {
  void g;
  go.frameVel = -1;
  // AS3 also reads GetParamString("switch_name","") for the id-based
  // DoGameObjSwitch path; no level instance uses it (links are logic joints)
  disappearData.set(go, { switchFlag: false });
  go.updateFn = updateSwitchableDisappear;
  registerSwitchFunction(go, (t) => switchableDisappearSwitched(t));
}

// ---------------------------------------------------------------------------
// Breakables (GameObj.as:3154-3319) — break into physics "broken_piece"
// objects when hit hard enough by the ball.
// ---------------------------------------------------------------------------

interface PieceDef {
  x: number;
  y: number;
  clip: string;
}
interface BreakData {
  pieces: PieceDef[];
  mvx: number; // movementVec (impulse * 0.03)
  mvy: number;
}
const breakData = new WeakMap<GameObj, BreakData>();

interface ImpactInfo {
  other: GameObj;
  l: number; // |normal impulse| / hitter mass, px/s (GameObj.as:3299-3305)
  jx: number; // impulse vector applied to the breakable, mass*px/s
  jy: number;
}
const lastImpact = new WeakMap<GameObj, ImpactInfo>();
const impactTargets = new WeakSet<GameObj>();
const hookedWorlds = new WeakSet<object>();

// Nape exposes the accumulated contact impulse (nape_bodies[0].normalImpulse,
// GameObj.as:3299) but planck has no impulse data at begin-contact, so we
// estimate it from pre-solve velocities with the standard restitution impulse
// j = (1 + e) * vRel_n / (invMassA + invMassB).
// TODO(fidelity): compare the 150-threshold break feel side by side with AS3.
function ensureImpactHook(g: GameContext): void {
  const world = g.physics.world;
  if (hookedWorlds.has(world)) return;
  hookedWorlds.add(world);
  world.on('begin-contact', (contact) => {
    const fa = contact.getFixtureA();
    const fb = contact.getFixtureB();
    if (fa.isSensor() || fb.isSensor()) return;
    const a = (fa.getUserData() as FixtureTag | null)?.owner as GameObj | undefined;
    const b = (fb.getUserData() as FixtureTag | null)?.owner as GameObj | undefined;
    if (!a || !b) return;
    const aIsTarget = impactTargets.has(a);
    const bIsTarget = impactTargets.has(b);
    if (!aIsTarget && !bIsTarget) return;
    const wm = contact.getWorldManifold(null);
    if (!wm) return;
    const bodyA = fa.getBody();
    const bodyB = fb.getBody();
    const va = bodyA.getLinearVelocity();
    const vb = bodyB.getLinearVelocity();
    const n = wm.normal; // points from A to B
    const vRel = Math.abs((vb.x - va.x) * n.x + (vb.y - va.y) * n.y) * S; // px/s
    const invA = bodyA.isDynamic() && bodyA.getMass() > 0 ? 1 / bodyA.getMass() : 0;
    const invB = bodyB.isDynamic() && bodyB.getMass() > 0 ? 1 / bodyB.getMass() : 0;
    if (invA + invB === 0) return;
    const e = contact.getRestitution();
    const j = ((1 + e) * vRel) / (invA + invB); // ~ Nape normalImpulse length
    if (aIsTarget && bodyB.getMass() > 0) {
      lastImpact.set(a, { other: b, l: j / bodyB.getMass(), jx: -n.x * j, jy: -n.y * j });
    }
    if (bIsTarget && bodyA.getMass() > 0) {
      lastImpact.set(b, { other: a, l: j / bodyA.getMass(), jx: n.x * j, jy: n.y * j });
    }
  });
}

// GameObj.as:3289-3319
function onHitBreakablePieces(go: GameObj, hitter: GameObj): void {
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  const imp = lastImpact.get(go);
  const l = imp && imp.other === hitter ? imp.l : 0;
  if (l < 150) return; // GameObj.as:3309
  go.frame = 0;
  go.frameVel = 1;
  go.state = 1;
  go.onHitFn = null;
  // movementVec.SetFromDxDy(impulse); movementVec.speed *= 0.03 (GameObj.as:3315-3316)
  const d = breakData.get(go)!;
  d.mvx = (imp?.jx ?? 0) * 0.03;
  d.mvy = (imp?.jy ?? 0) * 0.03;
}

// GameObj.as:3238-3288
function updateBreakablePieces(go: GameObj, g: GameContext): void {
  if (go.state === 1) {
    g.audio.playSfx('sfx_wood_snap' + randBetweenInt(1, 4)); // GameObj.as:3246-3247
    // the break_sfx_name (objects.json sfxBreak) branch is dead code in the
    // AS3 (GameObj.as:3249-3257) — the random wood snap always plays
    go.dead = true; // RemoveObject(RemovePhysObj()) — removeDead() frees the body
    const d = breakData.get(go)!;
    const rad = (go.dir * Math.PI) / 180; // AS3 dir is radians; ours is degrees
    const cos = Math.cos(rad);
    const sin = Math.sin(rad);
    for (const def of d.pieces) {
      // piece offsets rotated by the breakable's dir (GameObj.as:3269-3274;
      // note the AS3 ignores scale here, and spawns pieces at scale 1)
      const x = go.xpos + def.x * cos - def.y * sin;
      const y = go.ypos + def.x * sin + def.y * cos;
      // random scatter impulse + movementVec (GameObj.as:3277-3281)
      const ang = Math.random() * Math.PI * 2; // Utils.RandCircle
      const spd = randBetweenFloat(1, 2);
      spawnBrokenPiece(g, x, y, go.dir, def.clip, Math.cos(ang) * spd + d.mvx, Math.sin(ang) * spd + d.mvy);
    }
  }
}

// PhysicsBase.AddPhysObjAt("broken_piece", x, y, RadToDeg(dir), 1) +
// PostInitBreakable_Piece (GameObj.as:3283-3284, 3351-3360)
function spawnBrokenPiece(
  g: GameContext,
  x: number,
  y: number,
  dirDeg: number,
  clip: string,
  jx: number,
  jy: number,
): GameObj {
  const go = g.objects.add();
  go.name = 'broken_piece';
  go.type = 'broken_piece';
  go.dobjName = clip;
  go.frame = 0;
  go.xpos = x;
  go.ypos = y;
  go.dir = dirDeg;
  go.zpos = objData.gamelayers['NormalObjects'] ?? 0; // broken_piece def game_layer
  const shapes = objData.physobjs['broken_piece']?.bodies[0]?.shapes ?? [];
  go.body = g.physics.createBody(go, x, y, dirDeg, 1, shapes, { fixed: false });
  go.physicsStationary = false;
  initBreakable_Piece_Physics(go, g);
  if (go.body) PhysicsWorld.applyImpulsePx(go.body, jx, jy); // GameObj_Base.ApplyImpulse
  go.timer = go.timerMax = randBetweenInt(100, 200); // GameObj.as:3358
  return go;
}

// GameObj.as:3361-3365 (update: 3341-3349, render: 3323-3326)
export function initBreakable_Piece_Physics(go: GameObj, g: GameContext): void {
  void g;
  go.updateFn = (p) => {
    p.timer--;
    if (p.timer <= 0) p.dead = true; // RemoveObject(RemovePhysObj)
  };
  go.renderFn = (p, gg, ctx) => {
    // RenderDispObjNormallyAlpha — the alpha fade is commented out in the AS3
    // (GameObj.as:3348), so alpha stays 1
    if (!p.visible) return;
    gg.atlas.draw(ctx, p.dobjName, p.frame | 0, p.xpos, p.ypos, { rot: p.dir, scale: p.scale });
  };
}

// GameObj.as:3229-3237 Init_Breakable_Pieces
function initBreakablePieces(go: GameObj, g: GameContext, pieces: PieceDef[]): void {
  ensureImpactHook(g);
  impactTargets.add(go);
  breakData.set(go, { pieces, mvx: 0, mvy: 0 });
  go.updateFn = updateBreakablePieces;
  go.onHitFn = onHitBreakablePieces;
  go.frame = 0;
  // health = maxHealth = 1 (GameObj.as:3236) — never read by this family
}

// GameObj.as:3154-3168 — note both crate and crateSmall (clip woodenCrate2)
// break into woodenCrate1_part* pieces, exactly as the AS3 does
export function initBreakable_WoodenCrate(go: GameObj, g: GameContext): void {
  const x = -18;
  const y = -16;
  initBreakablePieces(go, g, [
    { x: x + 7, y: y + 5, clip: 'woodenCrate1_part1' },
    { x: x + 30, y: y + 4, clip: 'woodenCrate1_part2' },
    { x: x + 42, y: y + 9, clip: 'woodenCrate1_part3' },
    { x: x + 5, y: y + 25, clip: 'woodenCrate1_part4' },
    { x: x + 17, y: y + 15, clip: 'woodenCrate1_part5' },
    { x: x + 33, y: y + 19, clip: 'woodenCrate1_part6' },
    { x: x + 19, y: y + 28, clip: 'woodenCrate1_part7' },
    { x: x + 36, y: y + 30, clip: 'woodenCrate1_part8' },
  ]);
}

// GameObj.as:3170-3177
export function initBreakable_WoodenPost(go: GameObj, g: GameContext): void {
  initBreakablePieces(go, g, [
    { x: 0, y: -20, clip: 'woodPost0_part3' },
    { x: 0, y: -1, clip: 'woodPost0_part2' },
    { x: 0, y: 19, clip: 'woodPost0_part1' },
  ]);
}

// ---------------------------------------------------------------------------
// InitGameObjLine_Switch (GameObj.as:1628-1647) — invisible polymat line
// ("poly_switch": senCat 1 / senMask 15 sensor) acting as a one-shot switch.
// Reuses UpdateSwitchOnce for the DoSwitch pulse.
// ---------------------------------------------------------------------------

// GameObj.as:1628-1636
function gameObjLineSwitchHit(go: GameObj, hitter: GameObj): void {
  if (go.state !== 0) return;
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  go.state = 1;
  go.onHitFn = null;
}

// GameObj.as:1637-1647
export function initGameObjLine_Switch(go: GameObj, g: GameContext): void {
  void g;
  go.name = 'invisible_switch';
  go.onHitFn = gameObjLineSwitchHit;
  go.updateFn = updateSwitchOnce;
  go.state = 0;
  go.visible = false;
}

// ---------------------------------------------------------------------------

export const registry: Record<string, (go: GameObj, g: GameContext) => void> = {
  InitSwitch_Once: initSwitch_Once,
  InitSwitch_2Way: initSwitch_2Way,
  InitSwitch_Weight: initSwitch_Weight,
  InitSwitch_Timer: initSwitch_Timer,
  InitSwitchable_Disappear: initSwitchable_Disappear,
  InitBreakable_WoodenCrate: initBreakable_WoodenCrate,
  InitBreakable_WoodenPost: initBreakable_WoodenPost,
  InitBreakable_Piece_Physics: initBreakable_Piece_Physics,
  InitGameObjLine_Switch: initGameObjLine_Switch,
};
