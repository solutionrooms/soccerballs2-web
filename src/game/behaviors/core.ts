// Level-1 behavior set ported from GameObj.as. Each physobj initfunction name
// maps to an init that wires update/render/hit handlers.
import { GameObj, GameContext } from '../gameobj';
import { PhysicsWorld } from '../../physics/world';
import { VARS, FPS } from '../defs';
import { drawRig, animRange, labelFrame } from '../rig';
import { scaleTo, scaleToPreLimit, easePowerInOut, distBetween } from '../utils';

// GameVars.as:73-74 — ball offset at the player's feet
const FOOT_OFFSET_X = 10;
const FOOT_OFFSET_Y = -9;

// ---------------------------------------------------------------------------
// Football (GameObj.as UpdateFootball / Football_*)
// ---------------------------------------------------------------------------

export function initFootball(go: GameObj): void {
  go.name = 'football';
  go.collisionType = 'football';
  go.state = 0;
  go.updateFn = updateFootball;
  go.renderFn = (g0, g, ctx) => {
    if (!g0.visible) return;
    g.atlas.draw(ctx, g0.dobjName, 0, g0.xpos, g0.ypos, { rot: g0.dir, scale: g0.scale });
  };
  go.onHitFn = (ball, hitter) => {
    if (hitter.name === 'player' || hitter.name === 'pickup' || hitter.name === 'invisible_switch') return;
    // GameObj.as:4832-4837 footballHitSomthing — unlocks instant re-capture
    footballHitSomething.add(ball);
  };
}

function footballSnapToPlayer(ball: GameObj, player: GameObj): void {
  ball.refA = player;
  playerSetHasFootball(player, ball);
  ball.state = 1;
  ball.xpos = player.xpos;
  ball.ypos = player.ypos + FOOT_OFFSET_Y;
  parkBody(ball);
}

// footballHitSomthing flag (GameObj.as:4816) — set when the ball touches
// anything solid, cleared on launch; lets the kicker re-capture immediately
// after a ricochet
const footballHitSomething = new WeakSet<GameObj>();

// Football_CanSnapToPlayer (GameObj.as:4588-4606)
function footballCanSnapToPlayer(ball: GameObj, player: GameObj): boolean {
  if (ball.state === 200 || ball.state === 1 || ball.state === 4) return false;
  if (ball.state === 2) {
    if (footballHitSomething.has(ball)) return true;
    if (ball.refB === player && ball.ballTimer < FPS) return false;
    return true;
  }
  return true;
}

export function footballLaunch(ball: GameObj, jx: number, jy: number): void {
  ball.physicsStationary = false;
  footballHitSomething.delete(ball);
  if (ball.body) {
    PhysicsWorld.setVelPx(ball.body, 0, 0);
    ball.body.setAngularVelocity(0);
    ball.body.setAwake(true);
    PhysicsWorld.applyImpulsePx(ball.body, jx, jy);
  }
  ball.state = 2;
  ball.stillTimer = 0;
  ball.ballTimer = 0;
}

export function footballMoveToPlayer(ball: GameObj, player: GameObj, g: GameContext): void {
  g.audio.playSfx('sfx_ball_return');
  setCollisionEnabled(ball, false);
  ball.refA = player;
  ball.state = 4;
  ball.toPosX = player.xpos;
  ball.toPosY = player.ypos + FOOT_OFFSET_Y;
  ball.startx = ball.xpos;
  ball.starty = ball.ypos;
  ball.timer = ball.timerMax = FPS / 2;
  parkBody(ball);
}

function updateFootball(ball: GameObj, g: GameContext): void {
  if (ball.state === 0) {
    const player = g.objects.nearestByName('player', ball.xpos, ball.ypos);
    if (player) footballSnapToPlayer(ball, player);
  } else if (ball.state === 1) {
    const player = ball.refA;
    if (!player) return;
    ball.xpos = player.xpos + (player.xflip ? -FOOT_OFFSET_X : FOOT_OFFSET_X);
    ball.ypos = player.ypos + FOOT_OFFSET_Y;
    parkBody(ball);
    if (g.level.numKicks >= g.level.maxKicks) {
      g.level.numKicks = g.level.maxKicks;
      g.level.success = false;
      g.audio.playSfx('sfx_levelfailed');
      g.level.phase = 'complete';
      g.level.phaseTimer = 0;
      ball.state = 999;
      player.state = 999;
    }
  } else if (ball.state === 2) {
    if (g.level.phase === 'play') {
      ball.ballTimer++;
      if (ball.ballTimer >= g.level.ballTimerShowTimerMax && ball.ballTimer % 20 === 0) {
        g.audio.playSfx('sfx_tick', 0.5);
      }
      if (ball.ballTimer >= g.level.ballTimerMax) {
        g.level.numKicks++;
        ball.state = 3;
        parkBody(ball);
      }
    }
    const b = g.bounds;
    if (ball.xpos < b.left || ball.xpos > b.right || ball.ypos < b.top || ball.ypos > b.bottom) {
      g.level.numKicks++;
      ball.state = 3;
      parkBody(ball);
    }
  } else if (ball.state === 3) {
    // smoke puff + "+1" popup
    spawnSmokePuff(g, ball.xpos, ball.ypos);
    if (ball.refA) footballMoveToPlayer(ball, ball.refA, g);
  } else if (ball.state === 4) {
    ball.timer--;
    if (ball.timer <= 0) {
      ball.timer = 0;
      if (ball.refA) playerSetHasFootball(ball.refA, ball);
      ball.state = 1;
      setCollisionEnabled(ball, true);
    }
    const v = easePowerInOut(scaleTo(0, 1, ball.timerMax, 0, ball.timer));
    ball.xpos = scaleTo(ball.startx, ball.toPosX, 0, 1, v);
    ball.ypos = scaleTo(ball.starty, ball.toPosY, 0, 1, v);
    parkBody(ball);
  }
}

export function parkBody(go: GameObj): void {
  go.physicsStationary = true;
  if (go.body) {
    PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
    PhysicsWorld.setVelPx(go.body, 0, 0);
    go.body.setAngularVelocity(0);
  }
}

// Football_MoveToPlayer zeroes the masks and restores origCollisionMask /
// origSensorMask afterwards — the originals live on each fixture's tag.
export function setCollisionEnabled(go: GameObj, on: boolean): void {
  if (!go.body) return;
  for (let f = go.body.getFixtureList(); f; f = f.getNext()) {
    const tag = f.getUserData() as { colMask: number } | null;
    f.setFilterData({
      groupIndex: f.getFilterGroupIndex(),
      categoryBits: f.getFilterCategoryBits(),
      maskBits: on ? (tag?.colMask ?? 0xffff) : 0,
    });
  }
}

// ---------------------------------------------------------------------------
// Player (GameObj.as UpdatePlayer states 0..3)
// ---------------------------------------------------------------------------

interface PlayerData {
  idleTimer: number;
  kickJx: number;
  kickJy: number;
}
const playerData = new WeakMap<GameObj, PlayerData>();

export function initPlayer(go: GameObj): void {
  go.name = 'player';
  go.state = 0;
  playerData.set(go, { idleTimer: 0, kickJx: 0, kickJy: 0 });
  setAnim(go, 'player', 'idle1');
  go.updateFn = updatePlayer;
  go.renderFn = (p, g, ctx) => {
    drawRig(ctx, g.atlas, 'player', p.animFrame, p.xpos, p.ypos, {
      xflip: p.xflip,
      scale: p.scale,
      override: g.level.playerKit ?? undefined,
    });
  };
  // OnHitPlayer (GameObj.as:4963-4974) — players sense the ball passing
  // through and take possession (control passes to them)
  go.onHitFn = (player, hitter, g) => {
    if (g.level.phase === 'complete' || g.level.phase === 'end') return;
    if (hitter.name !== 'football') return;
    if (footballCanSnapToPlayer(hitter, player)) {
      footballSnapToPlayer(hitter, player);
    }
  };
}

export function playerSetHasFootball(player: GameObj, ball: GameObj): void {
  player.refA = ball;
  player.state = 1;
}

export function setAnim(go: GameObj, clip: string, name: string): void {
  const [start, end] = animRange(clip, name);
  go.animStart = start;
  go.animEnd = end;
  go.animFrame = start;
}

export function cycleAnim(go: GameObj): void {
  go.animFrame++;
  if (go.animFrame > go.animEnd) go.animFrame = go.animStart;
}

/** returns true when the range finishes (PlayAnimationEx) */
export function playAnim(go: GameObj): boolean {
  go.animFrame++;
  if (go.animFrame >= go.animEnd) {
    go.animFrame = go.animEnd;
    return true;
  }
  return false;
}

export interface KickAim {
  active: boolean;
  jx: number;
  jy: number;
  mass: number;
  ballX: number;
  ballY: number;
  dist: number;
}
export const kickAim: KickAim = { active: false, jx: 0, jy: 0, mass: 1, ballX: 0, ballY: 0, dist: 0 };

function updatePlayer(player: GameObj, g: GameContext): void {
  const data = playerData.get(player)!;
  const ball = player.refA;

  if (player.state === 0) {
    cycleAnim(player);
  } else if (player.state === 1) {
    // aiming — GameObj.as:5022-5167
    if (!ball || ball.state !== 1) {
      kickAim.active = false;
      cycleAnim(player);
      return;
    }
    const mx = g.mouseX + g.cameraX;
    const my = g.mouseY + g.cameraY;
    player.xflip = mx < player.xpos;
    cycleAnim(player);

    const dx = mx - ball.xpos;
    const dy = my - ball.ypos;
    let kickPower0 = VARS.kick_power0;
    let kickPower1 = VARS.kick_power1;
    if (ball.collisionType === 'beachball') {
      kickPower0 = VARS.kick_power0_beachball;
      kickPower1 = VARS.kick_power1_beachball;
    }
    const dist = distBetween(0, 0, dx, dy);
    const spd = scaleToPreLimit(kickPower0, kickPower1, VARS.kick_dist0, VARS.kick_dist1, dist);
    const ang = Math.atan2(dy, dx);
    kickAim.active = true;
    kickAim.jx = Math.cos(ang) * spd;
    kickAim.jy = Math.sin(ang) * spd;
    kickAim.mass = ball.body ? PhysicsWorld.massNape(ball.body) : 1;
    kickAim.ballX = ball.xpos;
    kickAim.ballY = ball.ypos;
    kickAim.dist = dist;

    if (g.level.doKick) {
      g.level.doKick = false;
      data.kickJx = kickAim.jx;
      data.kickJy = kickAim.jy;
      setAnim(player, 'player', 'kick3');
      player.state = 2;
      kickAim.active = false;
    }
  } else if (player.state === 2) {
    // kick anim; launch on the release_ball label (GameObj.as:5170-5194)
    const done = playAnim(player);
    if (player.refA && player.animFrame === labelFrame('player', 'release_ball', player.animStart)) {
      g.audio.playSfx('sfx_kick_football' + (1 + Math.floor(Math.random() * 2)));
      const ball = player.refA;
      footballLaunch(ball, data.kickJx, data.kickJy);
      ball.refB = player;
      player.refA = null;
      g.level.numKicks++;
    }
    if (done) {
      setAnim(player, 'player', 'idle1');
      player.state = 3;
    }
  } else if (player.state === 3) {
    // ball in flight — face it
    const ballGO = g.objects.byName('football');
    if (ballGO) player.xflip = ballGO.xpos < player.xpos;
    cycleAnim(player);
  } else if (player.state === 20) {
    // celebrate (GameObj.as:5255-5271): resume aiming if still holding a ball
    if (playAnim(player)) {
      player.state = player.refA ? 1 : 3;
      setAnim(player, 'player', 'idle1');
    }
  } else if (player.state === 999) {
    cycleAnim(player);
  }
}

// ---------------------------------------------------------------------------
// Referee (GameObj.as InitRef/OnHitRef)
// ---------------------------------------------------------------------------

export function initRef(go: GameObj, g: GameContext): void {
  go.name = 'ref';
  go.state = 0;
  g.level.totalRefs++;
  setAnim(go, 'ref', 'idle1');
  // UpdateRef (GameObj.as:6236-6285): redcard -> die (physics body removed,
  // stops blocking the ball) -> fall offscreen -> removed
  go.updateFn = (ref, gg) => {
    if (ref.state === 0) {
      const ball = gg.objects.byName('football');
      if (ball) ref.xflip = ball.xpos < ref.xpos;
      cycleAnim(ref);
    } else if (ref.state === 1) {
      if (playAnim(ref)) {
        setAnim(ref, 'ref', 'die');
        if (ref.body) {
          gg.physics.destroyBody(ref.body);
          ref.body = null;
        }
        ref.state = 2;
        ref.toPosY = -4; // yvel (GameObj.as:6267)
        ref.timer = FPS * 3;
      }
    } else if (ref.state === 2) {
      ref.zpos = -10000;
      ref.toPosY += 0.2; // GameVars.gravity_GO
      ref.ypos += ref.toPosY;
      playAnim(ref);
      ref.timer--;
      if (ref.timer <= 0) ref.dead = true;
    }
  };
  go.renderFn = (ref, gg, ctx) => {
    drawRig(ctx, gg.atlas, 'ref', ref.animFrame, ref.xpos, ref.ypos, { xflip: ref.xflip, scale: ref.scale });
  };
  go.onHitFn = (ref, hitter, gg) => {
    if (ref.state !== 0) return;
    if (hitter.collisionType !== 'football') return;
    ref.state = 1;
    setAnim(ref, 'ref', 'redcard');
    gg.level.numRefsHit++;
    gg.audio.playSfx('sfx_refgroan' + (1 + Math.floor(Math.random() * 3)));
    gg.audio.playSfx('sfx_ref_whistle', 0.1);
    gg.level.addScore(100);
    spawnPopup(gg, ref.xpos, ref.ypos - 120, 'popup_redcard');
  };
}

// ---------------------------------------------------------------------------
// Goal (GameObj.as InitGoal/OnHitGoal)
// ---------------------------------------------------------------------------

export function initGoal(go: GameObj, g: GameContext): void {
  go.name = 'goal';
  go.state = 0;
  g.level.totalGoals++;
  go.renderFn = (goal, gg, ctx) => {
    gg.atlas.draw(ctx, goal.dobjName, goal.frame, goal.xpos, goal.ypos, {
      rot: goal.dir,
      scale: goal.scale,
      xflip: goal.xflip,
    });
  };
  go.onHitFn = (goal, hitter, gg, sensor) => {
    if (goal.state !== 0) return;
    if (!sensor) {
      gg.audio.playSfx('sfx_hit_metal'); // post clang (GameObj.as:6617-6620)
      return;
    }
    if (hitter.collisionType !== 'football') return;
    goal.state = 1;
    goal.frame += 2; // net bulge frame
    gg.level.numGoalsScored++;
    gg.level.addScore(200);
    gg.audio.playSfx('sfx_goal');
    spawnPopup(gg, goal.xpos, goal.ypos - 60, 'popup_goal');
    for (const p of gg.objects.allByName('player')) {
      setAnim(p, 'player', 'goal1');
      p.state = 20; // celebrate, then resume (GameObj.as:5255-5271)
    }
    // GameObj.as:6606-6610 — opponents play the conceed anim
    if (goalScoredHook) goalScoredHook(gg);
  };
}

// characters.ts injects opponent commiseration here (avoids a circular import)
let goalScoredHook: ((g: GameContext) => void) | null = null;
export function setGoalScoredHook(fn: (g: GameContext) => void): void {
  goalScoredHook = fn;
}

// ---------------------------------------------------------------------------
// Pickups (GameObj.as InitPickup / OnHitPickup / OnHitPickupTrophy)
// ---------------------------------------------------------------------------

export function initPickup(go: GameObj, g: GameContext): void {
  go.name = 'pickup';
  go.frameVel = 0.5;
  const coinIndex = g.level.totalLevelCoins;
  go.type = String(coinIndex);
  g.level.totalLevelCoins++;
  // already collected in a previous run: small + inert (InitPickup,
  // GameObj.as:3515-3519)
  const alreadyCollected = g.level.collectedCoinIndices.has(coinIndex);
  if (alreadyCollected) {
    go.scale = 0.4;
  }
  // UpdatePickup (GameObj.as:3470-3484): state 0 does nothing — the star sits
  // static on the def's frame ('Pickups' frames are different pickup DESIGNS,
  // not an animation)
  go.updateFn = (p) => {
    if (p.state === 1) {
      p.timer++;
      if (p.timer > 20) p.dead = true;
    }
  };
  go.renderFn = (p, gg, ctx) => {
    gg.atlas.draw(ctx, p.dobjName, p.frame | 0, p.xpos, p.ypos, { scale: p.scale });
  };
  go.onHitFn = (p, hitter, gg) => {
    if (p.state !== 0) return;
    if (hitter.name !== 'football') return;
    p.state = 1;
    p.scale = 0.4;
    p.timer = 0;
    if (p.body) setCollisionEnabled(p, false);
    gg.audio.playSfx('sfx_collect_coin');
    gg.level.coinsCollectedThisLevel++;
    gg.level.coinsThisRun.push(parseInt(p.type, 10));
    gg.level.addScore(10);
  };
  if (alreadyCollected) go.onHitFn = null;
}

export function initPickupTrophy(go: GameObj, g: GameContext, trophyIndex: number): void {
  go.name = 'pickup_trophy';
  go.type = String(trophyIndex);
  go.frame = trophyIndex - 1;
  void g;
  go.renderFn = (p, gg, ctx) => {
    gg.atlas.draw(ctx, p.dobjName, p.frame | 0, p.xpos, p.ypos, { scale: p.scale });
  };
  go.onHitFn = (p, hitter, gg) => {
    if (hitter.name !== 'football') return;
    p.dead = true;
    gg.audio.playSfx('sfx_collect_cup');
    gg.level.trophyCollectedThisRun = true;
    spawnPopup(gg, p.xpos, p.ypos - 30, 'popup_cup');
  };
}

// ---------------------------------------------------------------------------
// Popups / particles (InitGoalPopup etc. — rise and fade)
// ---------------------------------------------------------------------------

export function spawnPopup(g: GameContext, x: number, y: number, dobjName: string): void {
  const go = g.objects.add();
  go.name = 'popup';
  go.dobjName = dobjName;
  go.xpos = x;
  go.ypos = y;
  go.zpos = -10000;
  go.timer = 0;
  go.updateFn = (p) => {
    p.timer++;
    p.ypos -= 0.5;
    if (p.timer > FPS * 1.5) p.dead = true;
  };
  go.renderFn = (p, gg, ctx) => {
    const alpha = p.timer > FPS ? 1 - (p.timer - FPS) / (FPS * 0.5) : 1;
    gg.atlas.draw(ctx, p.dobjName, 0, p.xpos, p.ypos, { alpha });
  };
}

export function spawnSmokePuff(g: GameContext, x: number, y: number): void {
  const go = g.objects.add();
  go.name = 'smoke';
  go.dobjName = 'fx_smoke';
  go.xpos = x;
  go.ypos = y;
  go.zpos = -10;
  go.updateFn = (p, gg) => {
    p.frame += 0.5;
    if (p.frame >= gg.atlas.frameCount(p.dobjName)) p.dead = true;
  };
  go.renderFn = (p, gg, ctx) => {
    gg.atlas.draw(ctx, p.dobjName, p.frame | 0, p.xpos, p.ypos);
  };
}

// ---------------------------------------------------------------------------
// Help text (GameObj_InitHelpText) — fades in after a delay
// ---------------------------------------------------------------------------

// Ease.as:45-48 Spring_Out (elastic out, period 0.3)
function springOut(t: number): number {
  if (t === 0) return 0;
  if (t === 1) return 1;
  const p = 0.3;
  const s = p / 4;
  return Math.pow(2, -10 * t) * Math.sin(((t - s) * 2 * Math.PI) / p) + 1;
}

// GameObj_InitHelpText / GameObj_UpdateHelpText (GameObj.as:4020-4065,
// 4123-4145): hidden countdown -> sfx_text_appear -> spring scale-in.
// State 3 = waiting for a switch (logic-linked help texts).
export function initHelpText(go: GameObj): void {
  go.name = 'text';
  go.state = 0;
  go.visible = false;
  go.scale = 0;
  go.timer = Math.round(go.paramNum('helptext_initialdelay', 0) * FPS);
  go.updateFn = (h, gg) => {
    if (h.state === 0) {
      h.visible = false;
      h.timer--;
      if (h.timer <= 0) {
        h.state = 1;
        h.visible = true;
        h.timer = h.timerMax = FPS * 2;
      }
    } else if (h.state === 1) {
      gg.audio.playSfx('sfx_text_appear');
      h.visible = true;
      h.scale = 0;
      h.state = 2;
      h.timer = h.timerMax = FPS * 2;
    } else if (h.state === 2) {
      h.scale = Math.max(0, springOut(scaleTo(1, 0, 0, h.timerMax, h.timer)));
      h.timer--;
      if (h.timer <= 0) h.timer = 0;
    }
    // state 3: waiting for switch
  };
  go.renderFn = (h, gg, ctx) => {
    if (!h.visible || h.scale <= 0) return;
    ctx.save();
    ctx.translate(h.xpos, h.ypos);
    ctx.scale(h.scale, h.scale);
    ctx.font = '16px sans-serif';
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.fillText(h.param('helptext_text'), 0, 0);
    ctx.restore();
    void gg;
  };
}

// OnSwitch_HelpText (GameObj.as:4086-4093)
export function onSwitchHelpText(go: GameObj): void {
  if (go.state === 3) {
    go.state = 0;
  }
}
