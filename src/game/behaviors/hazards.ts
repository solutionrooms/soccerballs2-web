// Hazards behavior family ported from GameObj.as: spiky ball, wind area,
// burstable bubble, sand block (+ the shared "pop" popup and explosion helper).
import { GameObj, GameContext } from '../gameobj';
import { PhysicsWorld } from '../../physics/world';
import { VARS, FPS } from '../defs';
import { scaleTo, scaleToPreLimit } from '../utils';
import { footballLaunch, footballMoveToPlayer, parkBody } from './core';

// Utils.as:383-394
function randBetweenFloat(r0: number, r1: number): number {
  return r0 + Math.random() * (r1 - r0);
}
function randBetweenInt(r0: number, r1: number): number {
  // AS3 casts to int (truncation); operands here are non-negative spans
  return r0 + Math.trunc(Math.random() * (r1 - r0 + 1));
}

// Ease.as:45-48 Spring_Out -> Ease.as:68-74 elastic easeOut with b=0,c=1,d=1
function springOut(t: number): number {
  if (t === 0) return 0;
  if (t === 1) return 1;
  const p = 0.3; // period defaults to d * 0.3
  const s = p / 4;
  return Math.pow(2, -10 * t) * Math.sin(((t - s) * 2 * Math.PI) / p) + 1;
}

// GameObj_Base.as:712-728 PlayAnimation — frame/frameVel against the dobj's
// frame count (not the rig label system).
function playFrameAnimation(go: GameObj, g: GameContext): boolean {
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

// GOHelpers.as:19-44 DoExplosion — every live object within maxRadius gets an
// impulse of magnitude maxForce directly away from the centre (no falloff;
// quirk: an object exactly at the centre gets pushed along +x, atan2(0,0)=0).
function doExplosion(
  g: GameContext,
  orig: GameObj,
  centreX: number,
  centreY: number,
  maxRadius: number,
  maxForce: number,
): void {
  for (const go of g.objects.list) {
    if (go.dead || go === orig) continue;
    const dx = go.xpos - centreX;
    const dy = go.ypos - centreY;
    if (Math.sqrt(dx * dx + dy * dy) > maxRadius) continue;
    const rot = Math.atan2(dy, dx);
    if (go.body) {
      PhysicsWorld.applyImpulsePx(go.body, Math.cos(rot) * maxForce, Math.sin(rot) * maxForce);
    }
  }
}

// ---------------------------------------------------------------------------
// Pop popup (GameObj.as:6550-6567 UpdatePopPopup/InitPopPopup)
// Both AS3 call sites spawn it at zpos -10000 (GameObj.as:4825, 6707).
// ---------------------------------------------------------------------------

export function spawnPopPopup(g: GameContext, x: number, y: number): void {
  const go = g.objects.add();
  go.name = 'popup';
  go.dobjName = 'popup_pop'; // GameObj.as:6564
  go.xpos = x;
  go.ypos = y;
  go.zpos = -10000;
  go.timerMax = go.timer = FPS * 0.5; // GameObj.as:6565
  const scaleMax = 1; // GameObj.as:6566
  go.scale = 0;
  go.updateFn = (p) => {
    p.timer--;
    if (p.timer <= 0) p.dead = true;
    const f = springOut(scaleTo(1, 0, 0, p.timerMax, p.timer));
    p.scale = f * scaleMax;
  };
  go.renderFn = (p, gg, ctx) => {
    gg.atlas.draw(ctx, p.dobjName, 0, p.xpos, p.ypos, { scale: p.scale });
  };
}

// ---------------------------------------------------------------------------
// Spiky ball (GameObj.as:6691-6697 InitSpikyBall, 6653-6690 UpdateSpikyBall)
// The football-popping logic lives in OnHit_Football (GameObj.as:4817-4838);
// core.ts owns the football's onHitFn, so the same contact is handled here
// from the spiky ball's side (begin-contact fires for both owners).
// ---------------------------------------------------------------------------

export function initSpikyBall(go: GameObj): void {
  go.name = 'spikyball';
  go.updateFn = updateSpikyBall;
  go.onHitFn = onHitSpikyBall;
}

// GameObj.as:4817-4838 OnHit_Football, spikyball branch: only pops the ball
// in flight (state 2); pop popup at the ball, then return it to the last
// player to have it. No pop sfx in the AS3 — Football_MoveToPlayer plays
// sfx_ball_return.
function onHitSpikyBall(_spiky: GameObj, hitter: GameObj, g: GameContext): void {
  if (hitter.name !== 'football') return;
  if (hitter.state !== 2) return;
  spawnPopPopup(g, hitter.xpos, hitter.ypos);
  const player = hitter.refB ?? hitter.refA; // football_lastPlayerToHaveBall
  if (player) footballMoveToPlayer(hitter, player, g);
}

// GameObj.as:6653-6690 UpdateSpikyBall
function updateSpikyBall(go: GameObj, g: GameContext): void {
  if (go.state === 0) {
    const b = g.bounds; // Game.boundingRectangle
    if (go.xpos < b.left || go.xpos > b.right || go.ypos < b.top || go.ypos > b.bottom) {
      go.dead = true; // RemoveObject(RemovePhysObj) — removeDead destroys the body
    }
  } else if (go.state === 200) {
    // in cannon — entered via Football_InitHoldInCannon (GameObj.as:4581-4586):
    // the cannon's OnHit must set state=200, timer=GameVars.cannonHoldTime and
    // refA=cannon on this object.
    const cannon = go.refA;
    if (!cannon) return;
    go.visible = true;
    go.xpos = cannon.xpos;
    go.ypos = cannon.ypos;
    parkBody(go); // PhysicsSetStationary
    go.timer--;
    if (go.timer <= 0) {
      const ang = (cannon.dir * Math.PI) / 180 - Math.PI / 2; // AS3 dir is radians
      let speed = VARS.cannonLaunchForce;
      if (go.body) speed *= PhysicsWorld.massNape(go.body); // GetBodyMass(0)
      go.timer = go.timerMax = FPS * 3;
      // Cannon_Fired (GameObj.as:4497-4501) — TODO: move into the cannon
      // family's exported helper once it exists.
      cannon.state = 2;
      cannon.timer = cannon.timerMax = FPS;
      go.visible = true;
      // footballLaunch un-parks the body (updateFromPhysicsFunction = null)
      footballLaunch(go, Math.cos(ang) * speed, Math.sin(ang) * speed);
    }
  }
}

// ---------------------------------------------------------------------------
// Wind (GameObj.as:2014-2028 InitWind, 1992-2013 UpdateWind,
// 1978-1991 OnHit_Wind, 2036-2075 Render/Update/InitWindPart)
// ---------------------------------------------------------------------------

// force_strength is captured at init like the AS3 instance field
const windStrength = new WeakMap<GameObj, number>();

export function initWind(go: GameObj): void {
  go.name = 'wind';
  go.timer = randBetweenInt(10, 30);
  windStrength.set(go, VARS.windforce); // Vars.GetVarAsNumber("windforce")
  go.state = 0;
  go.onHitFn = (wind, hitter) => windApplyForce(wind, hitter);
  go.updateFn = updateWind;
  // AS3 sets visible = false unconditionally (the usedebug branch is dead code)
  go.visible = false;
}

function windBodyAngle(wind: GameObj): number {
  // GetBodyAngle(0) — nape body rotation in radians
  return wind.body ? PhysicsWorld.bodyAngleRad(wind.body) : (wind.dir * Math.PI) / 180;
}

// OnHit_Wind (GameObj.as:1978-1991) — nape ApplyForce (GameObj_Base.as:1618-1624)
// adds straight onto body velocity, so this is a px/s velocity delta per call.
function windApplyForce(wind: GameObj, hitter: GameObj): void {
  if (hitter.collisionType !== 'football' && hitter.collisionType !== 'beachball') return;
  if (!hitter.body) return;
  const ang = windBodyAngle(wind);
  const fs = windStrength.get(wind) ?? VARS.windforce;
  const v = PhysicsWorld.getVelPx(hitter.body);
  PhysicsWorld.setVelPx(hitter.body, v.x + Math.cos(ang) * fs, v.y + Math.sin(ang) * fs);
}


// UpdateWind (GameObj.as:1992-2013)
function updateWind(wind: GameObj, g: GameContext): void {
  // AS3 also registers OnHit_Wind as onHitPersistFunction (fires every frame
  // of overlap). The web GameObj only has begin-contact, so emulate persist by
  // testing ball centres against our fixtures each frame. Approximation: a
  // ball overlapping only at its rim is missed (begin-contact still catches
  // the first touch), and the first contact frame can apply force twice.
  if (wind.body) {
    for (const other of g.objects.list) {
      if (other.dead || !other.body) continue;
      if (other.collisionType !== 'football' && other.collisionType !== 'beachball') continue;
      if (PhysicsWorld.bodyContainsPoint(wind.body, other.xpos, other.ypos)) windApplyForce(wind, other);
    }
  }

  const ang = windBodyAngle(wind) - Math.PI / 2;
  wind.timer--;
  if (wind.timer <= 0) {
    // random offset rotated by (angle - 90deg), flash Matrix.transformPoint
    const rx = randBetweenInt(-20, 20);
    const ry = randBetweenInt(-20, 20);
    const px = wind.xpos + rx * Math.cos(ang) - ry * Math.sin(ang);
    const py = wind.ypos + rx * Math.sin(ang) + ry * Math.cos(ang);
    wind.timer = randBetweenInt(10, 20);
    // particle direction is the raw wind angle (InitWindPart receives dir)
    spawnWindPart(g, px, py, wind.zpos, windBodyAngle(wind));
  }
}

// InitWindPart/UpdateWindPart/RenderWindPart (GameObj.as:2036-2075)
function spawnWindPart(g: GameContext, x: number, y: number, z: number, angRad: number): void {
  const go = g.objects.add();
  go.name = 'windpart';
  go.xpos = x;
  go.ypos = y;
  go.zpos = z;
  go.frame = 0;
  go.frameVel = 4;
  go.dir = (angRad * 180) / Math.PI;
  go.timer = go.timerMax = randBetweenInt(8, 13);
  const speed = randBetweenFloat(1, 2);
  let xvel = Math.cos(angRad) * speed; // movementVec.X()/Y()
  let yvel = Math.sin(angRad) * speed;
  go.updateFn = (p) => {
    xvel *= 1.1;
    yvel *= 1.1;
    p.xpos += xvel;
    p.ypos += yvel;
    p.timer--;
    if (p.timer <= 0) p.dead = true;
  };
  // RenderWindPart draws a 5-pixel white cross via BitmapData.setPixel32;
  // renderFn already runs in world space (camera transform applied).
  go.renderFn = (p, _gg, ctx) => {
    const xp = Math.trunc(p.xpos); // AS3 int() truncates
    const yp = Math.trunc(p.ypos);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(xp, yp, 1, 1);
    ctx.fillRect(xp + 1, yp, 1, 1);
    ctx.fillRect(xp - 1, yp, 1, 1);
    ctx.fillRect(xp, yp + 1, 1, 1);
    ctx.fillRect(xp, yp - 1, 1, 1);
  };
}

// ---------------------------------------------------------------------------
// Burstable ball (GameObj.as:6729-6734 InitBurstableBall,
// 6702-6727 OnHitBurstableBall)
// ---------------------------------------------------------------------------

export function initBurstableBall(go: GameObj): void {
  go.collisionType = 'football'; // quirk: bursts only on the SPIKY ball, but
  go.name = 'burstable'; // collides/filters like a football
  go.onHitFn = onHitBurstableBall;
}

function onHitBurstableBall(go: GameObj, hitter: GameObj, g: GameContext): void {
  if (hitter.name !== 'spikyball') return;
  spawnPopPopup(g, go.xpos, go.ypos);

  // Sum body shape area in px^2 (Football_Burst scales explosion force by it).
  const area = go.body ? PhysicsWorld.bodyArea(go.body) : 0;
  const force = scaleToPreLimit(5, 30, 100, 12000, area);
  doExplosion(g, go, go.xpos, go.ypos, 200, force);
  g.audio.playSfx('sfx_pop');
  go.dead = true; // RemoveObject(RemovePhysObj)
}

// ---------------------------------------------------------------------------
// Sand block (GameObj.as:3146-3151 InitSandBlock, 3124-3134 OnHitSandBlock,
// 3136-3144 UpdateSandBlock)
// ---------------------------------------------------------------------------

export function initSandBlock(go: GameObj): void {
  go.onHitFn = onHitSandBlock;
  go.updateFn = updateSandBlock;
  go.frameVel = 0.3;
}

// quirk: only the BEACHBALL crumbles sand blocks; the normal football doesn't
function onHitSandBlock(go: GameObj, hitter: GameObj, g: GameContext): void {
  if (go.state !== 0) return;
  if (hitter.collisionType === 'beachball') {
    g.audio.playSfx('sfx_hit_sandblock');
    // RemovePhysObj — physics goes away immediately, the crumble anim plays on
    if (go.body) {
      g.physics.destroyBody(go.body);
      go.body = null;
    }
    go.state = 1;
  }
}

function updateSandBlock(go: GameObj, g: GameContext): void {
  if (go.state === 1) {
    if (playFrameAnimation(go, g)) go.dead = true; // RemoveObject
  }
}

// ---------------------------------------------------------------------------

export const registry: Record<string, (go: GameObj, g: GameContext) => void> = {
  InitSpikyBall: initSpikyBall,
  InitWind: initWind,
  InitBurstableBall: initBurstableBall,
  InitSandBlock: initSandBlock,
};
