// Characters & markers behavior family ported from GameObj.as:
// keeper, opponents (idle/patrol/jump-when-near), referee variants,
// patrol/jump markers, beachball, spawner and help-text/help-object variants.
import { GameObj, GameContext } from '../gameobj';
import { PhysicsWorld } from '../../physics/world';
import { FPS, PX_PER_METER } from '../defs';
import { drawRig, labelFrame } from '../rig';
import { scaleTo, distBetween } from '../utils';
import { initFootball, initRef, setAnim, spawnPopup } from './core';

// GameVars.as:33
const GRAVITY_GO = 0.2;

// ---------------------------------------------------------------------------
// Shared helpers (GameObj_Base.as / Utils.as)
// ---------------------------------------------------------------------------

/** Utils.as RandBetweenInt — inclusive both ends. */
function randBetweenInt(a: number, b: number): number {
  return a + Math.floor(Math.random() * (b - a + 1));
}

// GameObj_Base.as:676-691 — PlayAnimationEx: fractional frameVel, clamps at the
// range end and returns true once there. (core's playAnim is the vel=1 case.)
function playAnimVel(go: GameObj, vel: number): boolean {
  go.animFrame += vel;
  if (go.animFrame > go.animEnd) {
    go.animFrame = go.animEnd;
    return true;
  }
  if (go.animFrame < go.animStart) {
    go.animFrame = go.animStart;
    return true;
  }
  return false;
}

// GameObj_Base.as:638-674 — CycleAnimationEx (non-bouncing branch).
function cycleAnimVel(go: GameObj, vel: number): boolean {
  go.animFrame += vel;
  const numFrames = go.animEnd - go.animStart;
  let looped = false;
  if (go.animFrame > go.animEnd) {
    go.animFrame -= numFrames;
    looped = true;
  }
  if (go.animFrame < go.animStart) {
    go.animFrame += numFrames;
    looped = true;
  }
  return looped;
}

// Per-character mutable state the AS3 kept as GameObj member vars.
interface CharData {
  idleTimer: number; // GameObj.as:5280
  idleState: number; // GameObj.as:5281
  animVel: number; // AS3 frameVel (player/ref 0.5, patrol run 0.3)
  xvel: number;
  yvel: number;
  frame1: number; // jump_mark overlay anim (dobj1/frame1)
  frameVel1: number;
  canJumpWhenNear: boolean; // GameObj.as:6020
  canKickWhenNear: boolean; // GameObj.as:6021
  keeperActionName: string; // GameObj.as:5762
  keeperActionIndex: number; // GameObj.as:5761
  showTimer: boolean; // GameObj.as:5815
  /** rig part frame overrides (AnimHierarchy.SetPartFrame: head pick, red card) */
  rigFrames: Map<string, number>;
}

const charData = new WeakMap<GameObj, CharData>();

function newCharData(): CharData {
  return {
    idleTimer: 0,
    idleState: 0,
    animVel: 0.5,
    xvel: 0,
    yvel: 0,
    frame1: 0,
    frameVel1: 0,
    canJumpWhenNear: false,
    canKickWhenNear: false,
    keeperActionName: 'stationary',
    keeperActionIndex: 0,
    showTimer: false,
    rigFrames: new Map<string, number>(),
  };
}

// GameObj.as:5282-5287 — PlayerStartIdleAnim (also RefStartIdleAnim 6386-6391)
function startIdleAnim(go: GameObj, d: CharData, clip: string): void {
  d.idleTimer = 0;
  d.idleState = 0;
  setAnim(go, clip, 'idle' + randBetweenInt(1, 3));
}

// GameObj.as:5288-5307 — PlayerUpdateIdleAnim: play one idle, hold the end
// pose for rand(fps..2fps) frames, then pick the next random idle1..3.
function updateIdleAnim(go: GameObj, d: CharData, clip: string): void {
  if (d.idleState === 0) {
    if (playAnimVel(go, d.animVel)) {
      d.idleState = 1;
    }
  } else {
    d.idleTimer--;
    if (d.idleTimer <= 0) {
      setAnim(go, clip, 'idle' + randBetweenInt(1, 3));
      d.idleTimer = randBetweenInt(FPS, FPS * 2);
      d.idleState = 0;
    }
  }
}

// GameObj.as:4976-4981 — PlayerFaceToBall
function faceToBall(go: GameObj, ball: GameObj): void {
  go.xflip = ball.xpos < go.xpos;
}

// Rounded world-space rig draw with body rotation (AnimHierarchy.RenderAt got
// `dir`; needed for the loose ref getting knocked over).
function drawRigChar(ctx: CanvasRenderingContext2D, g: GameContext, clip: string, go: GameObj): void {
  const d = charData.get(go);
  const kit = go.name === 'opponent' || go.name === 'opponent_keeper' ? g.level.opponentKit : null;
  const override =
    (d && d.rigFrames.size) || kit
      ? { frames: d?.rigFrames, tints: kit?.tints, hidden: kit?.hidden }
      : undefined;
  const x = Math.round(go.xpos);
  const y = Math.round(go.ypos);
  if (go.dir !== 0) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate((go.dir * Math.PI) / 180);
    drawRig(ctx, g.atlas, clip, go.animFrame, 0, 0, { xflip: go.xflip, scale: go.scale, override });
    ctx.restore();
  } else {
    drawRig(ctx, g.atlas, clip, go.animFrame, x, y, { xflip: go.xflip, scale: go.scale, override });
  }
}

// GameObj.as:5996-6018 — RaycastBelow: ray down from (xpos, ypos-50), max
// distance 100 (snap) / 50 (walk check), floor filter; snaps ypos to the hit.
function raycastBelow(go: GameObj, g: GameContext, snap: boolean): boolean {
  const y = g.physics.raycastFloorY(go.xpos, go.ypos - 50, snap ? 100 : 50);
  if (y !== null) {
    go.ypos = y;
    return true;
  }
  return false;
}

function removePhysBody(go: GameObj, g: GameContext): void {
  if (go.body) {
    g.physics.destroyBody(go.body);
    go.body = null;
  }
}

// ---------------------------------------------------------------------------
// Patrol movement (shared verbatim by UpdateOpponent GameObj.as:5607-5692 and
// UpdateRef GameObj.as:6285-6371): state 100 walk between patrol_markers,
// launch off jump_markers; state 101 airborne until the floor raycast hits.
// ---------------------------------------------------------------------------

function updatePatrol(go: GameObj, g: GameContext, d: CharData): void {
  if (go.state === 100) {
    for (const m of g.objects.allByName('jump_marker')) {
      if (distBetween(go.xpos, go.ypos, m.xpos, m.ypos) < 20) {
        // AS3 marker dir is radians; the web loader stores degrees
        const rot = (m.dir * Math.PI) / 180;
        const vx = Math.cos(rot);
        const doit = go.xflip ? vx < 0 : vx > 0;
        if (doit) {
          go.state = 101;
          const spd = 5 * m.scale; // movementVec.Set(go.dir, 5); speed *= go.scale
          d.xvel = Math.cos(rot) * spd;
          d.yvel = Math.sin(rot) * spd;
        }
      }
    }

    cycleAnimVel(go, d.animVel);

    const ox = go.xpos;
    go.xpos += d.xvel;

    for (const m of g.objects.allByName('patrol_marker')) {
      if (Math.abs(m.ypos - go.ypos) < 20) {
        if (d.xvel > 0) {
          if (go.xpos >= m.xpos && ox < m.xpos) {
            go.xpos = m.xpos;
            d.xvel = -d.xvel;
            go.xflip = !go.xflip;
          }
        } else {
          if (go.xpos <= m.xpos && ox > m.xpos) {
            go.xpos = m.xpos;
            d.xvel = -d.xvel;
            go.xflip = !go.xflip;
          }
        }
      }
    }
    if (!raycastBelow(go, g, true)) {
      go.state = 101;
      d.yvel = 0;
    }
  } else if (go.state === 101) {
    go.xpos += d.xvel;
    go.ypos += d.yvel;
    d.yvel += GRAVITY_GO;
    if (d.yvel > 0) {
      if (raycastBelow(go, g, false)) {
        go.state = 100;
        d.xvel = go.xflip ? -2 : 2; // land: walk speed 2 again
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Opponent (GameObj.as:5417-5758, 6020-6049)
// ---------------------------------------------------------------------------

// GameVars.as:611-614 — oppo_kick_table (frame within the player 'kick1' anim,
// foot offset from the opponent's origin; force field unused by Opponent_KickBall)
const OPPO_KICK_TABLE: { frame: number; xoff: number; yoff: number }[] = [
  { frame: 67, xoff: 14, yoff: -6 },
  { frame: 68, xoff: 23, yoff: -13 },
  { frame: 69, xoff: 30, yoff: -26 },
];

// GameObj.as:5417-5426 — Opponent_KickBall: impulse of 150 units toward the
// ball (movementVec.SetFromDxDy + speed = 150 → normalized * 150).
function opponentKickBall(go: GameObj, ball: GameObj): void {
  const dx = ball.xpos - go.xpos;
  const dy = ball.ypos - go.ypos;
  const len = distBetween(0, 0, dx, dy);
  if (ball.body && len > 0) {
    PhysicsWorld.applyImpulsePx(ball.body, (dx / len) * 150, (dy / len) * 150);
  }
}

// GameObj.as:5505-5520 / 5854-5869 — kick-frame foot-vs-ball check (< 15px)
function checkOppoKickTable(go: GameObj, ball: GameObj | null): void {
  if (!ball) return;
  for (const ok of OPPO_KICK_TABLE) {
    if (Math.floor(go.animFrame) === ok.frame) {
      let x = go.xpos + ok.xoff;
      if (go.xflip) x = go.xpos - ok.xoff;
      const dist = distBetween(x, go.ypos + ok.yoff, ball.xpos, ball.ypos);
      if (dist < 15) {
        opponentKickBall(go, ball);
        go.state = 2;
      }
    }
  }
}

/** GameObj.as:5439-5446 — OpponentStartCommiseration. OnHitGoal
 *  (GameObj.as:6606-6610) calls this on every 'opponent' when a goal is
 *  scored — core's initGoal needs to call it (reported, core untouched). */
export function opponentStartCommiseration(go: GameObj): void {
  if (go.state === 0) {
    setAnim(go, 'player', 'conceed');
    go.state = 30;
  }
}

function cycleFrame1(go: GameObj, d: CharData, g: GameContext, clip: string): void {
  // GameObj_Base.as:702-710 — CycleAnimation1 (dobj1/frame1/frameVel1)
  d.frame1 += d.frameVel1;
  const max = g.atlas.frameCount(clip);
  if (d.frame1 >= max) d.frame1 -= max;
  if (d.frame1 < 0) d.frame1 += max;
  void go;
}

// GameObj.as:5464-5697 — UpdateOpponent
function updateOpponent(go: GameObj, g: GameContext): void {
  const d = charData.get(go)!;
  const ball = g.objects.byName('football'); // GameVars.footballGO

  if (go.state === 0) {
    if (ball) faceToBall(go, ball);
    updateIdleAnim(go, d, 'player');
    // PlayerHeadFollowPoint(ball.xpos, ball.ypos) — TODO(M5): drawRig has no
    // per-part rotation override yet (head tracking).

    if (d.canJumpWhenNear) {
      cycleFrame1(go, d, g, 'jump_mark');
      if (ball && ball.ypos < go.ypos - 80) {
        const distHeadToBall = distBetween(go.xpos, go.ypos - 80, ball.xpos, ball.ypos);
        if (distHeadToBall < 100) {
          // Opponent_InitHeader — GameObj.as:5433-5437
          setAnim(go, 'player', 'jump_start');
          go.state = 20;
        }
      }
    }
    // oppo_canKickWhenNear: the kick trigger (Opponent_InitKick on
    // distToBall < 100) is commented out in the AS3 (GameObj.as:5489-5495),
    // so states 1/2 below are unreachable in the original too.
  } else if (go.state === 1) {
    // KICK — GameObj.as:5497-5521 (Opponent_InitKick sets 'kick1', 5427-5431)
    if (playAnimVel(go, d.animVel)) {
      startIdleAnim(go, d, 'player');
      go.state = 0;
    }
    checkOppoKickTable(go, ball);
  } else if (go.state === 2) {
    if (playAnimVel(go, d.animVel)) {
      startIdleAnim(go, d, 'player');
      go.state = 0;
    }
  } else if (go.state === 10) {
    // hit by ball — GameObj.as:5531-5543; AS3 plays at frameVel 0.4 and
    // restores 0.5 when done (head keeps following the ball — TODO(M5))
    if (playAnimVel(go, 0.4)) {
      startIdleAnim(go, d, 'player');
      go.state = 0;
    }
  } else if (go.state === 20) {
    // jump for header — GameObj.as:5545-5556
    cycleFrame1(go, d, g, 'jump_mark');
    if (playAnimVel(go, d.animVel)) {
      g.audio.playSfx('sfx_jump');
      setAnim(go, 'player', 'jumped');
      go.state = 21;
      d.yvel = -7;
    }
  } else if (go.state === 21) {
    // airborne — GameObj.as:5557-5577
    cycleFrame1(go, d, g, 'jump_mark');
    playAnimVel(go, d.animVel);
    go.ypos += d.yvel;
    d.yvel += GRAVITY_GO;
    if (go.ypos >= go.starty) {
      go.ypos = go.starty;
      d.yvel = 0;
      setAnim(go, 'player', 'landing');
      go.state = 22;
    }
  } else if (go.state === 22) {
    // landing — GameObj.as:5578-5586
    cycleFrame1(go, d, g, 'jump_mark');
    if (playAnimVel(go, d.animVel)) {
      startIdleAnim(go, d, 'player');
      go.state = 0;
    }
  } else if (go.state === 30) {
    // conceed — GameObj.as:5588-5596
    if (playAnimVel(go, d.animVel)) {
      go.state = 31;
      setAnim(go, 'player', 'conceed_loop');
      go.timer = randBetweenInt(FPS * 1, FPS * 2);
    }
  } else if (go.state === 31) {
    // GameObj.as:5597-5606
    cycleAnimVel(go, d.animVel);
    go.timer--;
    if (go.timer <= 0) {
      startIdleAnim(go, d, 'player');
      go.state = 0;
    }
  }

  // patrol — GameObj.as:5607-5692
  updatePatrol(go, g, d);
  // SetBodyXForm(0, xpos, ypos, 0) — GameObj.as:5694: physicsStationary=true
  // makes the scene park the body from xpos/ypos every frame.
}

// GameObj.as:5448-5461 — RenderOpponent (player rig + jump_mark hint overlay)
function renderOpponent(go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  drawRigChar(ctx, g, 'player', go);
  const d = charData.get(go)!;
  if (d.canJumpWhenNear) {
    g.atlas.draw(ctx, 'jump_mark', d.frame1 | 0, go.xpos, go.ypos - 93);
  }
}

// GameObj.as:5698-5708 — OnHitOpponent
function onHitOpponent(go: GameObj, hitter: GameObj): void {
  if (hitter.collisionType === 'football' || hitter.collisionType === 'beachball') {
    if (go.state === 0) {
      opponentInitHitByFootball(go, hitter);
    }
  }
}

// GameObj.as:5709-5726 — Opponent_InitHitByFootball: reaction anim by hit height
function opponentInitHitByFootball(go: GameObj, hitter: GameObj): void {
  const dy = go.ypos - hitter.ypos;
  if (dy < 20) {
    setAnim(go, 'player', 'hitLow');
  } else if (dy < 55) {
    setAnim(go, 'player', 'hitMid');
  } else {
    setAnim(go, 'player', 'hitHigh');
  }
  go.state = 10;
}

// GameObj.as:5727-5758 — InitOpponent. Uses the 'player' rig clip (AS3:
// dobj = "player" + AddHierarchy_Player with the opponent team's kit colors —
// kit tinting is TODO(M4), rig override images).
export function initOpponent(go: GameObj, g: GameContext): void {
  const d = newCharData();
  charData.set(go, d);
  go.name = 'opponent';
  go.state = 0;
  // AddHierarchy_Player head pick — GameObj.as:6070-6077
  const race = randBetweenInt(0, 1);
  d.rigFrames.set('head', race === 1 ? randBetweenInt(8, 15) : randBetweenInt(0, 7));
  startIdleAnim(go, d, 'player');
  go.scale = 1;
  go.starty = go.ypos; // GameObj.as:5757
  go.physicsStationary = true; // body driven from xpos/ypos (SetBodyXForm)
  go.updateFn = updateOpponent;
  go.renderFn = renderOpponent;
  go.onHitFn = onHitOpponent;
  void g;
}

// GameObj.as:6022-6032 — InitOpponent_JumpWhenNear
export function initOpponentJumpWhenNear(go: GameObj, g: GameContext): void {
  initOpponent(go, g);
  const d = charData.get(go)!;
  go.state = 0;
  go.physicsStationary = true; // PhysicsSetStationary
  d.canJumpWhenNear = true;
  d.canKickWhenNear = true;
  d.frame1 = 0;
  d.frameVel1 = 0.1; // jump_mark hint cycles slowly
}

// GameObj.as:6035-6049 — InitOpponent_Patrol
export function initOpponentPatrol(go: GameObj, g: GameContext): void {
  initOpponent(go, g);
  const d = charData.get(go)!;
  go.state = 100;
  go.onHitFn = null; // patrolling opponents don't react to ball hits
  d.animVel = 0.3; // frameVel = 0.3
  setAnim(go, 'player', 'run1');
  d.xvel = 2;
}

// ---------------------------------------------------------------------------
// Goalkeeper (GameObj.as:5761-5988, GameVars.as:719-754)
// ---------------------------------------------------------------------------

// GameVars.as:746-754 — keeperActions: [mode, seconds] steps per action name.
// mode 0 = stand for N seconds (N < 0 → forever), 1 = jump, 2 = crouch.
// NOTE GameVars.as:753 quirk: "(new Point(0,3),new Point(2,0))" is the AS3
// comma operator, so jumpcrouch1 is really [(0,3),(1,0),(2,0)].
const KEEPER_ACTIONS: Record<string, [number, number][]> = {
  stationary: [[0, -1]],
  jump1: [
    [0, 3],
    [1, 0],
  ],
  crouch1: [
    [0, 3],
    [2, 0],
  ],
  jumpcrouch1: [
    [0, 3],
    [1, 0],
    [2, 0],
  ],
};

// GameVars.as:719-732 — KeeperNextAction: advance & wrap the step index
function keeperNextAction(d: CharData): void {
  const list = KEEPER_ACTIONS[d.keeperActionName];
  if (list) {
    d.keeperActionIndex++;
    if (d.keeperActionIndex >= list.length) d.keeperActionIndex = 0;
  }
}

// GameObj.as:5791-5794 (duck) + 5907-5910 (unduck) — the duck zeroes the
// upper-body shape collision masks so the ball flies over the keeper's head;
// unduck restores mask 14. AS3 indexed shapes 2,3 of 4; the extracted keeper
// body has a tall idle shape (to -70px) and a short crouch shape (to -40px)
// (each fan-triangulated), so we toggle every fixture reaching above -50px.
function keeperSetDuckMasks(go: GameObj, ducked: boolean): void {
  if (!go.body) return;
  const bodyY = go.body.getPosition().y;
  for (let f = go.body.getFixtureList(); f; f = f.getNext()) {
    const tag = f.getUserData() as { colMask: number } | null;
    const topPx = (bodyY - f.getAABB(0).lowerBound.y) * PX_PER_METER;
    if (topPx <= 50) continue; // crouch-height shape stays solid
    f.setFilterData({
      groupIndex: f.getFilterGroupIndex(),
      categoryBits: f.getFilterCategoryBits(),
      maskBits: ducked ? 0 : (tag?.colMask ?? 14),
    });
  }
}

// GameObj.as:5768-5796 — KeeperStartAction
function keeperStartAction(go: GameObj, d: CharData): void {
  const p = KEEPER_ACTIONS[d.keeperActionName]?.[d.keeperActionIndex] ?? [0, -1];
  if (p[0] === 0) {
    // stationary
    go.timer = p[1] * FPS;
    if (p[1] < 0) go.timer = 9999999;
    go.timerMax = go.timer;
    go.state = 0;
  } else if (p[0] === 1) {
    // jump
    setAnim(go, 'keeper', 'jump');
    go.state = 20;
  } else if (p[0] === 2) {
    // crouch
    setAnim(go, 'keeper', 'duck');
    go.timer = go.timerMax = randBetweenInt(100, 100); // = 100 frames
    go.state = 10;
    keeperSetDuckMasks(go, true);
  }
}

// GameObj.as:5816-5948 — UpdateKeeper
function updateKeeper(go: GameObj, g: GameContext): void {
  const d = charData.get(go)!;
  const ball = g.objects.byName('football');

  d.showTimer = false;

  if (go.state === 0) {
    go.starty = go.ypos;
    if (ball) faceToBall(go, ball);
    updateIdleAnim(go, d, 'keeper');
    // PlayerHeadFollowPoint — TODO(M5): rig head-part rotation override

    d.showTimer = true;
    go.timer--;
    if (go.timer <= 0) {
      keeperNextAction(d);
      keeperStartAction(go, d);
    }
  } else if (go.state === 1) {
    // kick — GameObj.as:5846-5870. Unreachable: no keeperAction sets state 1,
    // and the oppo_kick_table frames 67-69 never occur inside the keeper's
    // kick1 range (108-142) anyway. Ported for completeness.
    if (playAnimVel(go, d.animVel)) {
      startIdleAnim(go, d, 'keeper');
      go.state = 0;
    }
    checkOppoKickTable(go, ball);
  } else if (go.state === 2) {
    if (playAnimVel(go, d.animVel)) {
      startIdleAnim(go, d, 'keeper');
      go.state = 0;
    }
  } else if (go.state === 10) {
    // duck — GameObj.as:5879-5890
    playAnimVel(go, d.animVel);
    go.timer--;
    if (go.timer <= 0) {
      go.state = 11;
      go.timer = FPS * 2;
      setAnim(go, 'keeper', 'duck_loop');
    }
  } else if (go.state === 11) {
    // duck loop — GameObj.as:5891-5900
    cycleAnimVel(go, d.animVel);
    go.timer--;
    if (go.timer <= 0) {
      go.state = 12;
      setAnim(go, 'keeper', 'unduck');
    }
  } else if (go.state === 12) {
    // unduck — GameObj.as:5901-5914 (restores shape masks to 14)
    if (playAnimVel(go, d.animVel)) {
      go.state = 0;
      startIdleAnim(go, d, 'keeper');
      keeperSetDuckMasks(go, false);
      keeperNextAction(d);
      keeperStartAction(go, d);
    }
  } else if (go.state === 20) {
    // start jump — GameObj.as:5915-5925; leaves the ground at the "air" label
    playAnimVel(go, d.animVel);
    if (Math.floor(go.animFrame) === labelFrame('keeper', 'air')) {
      g.audio.playSfx('sfx_jump');
      go.state = 21;
      d.yvel = -7;
    }
  } else if (go.state === 21) {
    // airborne — GameObj.as:5926-5947
    playAnimVel(go, d.animVel);
    go.ypos += d.yvel;
    d.yvel += GRAVITY_GO;
    if (go.ypos >= go.starty) {
      go.ypos = go.starty;
      go.state = 0;
      d.yvel = 0;
      startIdleAnim(go, d, 'keeper');
      keeperNextAction(d);
      keeperStartAction(go, d);
    }
  }
}

// GameObj.as:5799-5813 — RenderKeeper: keeper rig + generalTimer countdown dial
function renderKeeper(go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  drawRigChar(ctx, g, 'keeper', go);
  const d = charData.get(go)!;
  if (d.showTimer) {
    const f = scaleTo(0, g.atlas.frameCount('generalTimer') - 1, 0, go.timerMax, go.timer);
    g.atlas.draw(ctx, 'generalTimer', f | 0, Math.round(go.xpos), Math.round(go.ypos) - 60);
  }
}

// GameObj.as:5951-5988 — InitKeeper. name 'opponent_keeper'; uses the 'keeper'
// rig clip (AddHierarchy_Keeper; kit tint TODO(M4)); no onHit (commented out
// in AS3 too). keeper_action param picks the keeperActions sequence.
export function initKeeper(go: GameObj, g: GameContext): void {
  const d = newCharData();
  charData.set(go, d);
  d.showTimer = false;
  d.keeperActionName = go.param('keeper_action', 'stationary');
  d.keeperActionIndex = 0;
  go.name = 'opponent_keeper';
  go.physicsStationary = true; // PhysicsSetStationary
  keeperStartAction(go, d);
  startIdleAnim(go, d, 'keeper'); // AS3 calls PlayerStartIdleAnim after StartAction
  go.scale = 1;
  go.updateFn = updateKeeper;
  go.renderFn = renderKeeper;
  void g;
}

// ---------------------------------------------------------------------------
// Referee variants (GameObj.as:6182-6498)
// ---------------------------------------------------------------------------

// GameObj.as:6182-6211 — OnHitRef/Ref_HitByFootball. Accepts patrol states
// 100/101 too (core's onHit only fires in state 0, so the variants rewire it).
// Football only — beachballs do NOT take out refs.
function onHitRefFull(ref: GameObj, hitter: GameObj, g: GameContext): void {
  if (ref.state !== 0 && ref.state !== 100 && ref.state !== 101) return;
  if (hitter.collisionType !== 'football') return;
  ref.state = 1;
  setAnim(ref, 'ref', 'redcard');
  const d = charData.get(ref)!;
  d.rigFrames.set('lowerArmLeft', 2); // red card (GameObj.as:6197)
  d.rigFrames.set('lowerArmRight', 1); // whistle (GameObj.as:6198)
  g.level.numRefsHit++;
  g.audio.playSfx('sfx_refgroan' + randBetweenInt(1, 3));
  g.audio.playSfx('sfx_ref_whistle', 0.1);
  g.level.addScore(100);
  spawnPopup(g, ref.xpos, ref.ypos - 120, 'popup_redcard');
}

// Shared by UpdateRef states 1/2 — redcard finished → 'die', drop the physics
// body and fall off-screen for 3 seconds (GameObj.as:6261-6283).
function refUpdateDieStates(go: GameObj, g: GameContext, d: CharData): void {
  if (go.state === 1) {
    // GameVars.useFeature3 gib pieces (GameObj.as:6248-6257) — TODO(M5)
    if (playAnimVel(go, d.animVel)) {
      setAnim(go, 'ref', 'die');
      removePhysBody(go, g); // RemovePhysObj
      go.state = 2;
      d.yvel = -4;
      go.timer = FPS * 3;
    }
  } else if (go.state === 2) {
    go.zpos = -10000;
    d.yvel += GRAVITY_GO;
    go.ypos += d.yvel;
    go.timer--;
    if (go.timer <= 0) {
      go.dead = true; // RemoveObject
    }
    cycleAnimVel(go, d.animVel);
  }
}

// GameObj.as:6236-6383 — UpdateRef (full version with die/fall + patrol)
function updateRefFull(go: GameObj, g: GameContext): void {
  const d = charData.get(go)!;
  if (go.state === 0) {
    const ball = g.objects.byName('football');
    if (ball) faceToBall(go, ball);
    updateIdleAnim(go, d, 'ref');
  } else {
    refUpdateDieStates(go, g, d);
  }
  // patrol — GameObj.as:6285-6371 (identical to the opponent patrol block)
  updatePatrol(go, g, d);
  // SetBodyXForm if a body exists (GameObj.as:6373-6379) → parked body
}

// GameObj.as:6414-6449 — UpdateRefLoose: idles in place (no ball facing); the
// dynamic body is free, so the football physically knocks him over.
function updateRefLoose(go: GameObj, g: GameContext): void {
  const d = charData.get(go)!;
  if (go.state === 0) {
    updateIdleAnim(go, d, 'ref');
  } else {
    refUpdateDieStates(go, g, d);
  }
}

function renderRefChar(go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  drawRigChar(ctx, g, 'ref', go);
}

// Common variant setup over core's initRef (GameObj.as:6456-6472: name 'ref',
// totalRefs++, idle anim, frameVel 0.5 — already done by core).
function initRefVariant(go: GameObj, g: GameContext): CharData {
  initRef(go, g);
  const d = newCharData();
  charData.set(go, d);
  // AddHierarchy_Ref — GameObj.as:6491-6498: random head frame 0..2
  d.rigFrames.set('head', randBetweenInt(0, 2));
  startIdleAnim(go, d, 'ref');
  go.renderFn = renderRefChar;
  go.onHitFn = onHitRefFull;
  return d;
}

// GameObj.as:6450-6455 — InitRef_Loose: PhysicsSetMovable; level instances set
// fixed=false so the loader already made the body dynamic.
export function initRefLoose(go: GameObj, g: GameContext): void {
  initRefVariant(go, g);
  go.physicsStationary = false;
  go.updateFn = updateRefLoose;
}

// GameObj.as:6474-6485 — InitRef_Patrol
export function initRefPatrol(go: GameObj, g: GameContext): void {
  const d = initRefVariant(go, g);
  go.state = 100;
  d.animVel = 0.3; // frameVel = 0.3
  setAnim(go, 'ref', 'run1');
  d.xvel = 2;
  go.physicsStationary = true; // body follows xpos/ypos while walking
  go.updateFn = updateRefFull;
}

// ---------------------------------------------------------------------------
// AI markers (GameObj.as:6747-6759) — invisible name tags the patrol AI reads
// ---------------------------------------------------------------------------

// GameObj.as:6747-6752
export function initPatrolMarker(go: GameObj): void {
  go.name = 'patrol_marker';
  go.visible = false; // visible only when Game.usedebug
}

// GameObj.as:6754-6759
export function initJumpMarker(go: GameObj): void {
  go.name = 'jump_marker';
  go.visible = false; // visible only when Game.usedebug
}

// ---------------------------------------------------------------------------
// Beachball (GameObj.as:4846-4850)
// ---------------------------------------------------------------------------

// InitFootball_Beachball is the plain football with collisionType 'beachball';
// the lighter kick (VARS.kick_power0/1_beachball) is applied by core's
// updatePlayer. The VarsData 'ballpath_gravity_multiplier_beachball' is never
// read by the AS3 (Game.as:2982 always uses ballpath_gravity_multiplier), so
// the aim path needs no override either.
export function initFootballBeachball(go: GameObj): void {
  initFootball(go);
  go.collisionType = 'beachball';
}

// ---------------------------------------------------------------------------
// Spawner (GameObj.as:2078-2174)
// ---------------------------------------------------------------------------

interface SpawnerData {
  spin: number; // AS3 rotVel, radians (dir is set from it each render)
  frequency: number; // frames
  total: number; // 0 = infinite
  count: number;
  names: string[]; // spawner_spawnobject split on '+'
}
const spawnerData = new WeakMap<GameObj, SpawnerData>();

/** Spawner_GenerateObjectsCallback (GameObj.as:2125-2128) needs
 *  PhysicsBase.AddPhysObjAt — i.e. level-loader's instance factory. The loader
 *  must register it here via setSpawnPhysObjFn (reported; not wired yet). */
export type SpawnPhysObjFn = (g: GameContext, typeName: string, x: number, y: number) => void;
let spawnPhysObjFn: SpawnPhysObjFn | null = null;
export function setSpawnPhysObjFn(fn: SpawnPhysObjFn): void {
  spawnPhysObjFn = fn;
}

// GameObj.as:2078-2123 — UpdateSpawner
function updateSpawner(go: GameObj, g: GameContext): void {
  const d = spawnerData.get(go)!;
  d.spin += 0.09;

  if (go.state === -1) {
    // "waiting for a click" — legacy, falls straight through (2082-2085)
    go.state = 0;
  }
  if (go.state === 0) {
    go.timer--;
    if (go.timer <= 0) {
      go.state = 1;
    }
  } else if (go.state === 1) {
    const name = d.names[d.count % d.names.length];
    if (spawnPhysObjFn) {
      spawnPhysObjFn(g, name, go.xpos, go.ypos);
    }
    // TODO(M2): wire setSpawnPhysObjFn from level-loader so spikyballs spawn

    g.audio.playSfx('sfx_portal');
    d.count++;
    go.timer = d.frequency;
    go.state = 0;
    if (d.total !== 0 && d.count >= d.total) {
      go.state = 2; // exhausted
    }
  }
  // state 2: inert (GameObj.as:2119-2122)
}

// GameObj.as:2142-2148 — RenderSpawner: wormhole spins at rotVel (radians),
// 'wormhole_small' overlay at 0.3x the angle.
function renderSpawner(go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  const d = spawnerData.get(go)!;
  const deg = (d.spin * 180) / Math.PI;
  g.atlas.draw(ctx, go.dobjName, go.frame | 0, go.xpos, go.ypos, { rot: deg, scale: go.scale });
  g.atlas.draw(ctx, 'wormhole_small', 0, go.xpos, go.ypos, { rot: deg * 0.3 });
}

// GameObj.as:2149-2174 — InitSpawner
export function initSpawner(go: GameObj, g: GameContext): void {
  const d: SpawnerData = {
    spin: 1, // dir = 1; rotVel = 1
    frequency: go.paramNum('spawner_frequency', 3) * FPS,
    total: Math.floor(go.paramNum('spawner_totalamount', 10)),
    count: 0,
    names: go.param('spawner_spawnobject', '').split('+'),
  };
  spawnerData.set(go, d);
  // switch_name param read in AS3 (2154) — switches TODO(M2)
  go.timer = go.paramNum('spawner_initialdelay', 0) * FPS;
  go.state = -1;
  go.updateFn = updateSpawner;
  go.renderFn = renderSpawner;
  void g;
}

// ---------------------------------------------------------------------------
// Help text / help object variants (GameObj.as:4020-4255)
// ---------------------------------------------------------------------------

// Game.doWalkthrough — walkthrough mode not ported yet. TODO(M4).
const DO_WALKTHROUGH = false;

// Ease.as:45-48,68-74 — Spring_Out (Penner elastic easeOut, a=c=1, p=0.3)
function springOut(t: number): number {
  if (t === 0) return 0;
  if (t === 1) return 1;
  const p = 0.3;
  const s = p / 4;
  return Math.pow(2, -10 * t) * Math.sin(((t - s) * Math.PI * 2) / p) + 1;
}

// GameObj.as:4020-4065 — GameObj_UpdateHelpText: delay → sfx + spring-scale in
function updateHelpTextW(h: GameObj, g: GameContext): void {
  if (h.state === 0) {
    // logicLink0 switch-link parking (4024-4027) — switches TODO(M2)
    h.visible = false;
    h.timer--;
    if (h.timer <= 0) {
      h.state = 1;
      h.visible = true;
      h.timer = h.timerMax = FPS * 2;
    }
  } else if (h.state === 1) {
    g.audio.playSfx('sfx_text_appear');
    h.visible = true;
    h.scale = 0;
    h.state = 2;
    h.timer = h.timerMax = FPS * 2;
  } else if (h.state === 2) {
    let f = scaleTo(1, 0, 0, h.timerMax, h.timer);
    f = springOut(f);
    h.scale = f;
    if (h.scale < 0) h.scale = 0;
    h.timer--;
    if (h.timer <= 0) h.timer = 0;
  } else if (h.state === 3) {
    // waiting for switch (OnSwitch_HelpText resets to state 0)
  }
}

// GameObj.as:4075-4084 — GameObj_RenderHelpText (TextRenderer bitmap font —
// TODO(M5); canvas text matches core's initHelpText for now)
function renderHelpTextW(h: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  if (!h.visible || h.scale <= 0) return;
  ctx.save();
  ctx.translate(Math.round(h.xpos), Math.round(h.ypos));
  ctx.scale(h.scale, h.scale);
  ctx.font = '16px sans-serif';
  ctx.fillStyle = '#' + h.param('helptext_color', 'ffffff');
  ctx.textAlign = 'center';
  ctx.fillText(h.param('helptext_text', 'helptxt'), 0, 0);
  ctx.restore();
  void g;
}

// GameObj.as:4067-4074 — adds the walkthroughMarker sprite at (-25, -10)
function renderHelpTextWWithMarker(h: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  renderHelpTextW(h, g, ctx);
  if (!h.visible) return;
  g.atlas.draw(ctx, 'walkthroughMarker', 0, Math.round(h.xpos) - 25, Math.round(h.ypos) - 10);
}

// GameObj.as:4100-4122 — GameObj_InitHelpTextW: walkthrough-only help text.
// Starts parked in state 3 until the walkthrough sequencer switches it on;
// removed immediately when walkthrough mode is off (always, until M4).
export function initHelpTextW(go: GameObj, g: GameContext): void {
  go.name = 'walkthrough';
  go.timer = Math.round(go.paramNum('helptext_initialdelay', 0) * FPS);
  go.updateFn = updateHelpTextW;
  go.renderFn = renderHelpTextW;
  go.zpos = -10000;
  go.frame = 0;
  go.state = 3;
  go.scale = 1;
  if (!DO_WALKTHROUGH) {
    go.dead = true; // RemoveObject (GameObj.as:4117-4121)
    go.visible = false;
  }
  void g;
}

// GameObj.as:4095-4099 — GameObj_InitHelpTextW_WithMarker
export function initHelpTextWWithMarker(go: GameObj, g: GameContext): void {
  initHelpTextW(go, g);
  go.renderFn = renderHelpTextWWithMarker;
}

// GameObj_Base.as:712-722 — PlayAnimation over the object's own clip frames
function playFrameAnim(go: GameObj, g: GameContext): boolean {
  const maxFrame = g.atlas.frameCount(go.dobjName) - 1;
  go.frame += go.frameVel;
  if (go.frame > maxFrame) {
    go.frame = maxFrame;
    return true;
  }
  return false;
}

// GameObj.as:4151-4178 — GameObj_UpdateHelpObject: hidden delay → appear and
// play the clip once (arrow/marker sprites)
function updateHelpObject(h: GameObj, g: GameContext): void {
  if (h.state === 0) {
    h.visible = false;
    h.timer--;
    if (h.timer <= 0) {
      h.state = 1;
      h.visible = true;
    }
  } else if (h.state === 1) {
    playFrameAnim(h, g);
    h.visible = true;
    h.state = 2;
  } else if (h.state === 2) {
    playFrameAnim(h, g);
  } else if (h.state === 3) {
    // waiting for switch
  }
}

// GameObj.as:4180-4200 — GameObj_InitHelpObject
export function initHelpObject(go: GameObj, g: GameContext): void {
  go.name = 'text';
  go.timer = Math.round(go.paramNum('helptext_initialdelay', 0) * FPS);
  go.updateFn = updateHelpObject;
  go.zpos = -10000;
  go.frame = 0;
  go.frameVel = 1; // GameObj_Base default frameVel (GameObj_Base.as:214)
  go.state = 0;
  // AS3: if a switch joint targets this object it parks in state 3 until
  // switched (Game.GetSwitchJointName + OnSwitch_HelpText) — switches TODO(M2)
  go.visible = false;
  void g;
}

// ---------------------------------------------------------------------------
// Registry (level-loader merges these by AS3 initfunction name)
// ---------------------------------------------------------------------------

export const registry: Record<string, (go: GameObj, g: GameContext) => void> = {
  InitKeeper: initKeeper,
  InitOpponent: initOpponent,
  InitOpponent_Patrol: initOpponentPatrol,
  InitOpponent_JumpWhenNear: initOpponentJumpWhenNear,
  InitRef_Patrol: initRefPatrol,
  InitRef_Loose: initRefLoose,
  InitPatrolMarker: initPatrolMarker,
  InitJumpMarker: initJumpMarker,
  InitFootball_Beachball: initFootballBeachball,
  InitSpawner: initSpawner,
  GameObj_InitHelpTextW: initHelpTextW,
  GameObj_InitHelpTextW_WithMarker: initHelpTextWWithMarker,
  GameObj_InitHelpObject: initHelpObject,
};

// wire opponent commiseration into core's goal handler (registered at import)
import { setGoalScoredHook } from './core';
setGoalScoredHook((g) => {
  for (const o of g.objects.list) {
    if (o.name === 'opponent' && !o.dead) opponentStartCommiseration(o);
  }
});
