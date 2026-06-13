// Movers & cannons behavior family ported from GameObj.as / GameObj_Base.as,
// plus the level joint factory ported from PhysicsBase.AddJoint_Nape.
import { GameObj, GameContext } from '../gameobj';
import { PhysicsWorld, type JointSpec } from '../../physics/world';
import { VARS, FPS } from '../defs';
import { parkBody, footballLaunch } from './core';
import { scaleToPreLimit, scaleTo, distBetween, easePowerInOut } from '../utils';

// ---------------------------------------------------------------------------
// Switch hooks. AS3 GameObjs expose switchFunction, driven by switch joints
// (Game.GetSwitchJointName). There is no switch system in the web port yet —
// when it lands it should call switchFunctions.get(go)?.() to flip a target.
// TODO(M2/M3): wire switch objects/joints to these.
// ---------------------------------------------------------------------------
export const switchFunctions = new WeakMap<GameObj, () => void>();

// ---------------------------------------------------------------------------
// Fixed cannon (GameObj.as:4479-4571) + the ball's "in cannon" state 200
// (GameObj.as UpdateFootball:4780-4806, spikyball copy at 6663-6684).
// core.ts updateFootball has NO state-200 branch (states 0..4 + 999 only), so
// the cannon drives the held ball directly from its own update — updateFootball
// falls through harmlessly while ball.state === 200.
// ---------------------------------------------------------------------------

// GameVars.as:62 — cannonHoldTime = Defs.fps
const CANNON_HOLD_TIME = FPS;

interface CannonData {
  smokeOn: boolean;
  smokeFrame: number;
}
const cannonData = new WeakMap<GameObj, CannonData>();

// GameObj_Base.as:712-727 PlayAnimation — clamp at the clip's last frame
function playClip(go: GameObj, g: GameContext): boolean {
  const maxFrame = g.atlas.frameCount(go.dobjName) - 1;
  go.frame += go.frameVel;
  if (go.frame > maxFrame) {
    go.frame = maxFrame;
    return true;
  }
  if (go.frame < 0) {
    go.frame = 0;
    return true;
  }
  return false;
}

// GameObj.as:4563-4571 InitFixedCannon
export function initFixedCannon(go: GameObj): void {
  cannonData.set(go, { smokeOn: false, smokeFrame: 0 });
  go.frameVel = 1; // AS3 GameObj default frameVel (GameObjects init)
  go.state = 0;
  go.updateFn = updateCannon;
  go.onHitFn = onHitCannon;
  go.renderFn = renderCannon;
}

// GameObj.as:4479-4496 OnHitCannon (+ Football_InitHoldInCannon 4581-4586)
function onHitCannon(go: GameObj, hitter: GameObj, g: GameContext): void {
  let cando = false;
  if (hitter.name === 'football') cando = true;
  else if (hitter.name === 'spikyball') cando = true;
  if (!cando) return;

  if (go.state === 0) {
    go.state = 1;
    go.timer = CANNON_HOLD_TIME;
    // Football_InitHoldInCannon: ball remembers the cannon and goes to state 200
    go.refA = hitter;
    hitter.state = 200;
    hitter.timer = CANNON_HOLD_TIME;
    g.audio.playSfx('sfx_enter_cannon');
  }
}

// GameObj.as:4502-4510 RenderCannon — top (rotated), base (unrotated), smoke
function renderCannon(go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D): void {
  if (!go.visible) return;
  g.atlas.draw(ctx, go.dobjName, go.frame | 0, go.xpos, go.ypos, { rot: go.dir, scale: go.scale });
  g.atlas.draw(ctx, 'cannon_base', 0, go.xpos, go.ypos, { scale: go.scale });
  const d = cannonData.get(go);
  if (d?.smokeOn) {
    g.atlas.draw(ctx, 'cannonSmoke', d.smokeFrame | 0, go.xpos, go.ypos, { rot: go.dir, scale: go.scale });
  }
}

// GameObj.as:4511-4562 UpdateCannon (+ Cannon_Fired 4497-4501 inlined,
// + UpdateFootball state 200 GameObj.as:4780-4806 driven cannon-side)
function updateCannon(go: GameObj, g: GameContext): void {
  const d = cannonData.get(go)!;
  if (go.state === 0) {
    go.frame = 0;
  } else if (go.state === 1) {
    // holding ball — this is the ball's state-200 logic (GameObj.as:4780-4806)
    const ball = go.refA;
    if (!ball || ball.dead || ball.state !== 200) {
      // safety net (not in AS3): lose the ball, re-arm
      go.refA = null;
      go.state = 0;
      return;
    }
    ball.visible = true;
    ball.xpos = go.xpos;
    ball.ypos = go.ypos;
    parkBody(ball); // PhysicsSetStationary
    ball.timer--;
    if (ball.timer <= 0) {
      // launch along cannon dir minus PI/2, force scaled by ball mass
      const ang = (go.dir * Math.PI) / 180 - Math.PI / 2;
      let speed = VARS.cannonLaunchForce; // VarsData cannonLaunchForce = 1000
      speed *= ball.body ? PhysicsWorld.massNape(ball.body) : 1; // GetBodyMass(0)
      ball.timer = ball.timerMax = FPS * 3;

      // Cannon_Fired (GameObj.as:4497-4501)
      go.state = 2;
      go.timer = go.timerMax = FPS;

      ball.visible = true;
      footballLaunch(ball, Math.cos(ang) * speed, Math.sin(ang) * speed);
      go.refA = null;
    }
  } else if (go.state === 2) {
    // just fired — AS3 computes a smoke offset point (0,-25) rotated by dir but
    // the spawned object is commented out; smoke is drawn via dobj2 instead.
    go.state = 3;
    playClip(go, g);
    g.audio.playSfx('sfx_cannon_fire');
    d.smokeOn = true;
    d.smokeFrame = 0; // frameVel2 = 0.5
  } else if (go.state === 3) {
    if (d.smokeOn) {
      // PlayAnimation2 (GameObj_Base.as:739-749) with frameVel2 = 0.5
      const maxFrame = g.atlas.frameCount('cannonSmoke') - 1;
      d.smokeFrame += 0.5;
      if (d.smokeFrame >= maxFrame) {
        d.smokeFrame = maxFrame;
        d.smokeOn = false;
      }
    }
    playClip(go, g);
    go.timer--;
    if (go.timer <= 0) {
      go.state = 0;
    }
  }
}

// ---------------------------------------------------------------------------
// Path lines registry. AS3 path objects resolve their line by id only:
// GetLineIndexByName (GameObj_Base.as:2298-2311) matches level line.id against
// the object's "path_line" param. The loader should call registerPathLine(id,
// points, spline) for every level line whose polymat initType is 'path'
// (line_material "poly_path"), and clearPathLines() when loading a level.
// ---------------------------------------------------------------------------

interface PathLine {
  id: string;
  points: { x: number; y: number }[];
  spline: boolean; // line param "line_spline" (EditableObjectBase.IsSpline)
}
const pathLines = new Map<string, PathLine>();

export function registerPathLine(id: string, points: number[], spline = false): void {
  const pts: { x: number; y: number }[] = [];
  for (let i = 0; i + 1 < points.length; i += 2) {
    pts.push({ x: points[i], y: points[i + 1] });
  }
  pathLines.set(id, { id, points: pts, spline });
}

export function hasPathLine(id: string): boolean {
  return pathLines.has(id);
}

export function clearPathLines(): void {
  pathLines.clear();
}

// --- EdLine interpolation ---------------------------------------------------

// EdLine.as:405-419 PointOnCurve — Catmull-Rom basis
function pointOnCurve(
  t: number,
  p0: { x: number; y: number },
  p1: { x: number; y: number },
  p2: { x: number; y: number },
  p3: { x: number; y: number },
): { x: number; y: number } {
  const t2 = t * t;
  const t3 = t2 * t;
  return {
    x:
      0.5 *
      (2.0 * p1.x +
        (-p0.x + p2.x) * t +
        (2.0 * p0.x - 5.0 * p1.x + 4 * p2.x - p3.x) * t2 +
        (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3),
    y:
      0.5 *
      (2.0 * p1.y +
        (-p0.y + p2.y) * t +
        (2.0 * p0.y - 5.0 * p1.y + 4 * p2.y - p3.y) * t2 +
        (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3),
  };
}

// Utils.AddIntAndLoop equivalent for point indices
function wrapIndex(i: number, n: number): number {
  return ((i % n) + n) % n;
}

// EdLine.as:421-476 GetPointOnCatmullRom
function pointOnCatmullRom(line: PathLine, t: number, loop: boolean): { x: number; y: number } {
  const np = line.points.length;
  if (np < 4) return { x: 0, y: 0 };
  const numSegs = np;

  let seg = numSegs * t;
  if (seg >= numSegs) seg = numSegs - 1;
  const i = Math.floor(seg);

  let pt0: number;
  let pt2: number;
  let pt3: number;
  const pt1 = i;
  if (loop) {
    pt0 = wrapIndex(i - 1, np);
    pt2 = wrapIndex(i + 1, np);
    pt3 = wrapIndex(i + 2, np);
  } else {
    pt0 = i - 1;
    pt2 = i + 1;
    pt3 = i + 2;
    if (pt0 < 0) pt0 = 0;
    if (pt2 > np - 1) pt2 = np - 1;
    if (pt3 > np - 1) pt3 = np - 1;
  }

  const s0 = (1.0 / numSegs) * i;
  const s1 = (1.0 / numSegs) * (i + 1);
  const t1 = (1.0 / (s1 - s0)) * (t - s0);
  return pointOnCurve(t1, line.points[pt0], line.points[pt1], line.points[pt2], line.points[pt3]);
}

// EdLine.as:579-613 GetInterpolatedPoint_SegmentRatio (+ CalculateLength 328-371)
function interpSegmentRatio(line: PathLine, pos: number, loop: boolean): { x: number; y: number } {
  if (line.spline) return pointOnCatmullRom(line, pos, loop);

  const pts = line.points;
  const n = pts.length;
  if (n <= 1) return { x: 0, y: 0 };

  // CalculateLength: per-segment length ratios
  const segCount = loop ? n : n - 1;
  const lengths: number[] = [];
  let total = 0;
  for (let i = 0; i < segCount; i++) {
    const j = (i + 1) % n;
    const l1 = distBetween(pts[i].x, pts[i].y, pts[j].x, pts[j].y);
    total += l1;
    lengths.push(l1);
  }
  if (total <= 0) return { x: pts[0].x, y: pts[0].y };

  let numPoints = n;
  if (loop) numPoints++;
  const numSegs = numPoints - 1;

  let rr = 0;
  for (let i = 0; i < numSegs; i++) {
    let j = i + 1;
    if (j >= n) j = 0;
    const r = lengths[i] / total;
    const rr1 = rr + r;
    if (pos >= rr && pos <= rr1) {
      const q = scaleTo(0, 1, rr, rr1, pos);
      return {
        x: scaleTo(pts[i].x, pts[j].x, 0, 1, q),
        y: scaleTo(pts[i].y, pts[j].y, 0, 1, q),
      };
    }
    rr += r;
  }
  return { x: 0, y: 0 }; // AS3 falls back to (0,0) too
}

// EdLine.as:616-663 GetInterpolatedPoint_EqualSpacing
function interpEqualSpacing(line: PathLine, pos: number, loop: boolean): { x: number; y: number } {
  if (line.spline) return pointOnCatmullRom(line, pos, loop);

  const pts = line.points;
  const numPoints = pts.length;
  if (numPoints === 0) return { x: 0, y: 0 };
  if (numPoints === 1) return { x: pts[0].x, y: pts[0].y };

  if (loop) {
    const nodelen = 1.0 / numPoints;
    const pi0 = Math.min(Math.floor(numPoints * pos), numPoints - 1);
    const pi1 = (pi0 + 1) % numPoints;
    const pos0 = pi0 * nodelen;
    const pos1 = (pi0 + 1) * nodelen;
    return {
      x: scaleTo(pts[pi0].x, pts[pi1].x, pos0, pos1, pos),
      y: scaleTo(pts[pi0].y, pts[pi1].y, pos0, pos1, pos),
    };
  }
  const nodelen = 1.0 / (numPoints - 1);
  const pi0 = Math.min(Math.floor((numPoints - 1) * pos), numPoints - 2);
  const pi1 = (pi0 + 1) % numPoints;
  const pos0 = pi0 * nodelen;
  const pos1 = (pi0 + 1) * nodelen;
  return {
    x: scaleTo(pts[pi0].x, pts[pi1].x, pos0, pos1, pos),
    y: scaleTo(pts[pi0].y, pts[pi1].y, pos0, pos1, pos),
  };
}

// --- Ease.as:27-136 EaseByName (linear / power / spring=Penner elastic) -----

function elasticIn(t: number): number {
  // Ease.as:61-67 easeIn with b=0, c=1, d=1, a=0, p=0 -> a=1, p=0.3, s=p/4
  if (t === 0) return 0;
  if (t === 1) return 1;
  const p = 0.3;
  const s = p / 4;
  const t1 = t - 1;
  return -(Math.pow(2, 10 * t1) * Math.sin(((t1 - s) * (Math.PI * 2)) / p));
}

function elasticOut(t: number): number {
  // Ease.as:68-74 easeOut with b=0, c=1, d=1
  if (t === 0) return 0;
  if (t === 1) return 1;
  const p = 0.3;
  const s = p / 4;
  return Math.pow(2, -10 * t) * Math.sin(((t - s) * (Math.PI * 2)) / p) + 1;
}

function elasticInOut(t: number): number {
  // Ease.as:75-82 easeInOut with b=0, c=1, d=1
  if (t === 0) return 0;
  let t2 = t / 0.5;
  if (t2 === 2) return 1;
  const p = 0.3 * 1.5;
  const s = p / 4;
  if (t2 < 1) {
    t2 -= 1;
    return -0.5 * (Math.pow(2, 10 * t2) * Math.sin(((t2 - s) * (Math.PI * 2)) / p));
  }
  t2 -= 1;
  return Math.pow(2, -10 * t2) * Math.sin(((t2 - s) * (Math.PI * 2)) / p) * 0.5 + 1;
}

// Ease.as:27-37 EaseByName
function easeByName(name: string, time: number, value: number): number {
  if (name === 'linear') return time;
  if (name === 'power_in') return Math.pow(time, value);
  if (name === 'power_out') return 1 - Math.pow(1 - time, value);
  if (name === 'power_inout') return easePowerInOut(time, value);
  if (name === 'spring_in') return elasticIn(time);
  if (name === 'spring_out') return elasticOut(time);
  if (name === 'spring_inout') return elasticInOut(time);
  return time;
}

// ---------------------------------------------------------------------------
// Path object (GameObj_Base.as InitPhysObj_Path:3278-3347,
// SwitchFunction_PhysObj_Path_New:3350-3381, UpdatePhysObj_Path_New:3390-3477,
// UpdateLine:1403-1445; virtual variant GameObj.as:382-387).
// ---------------------------------------------------------------------------

interface PathData {
  lineId: string;
  line: PathLine | null;
  lineSpeed: number; // fraction of the line per frame (1 / (path_speed * fps))
  lineLinearPos: number; // 0..1
  lineLoop: boolean;
  endMode: string; // stop / loop / bounce / reset
  switchMode: string; // start / start_doubleswitch / stop / toggle_dir / toggle_movement
  easeName: string;
  easeValue: number;
  controlMode: number; // 0 stationary, 1 moving
}
const pathData = new WeakMap<GameObj, PathData>();

// UpdateLine(0)'s position sampling (GameObj_Base.as:1403-1445): clamp/wrap the
// linear pos, apply the ease, then interpolate. Loop+polyline uses the
// length-proportional SegmentRatio path, everything else EqualSpacing.
function pathPoint(data: PathData): { x: number; y: number } | null {
  const line = data.line;
  if (!line || line.points.length === 0) return null;

  if (data.lineLinearPos > 1) {
    data.lineLinearPos = data.lineLoop ? data.lineLinearPos - 1 : 1;
  }
  if (data.lineLinearPos < 0) {
    data.lineLinearPos = data.lineLoop ? data.lineLinearPos + 1 : 0;
  }

  let lp = data.lineLinearPos;
  if (data.easeName !== '' && data.easeName !== 'linear') {
    lp = easeByName(data.easeName, lp, data.easeValue);
  }

  if (data.lineLoop && !line.spline) {
    return interpSegmentRatio(line, lp, data.lineLoop);
  }
  return interpEqualSpacing(line, lp, data.lineLoop);
}

// UpdatePhysObj_Path_SetPos (GameObj_Base.as:3383-3389). The body is KINEMATIC
// and velocity-driven toward the path target: teleporting it (like the AS3
// SetBodyXForm) leaves zero solver velocity in Box2D, so welded platforms
// impart no motion to objects riding them and crate stacks slip off.
// Velocity = (target - current) * fps self-corrects drift each frame.
function setPathPos(go: GameObj, data: PathData): void {
  const p = pathPoint(data);
  if (!p) return;
  go.xpos = p.x;
  go.ypos = p.y;
  if (go.body) {
    const cur = PhysicsWorld.getPosPx(go.body);
    const vx = (p.x - cur.x) * 60;
    const vy = (p.y - cur.y) * 60;
    PhysicsWorld.setVelPx(go.body, vx, vy);
    if (Math.abs(vx) > 0.5 || Math.abs(vy) > 0.5) {
      // kinematic motion doesn't wake sleeping joint partners in Box2D
      PhysicsWorld.wakeJointPartners(go.body);
    }
  }
}

// GameObj.as:382-387 InitPhysObj_Path_Virtual — invisible path mover (visible
// only with Game.usedebug)
export function initPhysObj_Path_Virtual(go: GameObj, g: GameContext): void {
  initPhysObj_Path(go, g);
  go.visible = false;
}

// GameObj_Base.as:3278-3347 InitPhysObj_Path
function initPhysObj_Path(go: GameObj, g: GameContext): void {
  const endMode = go.param('path_endmode', 'stop');
  const switchMode = go.param('path_switchmode', 'stop');
  const easeName = go.param('path_ease', 'linear');
  const easeValue = go.paramNum('path_easevalue', 1);
  const startMode = go.param('path_startmode', 'start');

  const lineName = go.param('path_line', '');
  if (lineName === '') {
    console.error('ERROR: Path Object has no line');
    return;
  }

  const data: PathData = {
    lineId: lineName,
    line: pathLines.get(lineName) ?? null, // resolved lazily if not registered yet
    lineSpeed: 1 / (go.paramNum('path_speed') * FPS),
    lineLinearPos: go.paramNum('path_startpos', 0),
    lineLoop: false,
    endMode,
    switchMode,
    easeName,
    easeValue,
    controlMode: 0,
  };
  pathData.set(go, data);

  // NOTE: AS3 also reads path_rotatetopath (3312) but UpdatePhysObj_Path_New
  // never applies it — it is dead in the shipped path code, so omitted here.

  // kinematic + velocity-driven (see setPathPos) so welded platforms carry
  // their riders; the park loop must not zero the velocity each frame
  go.physicsStationary = false;
  if (go.body) PhysicsWorld.setType(go.body, 'kinematic');
  const p = pathPoint(data);
  if (p) {
    go.xpos = go.startx = p.x;
    go.ypos = go.starty = p.y;
    if (go.body) PhysicsWorld.setPosPx(go.body, p.x, p.y, go.dir); // SetBodyXForm_Immediate
  }

  // start / stop (GameObj_Base.as:3335-3345)
  if (startMode === 'stop') data.controlMode = 0;
  if (startMode === 'start') data.controlMode = 1;
  if (startMode === 'start_reverse') {
    data.controlMode = 1;
    data.lineSpeed *= -1;
  }

  go.updateFn = updatePhysObj_Path_New;
  switchFunctions.set(go, () => switchPhysObj_Path_New(go));
  void g;
}

// GameObj_Base.as:3350-3381 SwitchFunction_PhysObj_Path_New
function switchPhysObj_Path_New(go: GameObj): void {
  const data = pathData.get(go);
  if (!data) return;
  if (data.switchMode === 'start') {
    data.controlMode = 1;
  }
  if (data.switchMode === 'start_doubleswitch') {
    // for timed switches
    if (data.lineLinearPos === 0) {
      data.lineSpeed = Math.abs(data.lineSpeed);
    } else {
      data.lineSpeed = -Math.abs(data.lineSpeed);
    }
    data.controlMode = 1;
  }
  if (data.switchMode === 'stop') {
    data.controlMode = 0;
  }
  if (data.switchMode === 'toggle_dir') {
    data.lineSpeed *= -1;
    data.controlMode = 1;
  }
  if (data.switchMode === 'toggle_movement') {
    data.controlMode = 1 - data.controlMode;
  }
}

// GameObj_Base.as:3390-3477 UpdatePhysObj_Path_New
function updatePhysObj_Path_New(go: GameObj): void {
  const data = pathData.get(go);
  if (!data) return;
  if (!data.line) {
    // line registered after init (loader ordering) — resolve lazily
    data.line = pathLines.get(data.lineId) ?? null;
    if (!data.line) return;
    setPathPos(go, data);
  }

  if (data.controlMode === 0) {
    // stationary
    setPathPos(go, data);
  } else if (data.controlMode === 1) {
    // moving — path_endmode = bounce / stop / loop / reset
    data.lineLoop = data.endMode === 'loop';
    data.lineLinearPos += data.lineSpeed;

    if (data.endMode === 'loop') {
      if (data.lineLinearPos > 1) data.lineLinearPos -= 1;
      else if (data.lineLinearPos < 0) data.lineLinearPos += 1;
    } else if (data.endMode === 'bounce') {
      if (data.lineLinearPos > 1) {
        data.lineLinearPos = 1;
        data.lineSpeed *= -1;
      } else if (data.lineLinearPos < 0) {
        data.lineLinearPos = 0;
        data.lineSpeed *= -1;
      }
    } else if (data.endMode === 'stop') {
      if (data.lineLinearPos > 1) {
        data.lineLinearPos = 1;
        data.controlMode = 0;
      } else if (data.lineLinearPos < 0) {
        data.controlMode = 0;
        data.lineLinearPos = 0;
      }
    } else if (data.endMode === 'reset') {
      if (data.lineLinearPos > 1) {
        data.lineLinearPos = 0;
        data.controlMode = 0;
      } else if (data.lineLinearPos < 0) {
        data.lineLinearPos = 1;
        data.controlMode = 0;
      }
    }
    setPathPos(go, data);
  }
}

// ---------------------------------------------------------------------------
// Animated-when-moving (GameObj.as:7168-7179) — clip speed proportional to the
// body's linear velocity: frameVel = ScaleToPreLimit(0, 2, 0, 100, |v| px/s).
// ---------------------------------------------------------------------------

export function initAnimatedWhenMoving(go: GameObj): void {
  go.frameVel = 0;
  go.updateFn = (o, g) => {
    // CycleAnimation (GameObj_Base.as:693-701)
    const maxFrame = g.atlas.frameCount(o.dobjName);
    o.frame += o.frameVel;
    if (maxFrame > 0) {
      if (o.frame >= maxFrame) o.frame -= maxFrame;
      if (o.frame < 0) o.frame += maxFrame;
    }
    let v = 0;
    if (o.body) {
      const vel = PhysicsWorld.getVelPx(o.body);
      v = Math.hypot(vel.x, vel.y);
    }
    o.frameVel = scaleToPreLimit(0, 2, 0, 100, v);
  };
}

// ---------------------------------------------------------------------------
// Cog (GameObj.as:6843-6873) — rotates between 0 and 6 radians at 0.1 rad per
// frame; the direction is flipped by its switch. AS3 dir is radians, web dir
// is degrees, so the constants are converted exactly. NOTE: InitCog does not
// read the rotator_vel objparam — the rate is hardcoded in UpdateCog.
// ---------------------------------------------------------------------------

const COG_STEP_DEG = (0.1 * 180) / Math.PI;
const COG_MAX_DEG = (6 * 180) / Math.PI;

export function initCog(go: GameObj): void {
  go.state = 1;
  go.updateFn = (o) => {
    // UpdateCog (GameObj.as:6854-6866)
    if (o.state === 0) {
      o.dir += COG_STEP_DEG;
      if (o.dir >= COG_MAX_DEG) o.dir = COG_MAX_DEG;
    } else if (o.state === 1) {
      o.dir -= COG_STEP_DEG;
      if (o.dir < 0) o.dir = 0;
    }
  };
  // SwitchedCog (GameObj.as:6843-6853)
  switchFunctions.set(go, () => {
    go.state = go.state === 0 ? 1 : 0;
  });
}

// ---------------------------------------------------------------------------
// Icecream van (GameObj.as:3097-3120) — static scenery; plays its jingle when
// hit, with a 5-second cooldown. NOTE: the physobj def has hasPhysics=false so
// the current loader creates no body — onHit will never fire until the loader
// also builds bodies for hasPhysics=false defs with shapes (AS3 does).
// ---------------------------------------------------------------------------

export function initIcecreamVan(go: GameObj): void {
  go.updateFn = (o) => {
    // UpdateIcecreamVan (GameObj.as:3105-3115)
    if (o.state === 1) {
      o.timer--;
      if (o.timer <= 0) {
        o.state = 0;
      }
    }
  };
  go.onHitFn = (o, _hitter, g) => {
    // OnHitIcecreamVan (GameObj.as:3097-3104)
    if (o.state !== 0) return;
    o.state = 1;
    o.timer = FPS * 5;
    g.audio.playSfx('sfx_icecreamvan');
  };
}

// ---------------------------------------------------------------------------
// Level joints — PhysicsBase.AddJoint_Nape (PhysicsBase.as:561-810) mapped from
// Nape constraints to planck joints. Anchors/lengths are px / 30 = meters.
// ---------------------------------------------------------------------------

/** Shape of one entry in LevelDef.joints (level-loader.ts). */
export interface LevelJointDef {
  id: string;
  type: string;
  obj0: string;
  obj1: string;
  /** 'rev' world anchor */
  x: number;
  y: number;
  /** 'dist' world anchors */
  x0: number;
  y0: number;
  x1: number;
  y1: number;
  params: Record<string, string>;
}

function jStr(j: LevelJointDef, name: string, def = ''): string {
  const v = j.params[name];
  return v === undefined || v === '' ? def : v;
}
function jNum(j: LevelJointDef, name: string, def = 0): number {
  const v = Number(j.params[name]);
  return Number.isNaN(v) ? def : v;
}
function jBool(j: LevelJointDef, name: string): boolean {
  return jStr(j, name) === 'true';
}

// Joints against the world (obj name "") attach to Nape's static space.world
// body; planck needs an explicit static ground body per world.
/**
 * Create a level joint between goA (joint.obj0) and goB (joint.obj1); pass null
 * for either to attach to the static world body. The engine-specific joint
 * construction lives in each PhysWorld.createLevelJoint; here we normalize the
 * LevelJointDef into an engine-neutral JointSpec. Supported types: 'rev',
 * 'dist', 'weld' ('logic'/'switch' joints are object links / editor wiring).
 */
export function createLevelJoint(
  g: GameContext,
  type: string,
  goA: GameObj | null,
  goB: GameObj | null,
  jointDef: LevelJointDef,
): void {
  if (type !== 'rev' && type !== 'weld' && type !== 'dist') return;
  const weld = type === 'weld';
  const spec: JointSpec = {
    type,
    // joinedBodiesIgnoreCollision = !collide_joined (PhysicsBase.as:565-566)
    collideConnected: jBool(jointDef, 'collide_joined'),
    // rev (PhysicsBase.as:641-695). Nape MotorJoint rate (rad/s) -> motorSpeed;
    // maxForce stays in Nape px torque units (engine converts).
    anchorXPx: jointDef.x,
    anchorYPx: jointDef.y,
    enableMotor: jBool(jointDef, 'rev_enablemotor'),
    motorSpeed: jNum(jointDef, 'rev_motorrate'),
    maxMotorTorquePx: jNum(jointDef, 'rev_motormax', 10000),
    enableLimit: jBool(jointDef, 'rev_enablelimit'),
    lowerAngleRad: (jNum(jointDef, 'rev_lowerangle') * Math.PI) / 180,
    upperAngleRad: (jNum(jointDef, 'rev_upperangle') * Math.PI) / 180,
    // weld / dist soft constraint
    soft: weld ? jBool(jointDef, 'weld_soft') : jBool(jointDef, 'dist_soft'),
    softFreq: weld ? jNum(jointDef, 'weld_soft_frequency') : jNum(jointDef, 'dist_soft_frequency'),
    // dist (PhysicsBase.as:744-783)
    x0Px: jointDef.x0,
    y0Px: jointDef.y0,
    x1Px: jointDef.x1,
    y1Px: jointDef.y1,
    distLimitPx: jNum(jointDef, 'dist_limit'),
  };
  g.physics.createLevelJoint(spec, goA?.body ?? null, goB?.body ?? null);
}

// ---------------------------------------------------------------------------
// Registry (PORTING.md file shape) — exact AS3 initfunction names.
// ---------------------------------------------------------------------------

export const registry: Record<string, (go: GameObj, g: GameContext) => void> = {
  InitFixedCannon: initFixedCannon,
  InitPhysObj_Path_Virtual: initPhysObj_Path_Virtual,
  InitAnimatedWhenMoving: initAnimatedWhenMoving,
  InitCog: initCog,
  InitIcecreamVan: initIcecreamVan,
};
