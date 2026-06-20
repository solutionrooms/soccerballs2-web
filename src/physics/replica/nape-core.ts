// Hand-ported, bit-exact, readable replica of the ORIGINAL game's Nape engine.
//
// Source of truth: the game's OWN decompiled Nape, under
//   tools/swf-decomp/scripts/zpp_nape/*
// (decompiled from the shipped SoccerBalls2.swf) — the exact version the game
// ran on. We deliberately do NOT use nape.js: it is a different, newer Nape
// build (nape-haxe4 2.0.22) whose integrator was refactored, so it is the wrong
// version. Every arithmetic expression below mirrors the original's *operation
// order* exactly (same groupings, same temporaries), because two IEEE-754
// double computations are bit-identical only when their operation order matches.
//
// The differential harness (diff.ts) grades this readable replica against the
// transpiled original (original/original-nape.ts) after every step. Citations
// like `ZPP_Space.as:1312` point at the original source line.
//
// Build is incremental, one milestone per gate:
//   M0  free-fall of a single dynamic Circle: Space.updateVel / Space.updatePos
//       integration + circle mass properties. No broadphase / contacts yet.

// Nape's internal BodyType ids (ZPP_Flags). STATIC==1, DYNAMIC==2, KINEMATIC==3
// (the last added with kinematic bodies in a later milestone).
const TYPE_STATIC = 1;
const TYPE_DYNAMIC = 2;
const TYPE_KINEMATIC = 3;

// Nape's "infinite" mass/inertia constant for non-dynamic bodies (ZPP_Body.as:350).
const STATIC_MASS = 1.79e308;

// Nape normalizes with a Quake fast-inverse-sqrt (float32 bit-hack + ONE Newton
// step), NOT Math.sqrt — so normals/distances it produces carry that specific
// approximation error (e.g. a "unit" normal of length 0.99977). Replicated
// bit-exact via a float32 round-trip (ZPP_Collide.as:1155 `sf32/si32/li32/lf32`).
const _fisrF32 = new Float32Array(1);
const _fisrI32 = new Int32Array(_fisrF32.buffer);
function fastInvSqrt(x: number): number {
  _fisrF32[0] = x;
  _fisrI32[0] = 1597463007 - (_fisrI32[0] >> 1);
  const g = _fisrF32[0];
  return g * (1.5 - 0.5 * x * g * g);
}

// Nape combines two material coefficients (friction/rolling) by the GEOMETRIC
// MEAN, computed as the reciprocal of the fast-inverse-sqrt of their product —
// `1 / fastInvSqrt(a·b)` — not Math.sqrt (ZPP_Space.as:4142). Zero if either is 0.
function combineGeoMean(a: number, b: number): number {
  const x = a * b;
  if (x === 0) return 0;
  return 1 / fastInvSqrt(x);
}

// Unordered pair key for arbiter persistence across steps.
function pairKey(h1: number, h2: number): string {
  return h1 < h2 ? `${h1}-${h2}` : `${h2}-${h1}`;
}

interface CircleShape {
  kind: 'circle';
  // local placement (Vec2 passed to `new Circle(radius, pos, ...)`)
  localx: number;
  localy: number;
  radius: number;
  // Material density as Nape stores it internally: the raw arg / 1000
  // (Material.as:51). Sensor copies arrive as density 0 and contribute no mass.
  density: number;
  friction: number;
  rolling: number;
  elasticity: number;
  // derived by validate_area_inertia (ZPP_Circle.as:72)
  area: number;
  inertia: number; // per-shape inertia coefficient (about body origin)
  localCOMx: number;
  localCOMy: number;
  // [M4-CCD] swept extent (ZPP_Circle.as:66): sweepCoef = |localCOM|, radius adds
  sweepCoef: number;
  sweepRadius: number;
  // [F1] interaction filter (NapeWorld.hx:133 mkFilter). A shape is collider XOR
  // sensor: isSensor moves colCat/colMask into the sensor group/mask (collision
  // group/mask 0), so the collision-filter test alone keeps sensors out of the solver.
  colGroup: number;
  colMask: number;
  senGroup: number;
  senMask: number;
  isSensor: boolean;
  origColMask: number; // [facade] mask at creation — for setBodyCollision restore
  origSenMask: number;
  sid: number; // [E2] unique shape id (arbiter keying)
}

interface PolygonShape {
  kind: 'polygon';
  // flattened local vertices [x0,y0,x1,y1,…] relative to the body origin
  verts: number[];
  density: number; // raw / 1000 (Material.as:51)
  friction: number;
  rolling: number;
  elasticity: number;
  // derived by validate_area_inertia (ZPP_Polygon.as:1198) + localCOM (ZPP_Body.as:360)
  area: number;
  inertia: number;
  localCOMx: number;
  localCOMy: number;
  // [M4-CCD] swept extent (max vertex distance from COM + radius 0 for polygons)
  sweepCoef: number;
  sweepRadius: number;
  // [F1] interaction filter (NapeWorld.hx:133 mkFilter) — see CircleShape.
  colGroup: number;
  colMask: number;
  senGroup: number;
  senMask: number;
  isSensor: boolean;
  origColMask: number; // [facade] mask at creation — for setBodyCollision restore
  origSenMask: number;
  sid: number; // [E2] unique shape id (arbiter keying)
}

type Shape = CircleShape | PolygonShape;

// [F1] mkFilter (NapeWorld.hx:133): a shape is a collider XOR a sensor.
function makeFilter(colCat: number, colMask: number, isSensor: boolean): {
  colGroup: number; colMask: number; senGroup: number; senMask: number; isSensor: boolean;
} {
  if (isSensor) {
    return { colGroup: 0, colMask: 0, senGroup: colCat, senMask: colMask, isSensor: true };
  }
  return { colGroup: colCat, colMask, senGroup: 0, senMask: 0, isSensor: false };
}

// [F2] InteractionFilter.shouldCollide — two shapes generate a collision arbiter iff
// each group is in the other's mask (zpp_nape InteractionFilter). A sensor has
// collisionGroup 0, so any pair involving a sensor fails this and never reaches the
// solver (sensor OVERLAP events are a separate facade concern).
function shouldCollide(a: Shape, b: Shape): boolean {
  return (a.colGroup & b.colMask) !== 0 && (b.colGroup & a.colMask) !== 0;
}

interface Body {
  handle: number;
  type: number;
  // transform
  posx: number;
  posy: number;
  rot: number;
  axisx: number; // sin(rot)  (ZPP_Body.as:307)
  axisy: number; // cos(rot)  (ZPP_Body.as:308)
  // motion
  velx: number;
  vely: number;
  angvel: number;
  forcex: number;
  forcey: number;
  torque: number;
  // mass terms (zpp_nape.phys.ZPP_Body)
  cmass: number;
  mass: number;
  imass: number;
  smass: number;
  gravMass: number;
  cinertia: number;
  inertia: number;
  iinertia: number;
  sinertia: number;
  localCOMx: number;
  localCOMy: number;
  worldCOMx: number;
  worldCOMy: number;
  // movement gates (finalizeBody fallbacks)
  allowMovement: boolean;
  allowRotation: boolean;
  // position-integration bookkeeping (ZPP_Space.as:1372)
  pre_posx: number;
  pre_posy: number;
  pre_rot: number;
  sweepTime: number;
  // [M4-CCD] continuous-collision sweep state
  sweepRadius: number; // max over shapes (ZPP_Space.as:895)
  sweep_angvel: number; // angvel % (2π/dt) (ZPP_Space.as:1447)
  sweepFrozen: boolean; // true once arrested / not fast enough to sweep
  // [E3] sleeping (ZPP_Body.atRest / ZPP_Space.doForests). waket = last stamp the
  // body was NOT at rest; an island sleeps when every member has waket+60 < stamp.
  // Static bodies are permanently `sleeping` (so their arbiters with a sleeping
  // dynamic body skip the solver).
  waket: number;
  sleeping: boolean;
  shapes: Shape[];
  userData: Record<string, unknown>;
}

// [M4] One contact point of a collision arbiter (zpp_nape.dynamics.ZPP_Contact /
// ZPP_IContact). jnAcc/jtAcc PERSIST across steps (warm starting) — they are the
// load-bearing state of the sequential-impulse solver. Cited fields map to the
// original: px/py (ZPP_Collide.as:1009), dist (loc6 separation), lr1/lr2 (local
// contact arms, ZPP_Collide.as:1082), the prestep-derived arms r1/r2 and the
// effective masses nMass/tMass (ZPP_Space.as:4255-4276).
interface SolverContact {
  hash: number;
  px: number; // world contact point
  py: number;
  dist: number; // separation (negative when penetrating); loc6
  lr1x: number; // local arm on b1 (ptype 0/1: circle localCOM; ptype 2: lr1)
  lr1y: number;
  lr2x: number; // local arm on b2 (ptype 2 only)
  lr2y: number;
  r1x: number; // world arm contact−b1.pos (prestep)
  r1y: number;
  r2x: number; // world arm contact−b2.pos (prestep)
  r2y: number;
  nMass: number;
  tMass: number;
  bounce: number;
  friction: number;
  elasticity: number;
  jnAcc: number; // accumulated normal impulse (persists across steps)
  jtAcc: number; // accumulated tangent impulse (persists across steps)
  stamp: number;
  active: boolean;
  fresh: boolean;
  posOnly: boolean;
}

// [M4] A collision arbiter (zpp_nape.dynamics.ZPP_ColArbiter) between two bodies.
// INTERNAL body order matters for the solver math: for circle-vs-polygon the
// circle is b1 and the polygon is b2 (verified against the original — only this
// order makes iteratePos reduce to the observed resting separation). The public
// Nape Arbiter.body1/body2 is id-sorted and may be the reverse of (b1,b2).
interface Arbiter {
  key: string;
  b1: Body;
  b2: Body;
  s1: Shape; // shapes carry the materials for the combine (ZPP_Space.as:4115)
  s2: Shape;
  invalidated: boolean;
  // world contact normal (ZPP_Collide.as:1068)
  nx: number;
  ny: number;
  // position-solver geometry (ZPP_Collide.as:1076)
  ptype: number; // 0/1 = edge-face (which body owns the face), 2 = circle vertex
  rev: boolean;
  lnormx: number; // owning polygon's edge normal, in its local frame
  lnormy: number;
  lproj: number;
  radius: number;
  // prestep scalars (ZPP_Space.as:4161-4427)
  biasCoef: number;
  pre_dt: number;
  continuous: boolean;
  restitution: number;
  dyn_fric: number;
  stat_fric: number;
  rfric: number;
  surfacex: number;
  surfacey: number;
  rMass: number;
  jrAcc: number;
  contacts: SolverContact[];
  c1: SolverContact | null;
  c2: SolverContact | null;
  oc1: SolverContact | null;
  oc2: SolverContact | null;
  hc2: boolean;
  hpc2: boolean;
  k1x: number;
  k1y: number;
  k2x: number;
  k2y: number;
  rn1a: number;
  rt1a: number;
  rn1b: number;
  rt1b: number;
  rn2a: number;
  rt2a: number;
  rn2b: number;
  rt2b: number;
  Ka: number;
  Kb: number;
  Kc: number;
  kMassa: number;
  kMassb: number;
  kMassc: number;
  stamp: number;
  active: boolean;
}

// [M5] A PivotJoint constraint (zpp_nape.constraint.ZPP_PivotJoint): pins a local
// anchor on b1 to a local anchor on b2 (a 2-DOF point-to-point constraint). Solved
// with the same sequential-impulse framework as contacts. `stiff` (default true)
// ⇒ no soft-constraint bias/gamma. jAcc persists across steps (warm starting).
interface PivotJoint {
  kind: 'pivot';
  b1: Body;
  b2: Body;
  a1localx: number;
  a1localy: number;
  a2localx: number;
  a2localy: number;
  a1relx: number;
  a1rely: number;
  a2relx: number;
  a2rely: number;
  kMassa: number;
  kMassb: number;
  kMassc: number;
  jAccx: number;
  jAccy: number;
  biasx: number;
  biasy: number;
  gamma: number;
  jMax: number;
  stiff: boolean;
  pre_dt: number;
}

// [M5] A WeldJoint (zpp_nape.constraint.ZPP_WeldJoint): PivotJoint's 2-DOF point
// constraint PLUS a 1-DOF angular lock (b2.rot − b1.rot = phase) → a 3-DOF
// constraint with a symmetric 3×3 effective-mass matrix [a b c; b d e; c e f].
// jAccx/jAccy (linear) + jAccz (angular) persist across steps (warm starting).
interface WeldJoint {
  kind: 'weld';
  b1: Body;
  b2: Body;
  a1localx: number;
  a1localy: number;
  a2localx: number;
  a2localy: number;
  phase: number; // rest value of (b2.rot − b1.rot)
  a1relx: number;
  a1rely: number;
  a2relx: number;
  a2rely: number;
  kMassa: number;
  kMassb: number;
  kMassc: number;
  kMassd: number;
  kMasse: number;
  kMassf: number;
  jAccx: number;
  jAccy: number;
  jAccz: number;
  biasx: number;
  biasy: number;
  biasz: number;
  gamma: number;
  jMax: number;
  stiff: boolean;
  pre_dt: number;
}

// [M5] A DistanceJoint (zpp_nape.constraint.ZPP_DistanceJoint): keeps the distance
// between two local anchors within [jointMin, jointMax] — a 1-DOF constraint along
// the anchor-to-anchor direction. `equal` (min==max) ⇒ a rigid rod (bilateral);
// otherwise a rope that only resists when outside the range (`slack` when inside).
// Distance is computed with the fast-inverse-sqrt (1/fastInvSqrt(d²)).
interface DistanceJoint {
  kind: 'distance';
  b1: Body;
  b2: Body;
  a1localx: number;
  a1localy: number;
  a2localx: number;
  a2localy: number;
  jointMin: number;
  jointMax: number;
  equal: boolean;
  slack: boolean;
  a1relx: number;
  a1rely: number;
  a2relx: number;
  a2rely: number;
  nx: number; // unit (or flipped) direction of the constraint
  ny: number;
  cx1: number; // angular lever terms
  cx2: number;
  kMass: number;
  jAcc: number;
  bias: number;
  gamma: number;
  jMax: number;
  stiff: boolean;
  pre_dt: number;
}

// [M5] An AngleJoint (zpp_nape.constraint.ZPP_AngleJoint): a PURELY ANGULAR 1-DOF
// constraint keeping `ratio·b2.rot − b1.rot` within [jointMin, jointMax]. It reads
// only rot/angvel/inertia (never the sin/cos axis), so a centred-COM body can spin
// and still be graded bit-for-bit. `equal` ⇒ a rigid angular weld; else an angle
// limit (`slack` while inside the range).
interface AngleJoint {
  kind: 'angle';
  b1: Body;
  b2: Body;
  jointMin: number;
  jointMax: number;
  ratio: number;
  equal: boolean;
  slack: boolean;
  scale: number; // +1/-1 active-limit direction, 0 when slack
  kMass: number;
  jAcc: number;
  bias: number;
  gamma: number;
  jMax: number;
  stiff: boolean;
  pre_dt: number;
}

// [M5] A MotorJoint (zpp_nape.constraint.ZPP_MotorJoint): drives the relative
// angular velocity `ratio·b2.angvel − b1.angvel` toward `rate` — a purely-angular
// VELOCITY constraint (no position correction). Always active.
interface MotorJoint {
  kind: 'motor';
  b1: Body;
  b2: Body;
  rate: number;
  ratio: number;
  kMass: number;
  jAcc: number;
  jMax: number;
  pre_dt: number;
}

type Constraint = PivotJoint | WeldJoint | DistanceJoint | AngleJoint | MotorJoint;

// [M4-CCD] A time-of-impact event for the continuous-collision sweep
// (zpp_nape.geom.ZPP_ToiEvent). `mv`/`ms` = the moving body+shape (a circle here),
// `stat`/`ss` = the static polygon. c1/axis = witness point on the mover + the
// contact normal; toi = the impact fraction in [0,1] (−1 = no impact this step).
interface ToiEvent {
  mv: Body;
  ms: Shape; // moving shape — circle or polygon (rotating crate)
  stat: Body;
  ss: Shape; // static shape — circle or polygon
  c1x: number;
  c1y: number;
  axisx: number;
  axisy: number;
  toi: number;
  slipped: boolean;
  failed: boolean;
}

/**
 * Faithful Nape replica exposing the same low-level handle API as the compiled
 * `NapeWorld` facade (tools/nape/NapeWorld.hx), so the differential harness can
 * drive this and the reference engine through one identical call script.
 */
export class NapeReplica {
  // Space (zpp_nape.space.ZPP_Space)
  private gravityx = 0;
  private gravityy = 0;
  private readonly global_lin_drag = 0.015; // ZPP_Space.as:205
  private readonly global_ang_drag = 0.015; // ZPP_Space.as:206

  private bodies = new Map<number, Body>();
  private live: Body[] = [];
  private nextHandle = 1;
  private nextShapeId = 1; // [E2] per-shape id, so arbiters key per shape-PAIR

  // [M4] persistent arbiters, keyed by the unordered shape-id pair (a multi-shape
  // body has one arbiter per shape-pair), so a contact's accumulated impulses
  // survive between steps (warm starting).
  private arbiters = new Map<string, Arbiter>();
  private stamp = 0;
  // [M5] live constraints (joints), solved alongside contacts.
  private constraints: Constraint[] = [];

  // [facade] static world body @ handle 0 (joints attach to "the world"), the
  // joint-partner graph (wake welded riders), and the per-step BEGIN-event buffers.
  private worldBody: Body;
  private jointPartners = new Map<number, number[]>();
  // [joints] body pairs whose collision is suppressed because they're connected by a joint
  // built with collide_joined=false. The shipped game uses collide_joined=false on ALL 98
  // joints (PhysicsBase.as:142 default + every level), and sets joint.ignore=true — so jointed
  // bodies must NOT collide. Without this, a body overlapping its joint partner (e.g. the
  // metalpost chassis sits INSIDE the wheel it's revolute-jointed to) generates an internal
  // contact that fights the joint and locks the assembly (level-36 "ref on wheels" never rolls).
  private ignoredPairs = new Set<string>();
  private contactsBuf: number[] = []; // [hA,hB,sensorFlag, ...] BEGIN events
  private ongoingBuf: number[] = []; // [hA,hB,sensorFlag, ...] ONGOING (every awake step a pair persists)
  private impactsBuf: number[] = []; // [hA,hB,|normalImpulse|,nx,ny, ...]
  private activeColPairs = new Set<string>();
  private activeSenPairs = new Set<string>();

  constructor(gravityPxY: number) {
    this.gravityx = 0;
    this.gravityy = gravityPxY;
    this.worldBody = this.makeWorldBody();
    this.bodies.set(0, this.worldBody); // handle 0 resolves to the world body
  }

  setGravity(gpxY: number): void {
    this.gravityx = 0;
    this.gravityy = gpxY;
  }

  // --- body construction --------------------------------------------------
  createBody(
    isStatic: boolean,
    xPx: number,
    yPx: number,
    rotDeg: number,
    _linDamp: number,
    _angDamp: number,
  ): number {
    // linDamp/angDamp are intentionally ignored: the reference facade stores
    // them but its step() applies NO per-body damping — the only drag is the
    // Space global 0.015 (NapeWorld.hx:224). Applying both double-damps.
    const rot = (rotDeg * Math.PI) / 180; // degrees -> radians
    const h = this.nextHandle++;
    const b: Body = {
      handle: h,
      type: isStatic ? TYPE_STATIC : TYPE_DYNAMIC,
      posx: xPx,
      posy: yPx,
      rot,
      axisx: Math.sin(rot),
      axisy: Math.cos(rot),
      velx: 0,
      vely: 0,
      angvel: 0,
      forcex: 0,
      forcey: 0,
      torque: 0,
      cmass: 0,
      mass: 0,
      imass: 0,
      smass: 0,
      gravMass: 0,
      cinertia: 0,
      inertia: 0,
      iinertia: 0,
      sinertia: 0,
      localCOMx: 0,
      localCOMy: 0,
      worldCOMx: xPx,
      worldCOMy: yPx,
      allowMovement: true,
      allowRotation: true,
      pre_posx: xPx,
      pre_posy: yPx,
      pre_rot: rot,
      sweepTime: 0,
      sweepRadius: 0,
      sweep_angvel: 0,
      sweepFrozen: false,
      waket: 0,
      sleeping: false,
      shapes: [],
      userData: {},
    };
    this.bodies.set(h, b);
    return h;
  }

  addCircle(
    h: number,
    posX: number,
    posY: number,
    radius: number,
    density: number,
    friction: number,
    rolling: number,
    elasticity: number,
    colCat: number,
    colMask: number,
    isSensor: boolean,
  ): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    b.shapes.push({
      kind: 'circle',
      localx: posX,
      localy: posY,
      radius,
      density: density / 1000, // Material stores density/1000 (Material.as:51)
      friction,
      rolling,
      elasticity,
      area: 0,
      inertia: 0,
      localCOMx: posX,
      localCOMy: posY,
      sweepCoef: 0,
      sweepRadius: 0,
      ...makeFilter(colCat, colMask, isSensor),
      origColMask: isSensor ? 0 : colMask,
      origSenMask: isSensor ? colMask : 0,
      sid: this.nextShapeId++,
    });
  }

  // A single CONVEX polygon (decomposition is kept out of the bit-exact loop —
  // feed already-convex pieces). vertsFlat is [x0,y0,x1,y1,…] in body-local space.
  addPolygon(
    h: number,
    vertsFlat: number[],
    density: number,
    friction: number,
    rolling: number,
    elasticity: number,
    colCat: number,
    colMask: number,
    isSensor: boolean,
  ): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    b.shapes.push({
      kind: 'polygon',
      verts: vertsFlat.slice(),
      density: density / 1000,
      friction,
      rolling,
      elasticity,
      area: 0,
      inertia: 0,
      localCOMx: 0,
      localCOMy: 0,
      sweepCoef: 0,
      sweepRadius: 0,
      ...makeFilter(colCat, colMask, isSensor),
      origColMask: isSensor ? 0 : colMask,
      origSenMask: isSensor ? colMask : 0,
      sid: this.nextShapeId++,
    });
  }

  finalizeBody(h: number, _bullet: boolean): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    const hasShapes = b.shapes.length > 0;
    if (b.type === TYPE_DYNAMIC) {
      if (!hasShapes) {
        b.allowMovement = false;
        b.allowRotation = false;
      } else {
        this.validateMassProps(b); // mass/inertia/localCOM about the placement ORIGIN.
        // NO align: real Nape (and the live haxe game/shim) never call body.align(), so
        // position stays at the registration origin and rotation integrates about worldCOM.
        // All the offset-COM machinery (gravity-torque/arms/inertia about the origin) is
        // already faithful (copied from ZPP_Space/ZPP_Body); it was just dormant because
        // align() zeroed localCOM. align() was a vestige of the defunct Box2D-parity
        // NapeWorld.hx (recenters origin on COM) — it made getX/getY report the COM, which
        // broke offset-shape characters (level-7 opponent_patrol turn-around). Verified vs
        // the shipped SWF: an offset bar placed at y=416 reports 416, not the COM 376 (p0om).
        if (b.mass === 0) b.mass = 1; // Box2D-parity fallback (NapeWorld.hx:203)
        if (b.inertia === 0) b.allowRotation = false;
      }
    }
    // [M4-CCD] swept extent per shape + body max (ZPP_*.__validate_sweepRadius)
    let bodySweep = 0;
    for (const s of b.shapes) {
      if (s.kind === 'circle') {
        s.sweepCoef = Math.sqrt(s.localCOMx * s.localCOMx + s.localCOMy * s.localCOMy);
        s.sweepRadius = s.sweepCoef + s.radius;
      } else {
        // polygon: sweepCoef = max |vertex − COM| (the farthest vertex); radius 0
        let m = 0;
        for (let i = 0; i < s.verts.length; i += 2) {
          const dx = s.verts[i] - s.localCOMx;
          const dy = s.verts[i + 1] - s.localCOMy;
          const d = Math.sqrt(dx * dx + dy * dy);
          if (d > m) m = d;
        }
        s.sweepCoef = m;
        s.sweepRadius = m;
      }
      if (s.sweepRadius > bodySweep) bodySweep = s.sweepRadius;
    }
    b.sweepRadius = bodySweep;
    // [E3] static bodies are permanently "sleeping" — an arbiter sleeps when BOTH
    // bodies do, so a dynamic body resting on static geometry can sleep. (Only STATIC:
    // a kinematic must integrate, so it is never frozen here — though none reaches
    // finalizeBody as kinematic today, the type flip happens later via setBodyType.)
    if (b.type === TYPE_STATIC) b.sleeping = true;
    this.live.push(b);
  }

  // NB: there is intentionally NO align() here. Nape's body.align() (recenter the
  // origin onto the COM) is opt-in and the original 2012 game never calls it (grep of
  // src/*.as: zero hits), so faithful bodies keep their placement origin and rotate about
  // worldCOM. An earlier port copied align() from the defunct Box2D-parity NapeWorld.hx
  // and ran it on every dynamic body — that shifted getX/getY onto the COM and broke
  // offset-shape characters. Removed; see finalizeBody / the p0om golden.

  // Per-shape localCOM + area + inertia (about the body origin), matching Nape's
  // operation order exactly. Polygon traversal visits vertices in Nape's order
  // (cur = v1, v2, …, v_{n-1}, v0) so the float sums are bit-identical.
  private validateShapeGeom(s: Shape): void {
    if (s.kind === 'circle') {
      // ZPP_Circle.as:72 (localCOM is the circle's fixed local centre)
      s.localCOMx = s.localx;
      s.localCOMy = s.localy;
      const r2 = s.radius * s.radius;
      s.area = r2 * Math.PI;
      s.inertia = r2 * 0.5 + (s.localCOMx * s.localCOMx + s.localCOMy * s.localCOMy);
      return;
    }
    const v = s.verts;
    const n = v.length / 2;
    // localCOM centroid (ZPP_Body.as:360 polygon path)
    let comx = 0;
    let comy = 0;
    let comA = 0;
    for (let k = 0; k < n; k++) {
      const cur = (k + 1) % n;
      const prev = (cur + n - 1) % n;
      const next = (cur + 1) % n;
      const cx = v[2 * cur];
      const cy = v[2 * cur + 1];
      const py = v[2 * prev + 1];
      const nx = v[2 * next];
      const ny = v[2 * next + 1];
      comA += cx * (ny - py);
      const cf = ny * cx - nx * cy;
      comx += (cx + nx) * cf;
      comy += (cy + ny) * cf;
    }
    const f = 1 / (3 * comA);
    s.localCOMx = comx * f;
    s.localCOMy = comy * f;
    // area + inertia (ZPP_Polygon.as:1198)
    let area = 0;
    let l1 = 0;
    let l2 = 0;
    for (let k = 0; k < n; k++) {
      const cur = (k + 1) % n;
      const prev = (cur + n - 1) % n;
      const next = (cur + 1) % n;
      const cx = v[2 * cur];
      const cy = v[2 * cur + 1];
      const px = v[2 * prev];
      const py = v[2 * prev + 1];
      const ny = v[2 * next + 1];
      const cross = cy * px - cx * py;
      const s8 = cx * cx + cy * cy + (cx * px + cy * py) + (px * px + py * py);
      l1 += cross * s8;
      l2 += cross;
      area += cx * (ny - py);
    }
    s.inertia = l1 / (6 * l2);
    area *= 0.5;
    if (area < 0) area = -area;
    s.area = area;
  }

  // validate_localCOM + validate_mass + validate_inertia + validate_gravMass,
  // fused into the single pass Nape ends up performing
  // (ZPP_Body.as:360, 321, 481, 537).
  private validateMassProps(b: Body): void {
    let tempx = 0;
    let tempy = 0;
    let msum = 0.0;
    for (const s of b.shapes) {
      this.validateShapeGeom(s); // sets s.localCOM, s.area, s.inertia (about body origin)
      const t3 = s.area * s.density;
      tempx += s.localCOMx * t3;
      tempy += s.localCOMy * t3;
      msum += s.area * s.density;
    }
    if (msum !== 0) {
      const t4 = 1.0 / msum; // ZPP_Body.as:454
      b.localCOMx = tempx * t4;
      b.localCOMy = tempy * t4;
    }
    // cmass via the localCOM path (ZPP_Body.as:466)
    b.cmass = msum;
    if (b.type === TYPE_DYNAMIC) {
      b.mass = b.cmass;
      b.imass = b.smass = 1.0 / b.mass;
    } else {
      b.mass = STATIC_MASS;
      b.imass = b.smass = 0.0;
    }
    // validate_inertia (ZPP_Body.as:481)
    let cinertia = 0;
    for (const s of b.shapes) cinertia += s.inertia * s.area * s.density;
    b.cinertia = cinertia;
    if (b.type === TYPE_DYNAMIC) {
      b.inertia = b.cinertia;
      b.sinertia = b.iinertia = 1.0 / b.inertia;
    } else {
      b.inertia = STATIC_MASS;
      b.sinertia = b.iinertia = 0;
    }
    // validate_gravMass (ZPP_Body.as:537): gravMassMode DEFAULT -> gravMass = cmass
    b.gravMass = b.cmass;
  }

  destroyBody(h: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    const i = this.live.indexOf(b);
    if (i >= 0) this.live.splice(i, 1);
    // [facade] drop arbiters/constraints/partner edges referencing this body so a
    // level reload doesn't solve against a stale handle. Removing a body WAKES the
    // bodies it was interacting with (Nape `removed_shape` → `body.wake()`,
    // ZPP_Space.as:2353/2388) — otherwise a dynamic body asleep on a removed support
    // (the sand-block mechanic: ball resting on a destroyed block) stays frozen in
    // mid-air. wakeBody re-activates the dynamic partner so doForests re-evaluates it.
    for (const [k, arb] of this.arbiters) {
      if (arb.b1 === b || arb.b2 === b) {
        this.wakeBody(arb.b1 === b ? arb.b2 : arb.b1);
        this.arbiters.delete(k);
      }
    }
    this.constraints = this.constraints.filter((c) => {
      if (c.b1 === b || c.b2 === b) {
        this.wakeBody(c.b1 === b ? c.b2 : c.b1);
        return false;
      }
      return true;
    });
    this.jointPartners.delete(h);
    this.bodies.delete(h);
  }

  // --- step ---------------------------------------------------------------
  // Full Space.step pipeline (ZPP_Space.as:1579). The order is load-bearing:
  // validate → narrowphase → prestep → updateVel → warmStart → iterateVel →
  // updatePos → iteratePos. With no contacts this reduces to updateVel/updatePos
  // (the M0–M1 free-fall path); contacts add the sequential-impulse solver.
  step(dt: number, velIters: number, posIters: number): void {
    this.stamp++;
    this.validateWorldCOM();
    this.narrowphase();
    this.doForests(dt);
    this.prestep(dt);
    this.updateVel(dt);
    this.warmStart();
    this.iterateVel(velIters);
    this.updatePos(dt);
    this.continuousCollisions(dt);
    this.iteratePos(posIters);
    this.collectEvents(); // [facade] buffer BEGIN contact/sensor/impact events
  }

  // [E3] doForests (ZPP_Space.as:9472) — group dynamic bodies into islands
  // (connected by dynamic-dynamic arbiters/constraints), then sleep an island once
  // EVERY member has been atRest for 60 stamps: zero its bodies' velocity + freeze.
  // Awake islands sync each member's waket to the island max (so a body that briefly
  // moved keeps the whole island awake). Runs after narrowphase, before the solve.
  private doForests(dt: number): void {
    const dyn: Body[] = [];
    for (const b of this.live) if (b.type === TYPE_DYNAMIC) dyn.push(b);
    if (dyn.length === 0) return;
    // union-find over dynamic bodies (the island = connected component)
    const parent = new Map<Body, Body>();
    for (const b of dyn) parent.set(b, b);
    const find = (b: Body): Body => {
      let r = b;
      while (parent.get(r) !== r) r = parent.get(r)!;
      let x = b;
      while (parent.get(x) !== r) { const nx = parent.get(x)!; parent.set(x, r); x = nx; }
      return r;
    };
    const union = (a: Body, b: Body): void => {
      const ra = find(a); const rb = find(b);
      if (ra !== rb) parent.set(ra, rb);
    };
    for (const arb of this.arbiters.values()) {
      if (arb.stamp !== this.stamp) continue;
      // use a CONTACT this step (not the prestep `active` flag, which is set after
      // doForests) so a FRESH contact onto a sleeping body links them → wakes it.
      let hasContact = false;
      for (const c of arb.contacts) if (c.stamp === this.stamp) { hasContact = true; break; }
      if (!hasContact) continue;
      if (arb.b1.type === TYPE_DYNAMIC && arb.b2.type === TYPE_DYNAMIC) union(arb.b1, arb.b2);
    }
    for (const c of this.constraints) {
      if (c.b1.type === TYPE_DYNAMIC && c.b2.type === TYPE_DYNAMIC) union(c.b1, c.b2);
    }
    // per-body atRest (updates waket as a side effect), then group + decide
    const atRest = new Map<Body, boolean>();
    for (const b of dyn) atRest.set(b, this.bodyAtRest(b, dt));
    const islands = new Map<Body, Body[]>();
    for (const b of dyn) {
      const r = find(b);
      let g = islands.get(r);
      if (g == null) { g = []; islands.set(r, g); }
      g.push(b);
    }
    for (const group of islands.values()) {
      let sleep = true;
      let maxWaket = -Infinity;
      for (const b of group) {
        if (!atRest.get(b)) sleep = false;
        if (b.waket > maxWaket) maxWaket = b.waket;
      }
      if (sleep) {
        for (const b of group) { b.velx = 0; b.vely = 0; b.angvel = 0; b.sleeping = true; }
      } else {
        for (const b of group) { b.waket = maxWaket; b.sleeping = false; }
      }
    }
  }

  // [E3] ZPP_Body.atRest (1600): update waket if the body moved this frame (any of
  // the 4 thresholds — linear/displacement/angular/rotation), then return whether it
  // has stayed at rest for 60 consecutive stamps. aabb extent ≈ 2·sweepRadius (the
  // angular terms vanish for non-rotating bodies, so this is exact where it matters).
  private bodyAtRest(b: Body, dt: number): boolean {
    let rest: boolean;
    if (b.velx * b.velx + b.vely * b.vely > 0.2) rest = false;
    else {
      const dx = b.posx - b.pre_posx;
      const dy = b.posy - b.pre_posy;
      if (dx * dx + dy * dy > 0.05 * dt * dt) rest = false;
      else {
        const ext = 2 * b.sweepRadius;
        const diag2 = ext * ext + ext * ext;
        if (4 * b.angvel * b.angvel * diag2 > 0.4) rest = false;
        else {
          const dr = b.rot - b.pre_rot;
          rest = !(dr * dr * diag2 > 0.4 * dt * dt);
        }
      }
    }
    if (!rest) b.waket = this.stamp;
    return b.waket + 60 < this.stamp;
  }

  // validate_worldCOM (ZPP_Body.as:298)
  private validateWorldCOM(): void {
    for (const cur of this.live) {
      cur.axisx = Math.sin(cur.rot);
      cur.axisy = Math.cos(cur.rot);
      cur.worldCOMx = cur.posx + (cur.axisy * cur.localCOMx - cur.axisx * cur.localCOMy);
      cur.worldCOMy = cur.posy + (cur.localCOMx * cur.axisx + cur.localCOMy * cur.axisy);
    }
  }

  // Space.updateVel (ZPP_Space.as:1312) — the ORIGINAL force-based drag form:
  // drag enters as a force (−drag·mass·vel) folded into the accumulated force,
  // then the whole force is scaled by dt·imass. (nape.js uses a different,
  // multiplicative form; we match the original.)
  private updateVel(dt: number): void {
    for (const cur of this.live) {
      if (cur.sleeping) continue; // [E3] frozen
      let fx = cur.forcex + this.gravityx * cur.gravMass;
      let fy = cur.forcey + this.gravityy * cur.gravMass;
      const d = -this.global_lin_drag * cur.mass;
      fx += cur.velx * d;
      fy += cur.vely * d;
      if (cur.smass !== 0.0) {
        const time = dt * cur.imass;
        cur.velx += fx * time;
        cur.vely += fy * time;
      }
      if (cur.sinertia !== 0.0) {
        const dpx = cur.worldCOMx - cur.posx;
        const dpy = cur.worldCOMy - cur.posy;
        let torque = cur.torque + (this.gravityy * dpx - this.gravityx * dpy) * cur.gravMass;
        torque = torque - cur.angvel * this.global_ang_drag * cur.inertia;
        cur.angvel += torque * dt * cur.iinertia;
      }
    }
  }

  // Space.updatePos (ZPP_Space.as:1353) — rotation advances by dr = angvel·dt
  // directly (the original; nape.js clamps via angvel % MAX_VEL instead). The
  // CCD AABB sync that follows in the source never moves the body, so the
  // position result is the simple integral below.
  private updatePos(dt: number): void {
    for (const cur of this.live) {
      if (cur.sleeping) continue; // [E3] frozen — keep pre_pos/pos as-is
      cur.pre_posx = cur.posx;
      cur.pre_posy = cur.posy;
      cur.pre_rot = cur.rot;
      let t = dt;
      cur.posx += cur.velx * t;
      cur.posy += cur.vely * t;
      if (cur.angvel !== 0) {
        t = cur.angvel * dt;
        cur.rot += t;
        if (t * t > 0.0001) {
          cur.axisx = Math.sin(cur.rot);
          cur.axisy = Math.cos(cur.rot);
        } else {
          const d2 = t * t;
          const p = 1 - 0.5 * d2;
          const m = 1 - (d2 * d2) / 8;
          const nx = (p * cur.axisx + t * cur.axisy) * m;
          cur.axisy = (p * cur.axisy - t * cur.axisx) * m;
          cur.axisx = nx;
        }
      }
      cur.sweepTime = dt;
      // [M4-CCD] participation: a body sweeps if it moved > 5% of its sweepRadius
      // (or rotated past the angular threshold). Static bodies never sweep.
      // (ZPP_Space.as:1399) — the broadphase AABB sync is implicit in our naive pairing.
      if (cur.type !== TYPE_DYNAMIC) {
        cur.sweepFrozen = true;
      } else {
        const sr = 0.05 * cur.sweepRadius;
        const fast =
          (cur.velx * cur.velx + cur.vely * cur.vely) * dt * dt > sr * sr ||
          cur.angvel * cur.angvel * dt * dt > 0.005 * 0.005;
        cur.sweepFrozen = !fast;
      }
      cur.sweep_angvel = cur.angvel % ((2 * Math.PI) / dt);
    }
  }

  // --- readouts (match the NapeWorld facade getters) ----------------------
  getX(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.posx;
  }
  getY(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.posy;
  }
  getRot(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : (b.rot * 180) / Math.PI;
  }
  getRotRad(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.rot;
  }
  getVX(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.velx;
  }
  getVY(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.vely;
  }
  getAngVel(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.angvel;
  }
  getMass(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.mass;
  }
  isDynamic(h: number): boolean {
    const b = this.bodies.get(h);
    return b == null ? false : b.type === TYPE_DYNAMIC;
  }
  getInertia(h: number): number {
    const b = this.bodies.get(h);
    return b == null ? 0 : b.inertia;
  }

  // --- body ops [M1] ------------------------------------------------------
  // Body.velocity setter (Body.as:565) → vel_invalidate (ZPP_Body.as:291) which
  // assigns velx/vely then calls invalidate_wake() unconditionally → wakes a
  // sleeping DYNAMIC body so the new velocity actually integrates.
  setVel(h: number, vx: number, vy: number): void {
    const b = this.bodies.get(h);
    if (b != null) {
      b.velx = vx;
      b.vely = vy;
      this.wakeBody(b);
    }
  }
  // Body.angularVel setter (Body.as:1229): only assigns + invalidate_wake()
  // when the value actually changes (`if(angvel != param1)`).
  setAngVel(h: number, w: number): void {
    const b = this.bodies.get(h);
    if (b != null && b.angvel !== w) {
      b.angvel = w;
      this.wakeBody(b);
    }
  }
  // Body.applyImpulse, central case (Body.as:2406): vel += impulse · imass, then
  // invalidate_wake() guarded on `type == DYNAMIC` (Body.as:2467) — wakeBody's
  // own DYNAMIC guard reproduces that.
  applyImpulse(h: number, jx: number, jy: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    const imass = b.imass;
    b.velx = b.velx + jx * imass;
    b.vely = b.vely + jy * imass;
    this.wakeBody(b);
  }

  // [M5] PivotJoint: constrain local anchor (a1) on body hA to coincide with
  // local anchor (a2) on body hB. Mirrors `new PivotJoint(b1, b2, a1, a2)`.
  addPivotJoint(hA: number, hB: number, a1x: number, a1y: number, a2x: number, a2y: number): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null) return;
    this.constraints.push({
      kind: 'pivot',
      b1, b2,
      a1localx: a1x, a1localy: a1y, a2localx: a2x, a2localy: a2y,
      a1relx: 0, a1rely: 0, a2relx: 0, a2rely: 0,
      kMassa: 0, kMassb: 0, kMassc: 0,
      jAccx: 0, jAccy: 0,
      biasx: 0, biasy: 0, gamma: 0, jMax: 0,
      stiff: true, pre_dt: -1,
    });
  }

  // [M5] WeldJoint: rigidly fix body hB relative to body hA — anchors a1/a2
  // coincide AND (hB.rot − hA.rot) is locked to `phase` (default the current
  // relative rotation). Mirrors `new WeldJoint(b1, b2, a1, a2)`.
  addWeldJoint(hA: number, hB: number, a1x: number, a1y: number, a2x: number, a2y: number, phase = 0): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null) return;
    this.constraints.push({
      kind: 'weld',
      b1, b2,
      a1localx: a1x, a1localy: a1y, a2localx: a2x, a2localy: a2y,
      phase,
      a1relx: 0, a1rely: 0, a2relx: 0, a2rely: 0,
      kMassa: 0, kMassb: 0, kMassc: 0, kMassd: 0, kMasse: 0, kMassf: 0,
      jAccx: 0, jAccy: 0, jAccz: 0,
      biasx: 0, biasy: 0, biasz: 0, gamma: 0, jMax: 0,
      stiff: true, pre_dt: -1,
    });
  }

  // [M5] DistanceJoint: keep the distance between anchor a1 (on hA) and anchor a2
  // (on hB) within [jointMin, jointMax]. Mirrors `new DistanceJoint(b1,b2,a1,a2,min,max)`.
  addDistanceJoint(
    hA: number, hB: number,
    a1x: number, a1y: number, a2x: number, a2y: number,
    jointMin: number, jointMax: number,
  ): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null) return;
    this.constraints.push({
      kind: 'distance',
      b1, b2,
      a1localx: a1x, a1localy: a1y, a2localx: a2x, a2localy: a2y,
      jointMin, jointMax, equal: false, slack: false,
      a1relx: 0, a1rely: 0, a2relx: 0, a2rely: 0,
      nx: 0, ny: 0, cx1: 0, cx2: 0,
      kMass: 0, jAcc: 0, bias: 0, gamma: 0, jMax: 0,
      stiff: true, pre_dt: -1,
    });
  }

  // [M5] AngleJoint: keep (ratio·hB.rot − hA.rot) within [jointMin, jointMax].
  // Mirrors `new AngleJoint(b1, b2, jointMin, jointMax)` (ratio defaults to 1).
  addAngleJoint(hA: number, hB: number, jointMin: number, jointMax: number, ratio = 1): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null) return;
    this.constraints.push({
      kind: 'angle',
      b1, b2,
      jointMin, jointMax, ratio, equal: false, slack: false, scale: 0,
      kMass: 0, jAcc: 0, bias: 0, gamma: 0, jMax: 0,
      stiff: true, pre_dt: -1,
    });
  }

  // [M5] MotorJoint: drive (ratio·hB.angvel − hA.angvel) toward `rate`.
  // Mirrors `new MotorJoint(b1, b2, rate, ratio)`.
  addMotorJoint(hA: number, hB: number, rate = 0, ratio = 1): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null) return;
    this.constraints.push({
      kind: 'motor',
      b1, b2, rate, ratio,
      kMass: 0, jAcc: 0, jMax: 0, pre_dt: -1,
    });
  }

  // ======================================================================== //
  //  Facade surface — the NapeNative methods the game calls through          //
  //  nape-world.ts (window.NapeWorld). Pure plumbing over the solvers above;  //
  //  NapeWorld.hx is the reference for each. See FACADE-SPEC.md.             //
  // ======================================================================== //

  // static world body @ handle 0 — joints attach to "the world" (space.world).
  // Never in `live`, so it's inert in narrowphase/step/sleep; imass/iinertia 0.
  private makeWorldBody(): Body {
    return {
      handle: 0, type: TYPE_STATIC,
      posx: 0, posy: 0, rot: 0, axisx: 0, axisy: 1,
      velx: 0, vely: 0, angvel: 0, forcex: 0, forcey: 0, torque: 0,
      cmass: 0, mass: STATIC_MASS, imass: 0, smass: 0, gravMass: 0,
      cinertia: 0, inertia: STATIC_MASS, iinertia: 0, sinertia: 0,
      localCOMx: 0, localCOMy: 0, worldCOMx: 0, worldCOMy: 0,
      allowMovement: false, allowRotation: false,
      pre_posx: 0, pre_posy: 0, pre_rot: 0, sweepTime: 0,
      sweepRadius: 0, sweep_angvel: 0, sweepFrozen: true,
      waket: 0, sleeping: true, shapes: [], userData: {},
    };
  }

  // world point P -> body-local anchor: Rᵀ·(P − pos), axis = (sin rot, cos rot).
  // Inverse of the solver's a1rel = R·a1local (pivotPreStep). pos/axis are the
  // post-finalize (COM-centred) values, matching Nape's worldPointToLocal.
  private worldPointToLocal(b: Body, px: number, py: number): { x: number; y: number } {
    const dx = px - b.posx;
    const dy = py - b.posy;
    return { x: b.axisy * dx + b.axisx * dy, y: -b.axisx * dx + b.axisy * dy };
  }

  // record a joint connection so a moving body can wake its sleeping partners.
  private addPartner(hA: number, hB: number): void {
    if (hA === 0 || hB === 0) return;
    let la = this.jointPartners.get(hA);
    if (la == null) { la = []; this.jointPartners.set(hA, la); }
    la.push(hB);
    let lb = this.jointPartners.get(hB);
    if (lb == null) { lb = []; this.jointPartners.set(hB, lb); }
    lb.push(hA);
  }

  // suppress collision between two jointed bodies (Nape joint.ignore, collide_joined=false).
  private ignorePair(hA: number, hB: number): void {
    if (hA === 0 || hB === 0) return;
    this.ignoredPairs.add(pairKey(hA, hB));
  }

  // --- level joints (NapeWorld.hx jointRev/jointWeld/jointDist) -------------
  jointRev(hA: number, hB: number, ax: number, ay: number, enableMotor: boolean,
    motorSpeed: number, _maxTorque: number, enableLimit: boolean, lowerRad: number, upperRad: number): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null || b1 === b2) return;
    this.addPartner(hA, hB);
    this.ignorePair(hA, hB); // collide_joined=false (universal in the shipped game)
    const a1 = this.worldPointToLocal(b1, ax, ay);
    const a2 = this.worldPointToLocal(b2, ax, ay);
    this.addPivotJoint(hA, hB, a1.x, a1.y, a2.x, a2.y);
    // ALL 19 shipped rev joints have motor+limit disabled (dead branches kept
    // faithful). maxTorque is NOT honoured (motor jMax is ∞) — moot, since unused.
    if (enableMotor) this.addMotorJoint(hA, hB, motorSpeed, 1);
    if (enableLimit) this.addAngleJoint(hA, hB, lowerRad, upperRad, 1);
  }

  jointWeld(hA: number, hB: number, _soft: boolean, _freq: number): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null || b1 === b2) return;
    if (b1.type !== TYPE_DYNAMIC && b2.type !== TYPE_DYNAMIC) return; // weld of two statics = no-op
    this.addPartner(hA, hB);
    this.ignorePair(hA, hB); // collide_joined=false (universal in the shipped game)
    const phase = b2.rot - b1.rot;
    const a1 = this.worldPointToLocal(b1, b2.posx, b2.posy); // anchor = bodyB origin; a2 == (0,0)
    this.addWeldJoint(hA, hB, a1.x, a1.y, 0, 0, phase);
    // soft/freq skipped — 0 soft joints in any level.
  }

  jointDist(hA: number, hB: number, x0: number, y0: number, x1: number, y1: number,
    distLimit: number, _soft: boolean, _freq: number): void {
    const b1 = this.bodies.get(hA);
    const b2 = this.bodies.get(hB);
    if (b1 == null || b2 == null || b1 === b2) return;
    this.addPartner(hA, hB);
    this.ignorePair(hA, hB); // collide_joined=false (universal in the shipped game)
    const dx = x1 - x0;
    const dy = y1 - y0;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const minLen = Math.max(dist - distLimit, 0);
    const maxLen = dist + distLimit;
    const a1 = this.worldPointToLocal(b1, x0, y0);
    const a2 = this.worldPointToLocal(b2, x1, y1);
    this.addDistanceJoint(hA, hB, a1.x, a1.y, a2.x, a2.y, minLen, maxLen);
    // soft/freq skipped.
  }

  // --- contact/sensor/impact events (NapeWorld.hx onCollision/onSensor) -----
  // Run once at the end of step(); buffers BEGIN + ONGOING events for take*(). Reads
  // solver output only — no state mutation.
  private collectEvents(): void {
    // collisions: an arbiter active this step (stamp == this.stamp) that was NOT
    // active last step is a BEGIN. Impulse = Σ contacts' accumulated jnAcc.
    // ONGOING fires for EVERY active arbiter each step (including the BEGIN step) as
    // long as it is AWAKE — i.e. NOT both bodies asleep (static counts as asleep).
    // Nape skips ONGOING dispatch when all of an interaction's arbiters sleep
    // (ZPP_Space.as:1903-1919); verified vs the shipped SWF (p0og): BEGIN@15, ONGOING
    // 15..76 contiguous, body sleeps @77 → ONGOING stops exactly at the sleep step.
    const nowCol = new Set<string>();
    for (const arb of this.arbiters.values()) {
      if (arb.stamp !== this.stamp) continue;
      nowCol.add(arb.key);
      const ha = arb.b1.handle;
      const hb = arb.b2.handle;
      if (!(arb.b1.sleeping && arb.b2.sleeping)) this.ongoingBuf.push(ha, hb, 0);
      if (this.activeColPairs.has(arb.key)) continue;
      this.contactsBuf.push(ha, hb, 0);
      const jn = (arb.c1 ? arb.c1.jnAcc : 0) + (arb.c2 ? arb.c2.jnAcc : 0);
      this.impactsBuf.push(ha, hb, Math.abs(jn), arb.nx, arb.ny);
    }
    this.activeColPairs = nowCol;
    // sensors: the solver makes no arbiter for sensor pairs (shouldCollide drops
    // them), so test overlap here over every shape pair whose sensor filters match.
    const nowSen = new Set<string>();
    const arr = this.live;
    for (let i = 0; i < arr.length; i++) {
      for (let j = i + 1; j < arr.length; j++) {
        const A = arr[i];
        const B = arr[j];
        if (A.type !== TYPE_DYNAMIC && B.type !== TYPE_DYNAMIC) continue;
        if (this.ignoredPairs.size > 0 && this.ignoredPairs.has(pairKey(A.handle, B.handle))) continue; // joint collide_joined=false
        for (const sa of A.shapes) {
          for (const sb of B.shapes) {
            if ((sa.senGroup & sb.senMask) === 0 || (sb.senGroup & sa.senMask) === 0) continue;
            if (this.distanceQuery(A, sa, B, sb).d > 0) continue; // not overlapping
            const key = sa.sid < sb.sid ? `${sa.sid}-${sb.sid}` : `${sb.sid}-${sa.sid}`;
            nowSen.add(key);
            // ONGOING sensor overlap each awake step (same sleep gate as solids: a sensor
            // pair's arbiter sleeps when both bodies do, and a static sensor is permanently
            // asleep → gated by the dynamic body staying awake, e.g. the wind nudge).
            if (!(A.sleeping && B.sleeping)) this.ongoingBuf.push(A.handle, B.handle, 1);
            if (this.activeSenPairs.has(key)) continue;
            this.contactsBuf.push(A.handle, B.handle, 1);
          }
        }
      }
    }
    this.activeSenPairs = nowSen;
  }

  takeContacts(): number[] {
    const c = this.contactsBuf;
    this.contactsBuf = [];
    return c;
  }

  // ONGOING contact/sensor pairs persisting THIS step while awake (drives the game's
  // `onHitPersistFunction`: level-8 switch_weight timer reset, wind `OnHit_Wind`).
  // Same `[hA,hB,sensorFlag, ...]` shape as takeContacts; a pair appears every step from
  // its BEGIN until it separates or both its bodies sleep (the game keeps a resting body
  // awake with a per-step velocity nudge so ONGOING keeps firing).
  takeOngoing(): number[] {
    const c = this.ongoingBuf;
    this.ongoingBuf = [];
    return c;
  }

  takeImpacts(): number[] {
    const c = this.impactsBuf;
    this.impactsBuf = [];
    return c;
  }

  // Faithful Nape `Body.normalImpulse(other)` — the crate-break input
  // (GameObj.OnHit_Breakable_Pieces: `l = breakable.normalImpulse(ball).length / mass`).
  // Returns the full Vec3 [x, y, z] about `refHandle`, summed over the active arbiter's
  // contacts, EXACTLY as nape.dynamics.Contact.normalImpulse (Contact.as:82):
  //   ref == b1: ( -nx·jn, -ny·jn, -(ny·r1x - nx·r1y)·jn )
  //   ref == b2: (  nx·jn,  ny·jn,  (ny·r2x - nx·r2y)·jn )
  // The z (angular) term — jn × the contact's moment arm about the ref body's centre,
  // using the PRESTEP arms r1/r2 — is what `takeImpacts` (scalar jn only) dropped, making
  // breakables ~3.7× too tough: a gravity-lowered ball strikes the crate face well below
  // centre, so |Vec3| ≫ |jn| (the lever arm dominates). Bit-exact vs the shipped SWF (p0br).
  normalImpulse(refHandle: number, otherHandle: number): [number, number, number] {
    let x = 0;
    let y = 0;
    let z = 0;
    for (const arb of this.arbiters.values()) {
      if (arb.stamp !== this.stamp) continue; // impulse from the latest step only
      const h1 = arb.b1.handle;
      const h2 = arb.b2.handle;
      if (!((h1 === refHandle && h2 === otherHandle) || (h2 === refHandle && h1 === otherHandle))) continue;
      const nx = arb.nx;
      const ny = arb.ny;
      const refIsB1 = h1 === refHandle;
      for (const c of [arb.c1, arb.c2]) {
        if (c == null) continue;
        const jn = c.jnAcc;
        if (refIsB1) {
          x += -nx * jn;
          y += -ny * jn;
          z += -(ny * c.r1x - nx * c.r1y) * jn;
        } else {
          x += nx * jn;
          y += ny * jn;
          z += (ny * c.r2x - nx * c.r2y) * jn;
        }
      }
    }
    return [x, y, z];
  }

  // --- queries (read-only) --------------------------------------------------
  bodyContains(h: number, xPx: number, yPx: number): boolean {
    const b = this.bodies.get(h);
    if (b == null) return false;
    for (const s of b.shapes) {
      if (s.kind === 'circle') {
        const wc = this.shapeWorldCOM(b, s);
        const dx = xPx - wc.x;
        const dy = yPx - wc.y;
        if (dx * dx + dy * dy <= s.radius * s.radius) return true;
      } else {
        // point in convex polygon: all edge cross-products share one sign.
        const l = this.worldPointToLocal(b, xPx, yPx);
        const v = s.verts;
        const n = v.length / 2;
        let inside = true;
        let sign = 0;
        for (let k = 0; k < n; k++) {
          const ax = v[2 * k];
          const ay = v[2 * k + 1];
          const k2 = (k + 1) % n;
          const cross = (v[2 * k2] - ax) * (l.y - ay) - (v[2 * k2 + 1] - ay) * (l.x - ax);
          if (cross !== 0) {
            const sg = cross > 0 ? 1 : -1;
            if (sign === 0) sign = sg;
            else if (sg !== sign) { inside = false; break; }
          }
        }
        if (inside) return true;
      }
    }
    return false;
  }

  bodyArea(h: number): number {
    const b = this.bodies.get(h);
    if (b == null) return 0;
    let a = 0;
    for (const s of b.shapes) a += s.area;
    return a;
  }

  // dynamic bodies currently in collision contact with body h (switch persist).
  touchingBodies(h: number): number[] {
    const out: number[] = [];
    const b = this.bodies.get(h);
    if (b == null) return out;
    for (const arb of this.arbiters.values()) {
      if (arb.stamp !== this.stamp) continue;
      let other: Body | null = null;
      if (arb.b1 === b) other = arb.b2;
      else if (arb.b2 === b) other = arb.b1;
      if (other != null && other.type === TYPE_DYNAMIC) out.push(other.handle);
    }
    return out;
  }

  // ray straight down from (x, fromY); nearest hit y (px) among shapes matching
  // the filter (rayGroup=rayMask=colCat, like NapeWorld.hx:348), else NaN.
  raycastDown(xPx: number, fromYPx: number, maxDist: number, colCat: number): number {
    let bestY = Infinity;
    const maxY = fromYPx + maxDist;
    for (const b of this.live) {
      for (const s of b.shapes) {
        if ((colCat & s.colMask) === 0 || (s.colGroup & colCat) === 0) continue;
        if (s.kind === 'circle') {
          const wc = this.shapeWorldCOM(b, s);
          const ddx = xPx - wc.x;
          if (Math.abs(ddx) > s.radius) continue;
          const y = wc.y - Math.sqrt(s.radius * s.radius - ddx * ddx); // upper intersection
          if (y >= fromYPx && y <= maxY && y < bestY) bestY = y;
        } else {
          const axisx = Math.sin(b.rot);
          const axisy = Math.cos(b.rot);
          const v = s.verts;
          const n = v.length / 2;
          for (let k = 0; k < n; k++) {
            const k2 = (k + 1) % n;
            const ex = b.posx + (axisy * v[2 * k] - axisx * v[2 * k + 1]);
            const ey = b.posy + (v[2 * k] * axisx + v[2 * k + 1] * axisy);
            const fx = b.posx + (axisy * v[2 * k2] - axisx * v[2 * k2 + 1]);
            const fy = b.posy + (v[2 * k2] * axisx + v[2 * k2 + 1] * axisy);
            if ((ex - xPx) * (fx - xPx) > 0) continue; // edge doesn't span x
            if (ex === fx) continue; // vertical edge — no single crossing
            const t = (xPx - ex) / (fx - ex);
            const y = ey + t * (fy - ey);
            if (y >= fromYPx && y <= maxY && y < bestY) bestY = y;
          }
        }
      }
    }
    return bestY === Infinity ? NaN : bestY;
  }

  // --- lifecycle ------------------------------------------------------------
  setTransform(h: number, xPx: number, yPx: number, rotDeg: number): void {
    const b = this.bodies.get(h);
    if (b == null || b.type === TYPE_STATIC) return; // Nape forbids moving a static body
    b.posx = xPx;
    b.posy = yPx;
    b.rot = (rotDeg * Math.PI) / 180;
    b.axisx = Math.sin(b.rot);
    b.axisy = Math.cos(b.rot);
    b.worldCOMx = b.posx + (b.axisy * b.localCOMx - b.axisx * b.localCOMy);
    b.worldCOMy = b.posy + (b.localCOMx * b.axisx + b.localCOMy * b.axisy);
    b.sleeping = false;
    b.waket = this.stamp;
  }

  setBodyType(h: number, type: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    // Facade type codes (nape-haxe4 BodyType): 0 = STATIC, 1 = DYNAMIC, 2 = KINEMATIC.
    const nt = type === 0 ? TYPE_STATIC : type === 2 ? TYPE_KINEMATIC : TYPE_DYNAMIC;
    if (b.type === nt) return;
    b.type = nt;
    if (nt === TYPE_DYNAMIC) {
      if (b.shapes.length > 0) {
        this.validateMassProps(b); // mass/inertia/localCOM about the origin — NO align,
        // matching finalizeBody and the KINEMATIC branch below (Nape never recenters).
        if (b.mass === 0) b.mass = 1;
        if (b.inertia === 0) b.allowRotation = false;
      } else {
        b.allowMovement = false;
        b.allowRotation = false;
      }
      b.sleeping = false;
      b.waket = this.stamp;
    } else if (nt === TYPE_KINEMATIC) {
      // KINEMATIC: infinite mass (imass/iinertia 0 → unaffected by impulses, like static)
      // and NO gravity (gated by smass/sinertia==0 in updateVel), but it MOVES — it
      // integrates position from its externally-set velocity (updatePos runs because it's
      // not sleeping) and carries riders via its velocity in the contact solver. Crucially
      // it is NOT aligned: Nape never recenters a kinematic, so its registration origin
      // (what the game renders) is preserved. validateMassProps sets localCOM + imass=0
      // WITHOUT moving the origin. The game drives velocity each frame (SetBodyXForm).
      this.validateMassProps(b);
      b.sleeping = false; // must integrate in updatePos / updateVel
      b.waket = this.stamp;
    } else {
      this.validateMassProps(b); // static → STATIC_MASS, imass/iinertia 0
      b.velx = b.vely = b.angvel = 0;
      b.sleeping = true;
    }
  }

  setAwake(h: number, awake: boolean): void {
    const b = this.bodies.get(h);
    if (b == null || !awake) return; // only the wake case is used (NapeWorld.hx:291)
    b.sleeping = false;
    b.waket = this.stamp;
  }

  wakeJointPartners(h: number): void {
    const list = this.jointPartners.get(h);
    if (list == null) return;
    for (const ph of list) {
      const b = this.bodies.get(ph);
      if (b != null && b.type === TYPE_DYNAMIC && b.sleeping) {
        b.sleeping = false;
        b.waket = this.stamp;
      }
    }
  }

  // --- collision toggles (restore/zero the stored masks) --------------------
  setBodyCollision(h: number, enabled: boolean): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) {
      if (s.isSensor) s.senMask = enabled ? s.origSenMask : 0;
      else s.colMask = enabled ? s.origColMask : 0;
    }
    this.dropStaleArbiters(b);
  }

  // [facade] Runtime collision-mask change (game `SetBodyCollisionMask`, e.g. level-19
  // switches making a `switchable_block` disappear at mask 0). Sets the collision mask on
  // every NON-sensor shape of body h, then re-evaluates already-touching pairs so the
  // change takes effect on the current contact set — any existing arbiter that no longer
  // `shouldCollide` is dropped and the dynamic body on the other side is WOKEN (a resting
  // ball is likely asleep and would otherwise sleep through the change and never fall).
  setBodyCollisionMask(h: number, mask: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) {
      if (!s.isSensor) s.colMask = mask;
    }
    this.dropStaleArbiters(b);
  }

  // [facade] Runtime PER-SHAPE collision-mask change — game `SetBodyShapeCollisionMask`
  // (`GameObj_Base.as:1739`: `body.shapes.at(i).filter.collisionMask = mask`). The level-11
  // keeper ducks by zeroing ONLY its upper-body shapes (2,3) so the ball clears the top
  // while the legs (0,1) stay solid; the body-wide setBodyCollisionMask would wrongly
  // disable every shape and the ball would pass straight through. Sets just shape
  // `shapeIdx`'s colMask, then drops that shape's now-non-colliding arbiter + wakes the
  // resting partner (a ball asleep on the disabled shape falls; bodies on other shapes are
  // untouched). `shapeIdx` is the engine `b.shapes` order (the shim maps to it).
  setShapeCollisionMask(h: number, shapeIdx: number, mask: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    const s = b.shapes[shapeIdx];
    if (s == null) return;
    s.colMask = mask;
    this.dropStaleArbiters(b);
  }

  // [facade] Runtime collision-GROUP change (symmetric to setBodyCollisionMask). The game
  // only changes the mask at runtime today (level-19 switches) — this covers a group change
  // too. Sets colGroup on every non-sensor shape, then drops now-non-colliding arbiters +
  // wakes the resting body, exactly like the mask path.
  setBodyCollisionGroup(h: number, group: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) {
      if (!s.isSensor) s.colGroup = group;
    }
    this.dropStaleArbiters(b);
  }

  // [facade] Runtime SENSOR-mask change (game `SetBodySensorMask`; the flying bird gates its
  // hit detection by toggling sensorMask 0↔8). Sets senMask on EVERY shape (matching the
  // game, which sets all shapes; harmless on non-sensors whose senGroup is 0). Sensors are
  // NOT in the solver — this only gates the sensor-overlap BEGIN events recomputed each step
  // in collectEvents — so no arbiter drop / wake is needed.
  setBodySensorMask(h: number, mask: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) s.senMask = mask;
  }

  // [facade] Runtime SENSOR-group change (symmetric; events only, no solver effect).
  setBodySensorGroup(h: number, group: number): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) s.senGroup = group;
  }

  // [facade] Runtime `shape.sensorEnabled` toggle: swap a shape between collider (in the
  // solver) and sensor (overlap events only), preserving its category/mask. Becoming a
  // sensor zeroes its collision group/mask, so dropStaleArbiters drops its live contacts +
  // wakes the other body (a resting ball falls through); becoming solid lets narrowphase
  // re-form contacts next step. NOTE: this preserves the *single* category the shape carries
  // — see the collider-XOR-sensor caveat flagged to the game session (a shape that must be
  // BOTH solid and sensable needs independent sensor filters, which the facade can't yet express).
  setBodySensorEnabled(h: number, sensor: boolean): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (const s of b.shapes) {
      const cat = s.isSensor ? s.senGroup : s.colGroup;
      const mask = s.isSensor ? s.senMask : s.colMask;
      Object.assign(s, makeFilter(cat, mask, sensor));
      s.origColMask = sensor ? 0 : mask;
      s.origSenMask = sensor ? mask : 0;
    }
    this.dropStaleArbiters(b);
  }

  // Drop every arbiter touching body b whose shape pair no longer collides under the
  // current filters, waking the dynamic side so it re-enters the solver (and falls).
  private dropStaleArbiters(b: Body): void {
    for (const [k, arb] of this.arbiters) {
      if (arb.b1 !== b && arb.b2 !== b) continue;
      if (!shouldCollide(arb.s1, arb.s2)) {
        this.arbiters.delete(k);
        this.wakeBody(arb.b1);
        this.wakeBody(arb.b2);
      }
    }
  }

  private wakeBody(b: Body): void {
    if (b.type !== TYPE_DYNAMIC) return; // static/kinematic: never wake (static is perma-asleep)
    // Nape non_inlined_wake refreshes waket on EVERY call (ZPP_Space.as:5347 sets waket
    // unconditionally, then really_wake only if it was sleeping). The unconditional refresh is
    // load-bearing: a tiny keep-awake nudge (velocity.y -= 1e-8, below bodyAtRest's 0.2 vel /
    // disp thresholds) must be able to PREVENT an awake body from sleeping, not just re-wake one
    // already asleep — otherwise the level-8 weight-switch block sleeps at frame 60, ONGOING
    // stops (gated to awake arbiters), the nudge (fired only on ONGOING) stops, and it sleeps
    // forever → switch counts down to red. setVel/setAngVel/applyImpulse route through here, so
    // a velocity-set counts as activity (Nape Body.velocity/angularVel setters → invalidate_wake).
    b.waket = this.stamp;
    b.sleeping = false;
  }

  // toggle only shapes whose top reaches above the threshold (keeper duck): the
  // tall idle shape toggles, the short crouch shape stays solid.
  setBodyCollisionAboveTop(h: number, topThresholdPx: number, enabled: boolean): void {
    const b = this.bodies.get(h);
    if (b == null) return;
    for (let i = 0; i < b.shapes.length; i++) {
      const s = b.shapes[i];
      const aabb = this.shapeAABB(h, i);
      const topPx = b.posy - aabb[1]; // px above the body origin
      if (topPx <= topThresholdPx) continue;
      if (s.isSensor) s.senMask = enabled ? s.origSenMask : 0;
      else s.colMask = enabled ? s.origColMask : 0;
    }
    // Same wake-on-filter-change rule as setBodyCollision / setBodyCollisionMask: when the
    // duck DISABLES a tall shape, drop its now-non-colliding arbiters and wake the resting
    // partner — otherwise a body asleep on the keeper's head stays frozen mid-air (the
    // destroyBody / sand-block class of bug). No-op on the re-enable case (shouldCollide
    // becomes true again, so nothing is dropped; narrowphase re-forms the contact next step).
    this.dropStaleArbiters(b);
  }

  // [M2] world-space AABB [minx,miny,maxx,maxy] of shape i. Circle: worldCOM ±
  // radius (ZPP_Shape.as:658); polygon: min/max of world-transformed verts
  // (ZPP_Shape.as:682). World transform: g = pos + (axisy·l.x − axisx·l.y,
  //  l.x·axisx + l.y·axisy), axis = (sin rot, cos rot).
  shapeAABB(h: number, i: number): [number, number, number, number] {
    const b = this.bodies.get(h);
    if (b == null) return [0, 0, 0, 0];
    const s = b.shapes[i];
    const axisx = Math.sin(b.rot);
    const axisy = Math.cos(b.rot);
    if (s.kind === 'circle') {
      const wcx = b.posx + (axisy * s.localCOMx - axisx * s.localCOMy);
      const wcy = b.posy + (s.localCOMx * axisx + s.localCOMy * axisy);
      return [wcx - s.radius, wcy - s.radius, wcx + s.radius, wcy + s.radius];
    }
    const v = s.verts;
    const n = v.length / 2;
    let minx = 0;
    let miny = 0;
    let maxx = 0;
    let maxy = 0;
    for (let k = 0; k < n; k++) {
      const gx = b.posx + (axisy * v[2 * k] - axisx * v[2 * k + 1]);
      const gy = b.posy + (v[2 * k] * axisx + v[2 * k + 1] * axisy);
      if (k === 0) {
        minx = maxx = gx;
        miny = maxy = gy;
      } else {
        if (gx < minx) minx = gx;
        if (gx > maxx) maxx = gx;
        if (gy < miny) miny = gy;
        if (gy > maxy) maxy = gy;
      }
    }
    return [minx, miny, maxx, maxy];
  }

  // [M3] circle-circle narrowphase manifold (ZPP_Collide.as:1088). Pass bodies in
  // the original's (body1, body2) order — the normal sign depends on it. Returns
  // the contact normal and penetration (= −contact.dist), or null if separate.
  circleCircleManifold(ha: number, hb: number): { nx: number; ny: number; penetration: number } | null {
    const a = this.bodies.get(ha);
    const b = this.bodies.get(hb);
    if (a == null || b == null) return null;
    const sa = a.shapes[0];
    const sb = b.shapes[0];
    if (sa.kind !== 'circle' || sb.kind !== 'circle') return null;
    const axA = Math.sin(a.rot);
    const ayA = Math.cos(a.rot);
    const axB = Math.sin(b.rot);
    const ayB = Math.cos(b.rot);
    const w1x = a.posx + (ayA * sa.localCOMx - axA * sa.localCOMy);
    const w1y = a.posy + (sa.localCOMx * axA + sa.localCOMy * ayA);
    const w2x = b.posx + (ayB * sb.localCOMx - axB * sb.localCOMy);
    const w2y = b.posy + (sb.localCOMx * axB + sb.localCOMy * ayB);
    const rsum = sa.radius + sb.radius;
    const dx = w2x - w1x;
    const dy = w2y - w1y;
    const d2 = dx * dx + dy * dy;
    if (d2 > rsum * rsum) return null;
    if (d2 < 1e-8 * 1e-8) return { nx: 1, ny: 0, penetration: rsum };
    const invDist = fastInvSqrt(d2);
    const dist = invDist < 1e-8 ? 1e100 : 1 / invDist;
    const nx = -dx * invDist;
    const ny = -dy * invDist;
    return { nx, ny, penetration: -(dist - rsum) };
  }

  // circle-vertex contact (ZPP_Collide.as:593, param1-first sign): normal points
  // from the polygon vertex to the circle centre, via fast-inv-sqrt.
  private circleVertexContact(vx: number, vy: number, wcx: number, wcy: number, r: number): { nx: number; ny: number; penetration: number } | null {
    const lx = vx - wcx;
    const ly = vy - wcy;
    const d2 = lx * lx + ly * ly;
    if (d2 > r * r) return null;
    if (d2 < 1e-8 * 1e-8) return { nx: 1, ny: 0, penetration: r };
    const invDist = fastInvSqrt(d2);
    const dist = invDist < 1e-8 ? 1e100 : 1 / invDist;
    const nx = -lx * invDist;
    const ny = -ly * invDist;
    return { nx, ny, penetration: -(dist - r) };
  }

  // [M3b] circle-polygon narrowphase (ZPP_Collide.as:502). Pass the circle body
  // then the polygon body (the original's param1=circle, param2=polygon order).
  // Edge normals are computed Nape's way (edge dir rotated 90°, normalized with
  // Math.sqrt). Returns the deepest-edge face contact or a vertex contact.
  circlePolyManifold(hc: number, hp: number): { nx: number; ny: number; penetration: number } | null {
    const c = this.bodies.get(hc);
    const p = this.bodies.get(hp);
    if (c == null || p == null) return null;
    const sc = c.shapes[0];
    const sp = p.shapes[0];
    if (sc.kind !== 'circle' || sp.kind !== 'polygon') return null;
    const axc = Math.sin(c.rot);
    const ayc = Math.cos(c.rot);
    const wcx = c.posx + (ayc * sc.localCOMx - axc * sc.localCOMy);
    const wcy = c.posy + (sc.localCOMx * axc + sc.localCOMy * ayc);
    const r = sc.radius;
    const axp = Math.sin(p.rot);
    const ayp = Math.cos(p.rot);
    const v = sp.verts;
    const n = v.length / 2;
    // world vertices
    const gvx: number[] = [];
    const gvy: number[] = [];
    for (let k = 0; k < n; k++) {
      gvx.push(p.posx + (ayp * v[2 * k] - axp * v[2 * k + 1]));
      gvy.push(p.posy + (v[2 * k] * axp + v[2 * k + 1] * ayp));
    }
    // deepest-penetrating edge (ZPP_Collide.as:502)
    let best = -1e100;
    let bestEdge = -1;
    let bgnx = 0;
    let bgny = 0;
    let collision = true;
    for (let i = 0; i < n; i++) {
      const a2 = 2 * i;
      const b2 = 2 * ((i + 1) % n);
      const ex = v[a2] - v[b2]; // edge dir = lp0 − lp1 (ZPP_Polygon.as:110)
      const ey = v[a2 + 1] - v[b2 + 1];
      const len = Math.sqrt(ex * ex + ey * ey);
      const inv = 1 / len;
      const exn = ex * inv;
      const eyn = ey * inv;
      const lnx = -eyn; // lnorm = edge dir rotated 90° (ZPP_Polygon.as:117)
      const lny = exn;
      const lproj = lnx * v[a2] + lny * v[a2 + 1];
      const gnx = ayp * lnx - axp * lny; // world normal (ZPP_Polygon.as:190)
      const gny = lnx * axp + lny * ayp;
      const gproj = p.posx * gnx + p.posy * gny + lproj;
      const sep = gnx * wcx + gny * wcy - gproj - r;
      if (sep > 0) {
        collision = false;
        break;
      }
      if (sep > best) {
        best = sep;
        bestEdge = i;
        bgnx = gnx;
        bgny = gny;
      }
    }
    if (!collision || bestEdge < 0) return null;
    // region test against the deepest edge's endpoints (ZPP_Collide.as:525)
    const gp0x = gvx[bestEdge];
    const gp0y = gvy[bestEdge];
    const e1 = (bestEdge + 1) % n;
    const gp1x = gvx[e1];
    const gp1y = gvy[e1];
    const t = wcy * bgnx - wcx * bgny;
    const tp0 = gp0y * bgnx - gp0x * bgny;
    const tp1 = gp1y * bgnx - gp1x * bgny;
    if (t <= tp0) return this.circleVertexContact(gp0x, gp0y, wcx, wcy, r);
    if (t >= tp1) return this.circleVertexContact(gp1x, gp1y, wcx, wcy, r);
    return { nx: bgnx, ny: bgny, penetration: -best }; // edge face (ZPP_Collide.as:1011)
  }

  // World vertices + edges (gnorm/gprojection/tangent projections) of a polygon,
  // matching Nape's edge build (ZPP_Polygon.as:103 lnorm via Math.sqrt, :190 gnorm).
  private polyWorldGeom(b: Body, s: PolygonShape): {
    gv: number[];
    edges: { gnx: number; gny: number; gproj: number; gp0x: number; gp0y: number; gp1x: number; gp1y: number; tp0: number; tp1: number; lnx: number; lny: number; lproj: number }[];
  } {
    // use the body's MAINTAINED axis (Nape rebuilds world geometry from axisx/axisy,
    // not sin(rot)). At discrete-narrowphase time validateWorldCOM already set axis =
    // (sin,cos)(rot); mid-step (CCD sweep) it's the Taylor-integrated value — using
    // the stored axis keeps the swept geometry bit-exact with the original.
    const ax = b.axisx;
    const ay = b.axisy;
    const v = s.verts;
    const n = v.length / 2;
    const gv: number[] = [];
    for (let k = 0; k < n; k++) {
      gv.push(b.posx + (ay * v[2 * k] - ax * v[2 * k + 1]));
      gv.push(b.posy + (v[2 * k] * ax + v[2 * k + 1] * ay));
    }
    const edges = [];
    for (let i = 0; i < n; i++) {
      const a2 = 2 * i;
      const b2 = 2 * ((i + 1) % n);
      const ex = v[a2] - v[b2];
      const ey = v[a2 + 1] - v[b2 + 1];
      const inv = 1 / Math.sqrt(ex * ex + ey * ey);
      const lnx = -(ey * inv);
      const lny = ex * inv;
      const lproj = lnx * v[a2] + lny * v[a2 + 1];
      const gnx = ay * lnx - ax * lny;
      const gny = lnx * ax + lny * ay;
      const gproj = b.posx * gnx + b.posy * gny + lproj;
      const gp0x = gv[a2];
      const gp0y = gv[a2 + 1];
      const gp1x = gv[b2];
      const gp1y = gv[b2 + 1];
      edges.push({
        gnx,
        gny,
        gproj,
        gp0x,
        gp0y,
        gp1x,
        gp1y,
        tp0: gp0y * gnx - gp0x * gny, // ZPP_Polygon.as:198
        tp1: gp1y * gnx - gp1x * gny,
        lnx, // edge normal in the polygon's LOCAL frame (for iteratePos reconstruct)
        lny,
        lproj,
      });
    }
    return { gv, edges };
  }

  // [M3c] polygon-polygon narrowphase (ZPP_Collide.as:219): SAT over both polys'
  // edge normals → reference/incident edge → clip → up to 2 contacts. Pass bodies
  // in the original's (body1, body2) order. Returns the normal + contact list
  // (each penetration + clipped contact point). Order-independent vs the golden.
  polyPolyManifold(ha: number, hb: number): {
    nx: number;
    ny: number;
    contacts: { px: number; py: number; penetration: number }[];
  } | null {
    const A = this.bodies.get(ha);
    const B = this.bodies.get(hb);
    if (A == null || B == null) return null;
    const sA = A.shapes[0];
    const sB = B.shapes[0];
    if (sA.kind !== 'polygon' || sB.kind !== 'polygon') return null;
    const wA = this.polyWorldGeom(A, sA);
    const wB = this.polyWorldGeom(B, sB);

    type E = (typeof wA.edges)[number];
    let best = -1e100;
    let loc8 = -1;
    let refEdge: E | null = null;
    // SAT: param1(A) edges vs B verts, then param2(B) edges vs A verts.
    const sat = (edges: E[], verts: number[], which: number): boolean => {
      for (const e of edges) {
        let mn = 1e100;
        for (let k = 0; k < verts.length; k += 2) {
          const proj = e.gnx * verts[k] + e.gny * verts[k + 1];
          if (proj < mn) mn = proj;
        }
        const sep = mn - e.gproj;
        if (sep >= 0) return false; // separating axis → no collision
        if (sep > best) {
          best = sep;
          refEdge = e;
          loc8 = which;
        }
      }
      return true;
    };
    if (!sat(wA.edges, wB.gv, 1)) return null;
    if (!sat(wB.edges, wA.gv, 2)) return null;
    if (refEdge == null) return null;
    const ref: E = refEdge;

    const incWorld = loc8 === 1 ? wB : wA;
    const sign = loc8 === 1 ? 1 : -1;
    // incident edge = inc poly's edge most anti-parallel to the reference normal
    let inc: E | null = null;
    let mindot = 1e100;
    for (const e of incWorld.edges) {
      const d = ref.gnx * e.gnx + ref.gny * e.gny;
      if (d < mindot) {
        mindot = d;
        inc = e;
      }
    }
    const ie: E = inc!;

    // clip the incident edge to the reference edge's side bounds (ZPP_Collide.as:331)
    let p0x = ie.gp0x;
    let p0y = ie.gp0y;
    let p1x = ie.gp1x;
    let p1y = ie.gp1y;
    const dx = p1x - p0x;
    const dy = p1y - p0y;
    const c27 = ref.gny * p0x - ref.gnx * p0y;
    const c28 = ref.gny * p1x - ref.gnx * p1y;
    const c29 = 1 / (c28 - c27);
    const t30 = (-ref.tp1 - c27) * c29;
    if (t30 > 1e-8) {
      p0x += dx * t30;
      p0y += dy * t30;
    }
    const t31 = (-ref.tp0 - c28) * c29;
    if (t31 < -1e-8) {
      p1x += dx * t31;
      p1y += dy * t31;
    }

    let nx = ref.gnx * sign;
    let ny = ref.gny * sign;
    const d34 = p0x * ref.gnx + p0y * ref.gny - ref.gproj;
    const d35 = p1x * ref.gnx + p1y * ref.gny - ref.gproj;
    if (d34 > 0 && d35 > 0) return null;
    // param4 = true for body1==param1 (matches the harness's (body1, body2) order)
    nx = -nx;
    ny = -ny;

    return {
      nx,
      ny,
      contacts: [
        { px: p0x - ref.gnx * d34 * 0.5, py: p0y - ref.gny * d34 * 0.5, penetration: -d34 },
        { px: p1x - ref.gnx * d35 * 0.5, py: p1y - ref.gny * d35 * 0.5, penetration: -d35 },
      ],
    };
  }

  // ======================================================================== //
  //  [M4-CCD] Closest-distance query (ZPP_SweepDistance.distance) — the        //
  //  primitive the continuous-collision sweep builds on. Specialized by shape  //
  //  pair (circle-circle direct; circle-polygon closest-feature). Returns the  //
  //  signed distance (negative when overlapping) and witness points p3 (on     //
  //  shape A), p4 (on shape B), p5 (normal) in the CALLER's argument order.    //
  // ======================================================================== //
  distanceQuery(
    bA: Body, sA: Shape, bB: Body, sB: Shape, maxDist = 1e100,
  ): { d: number; p3x: number; p3y: number; p4x: number; p4y: number; p5x: number; p5y: number } {
    // --- circle vs circle (ZPP_SweepDistance.as:2138) ---
    if (sA.kind === 'circle' && sB.kind === 'circle') {
      const w1 = this.shapeWorldCOM(bA, sA);
      const w2 = this.shapeWorldCOM(bB, sB);
      let nx = w2.x - w1.x;
      let ny = w2.y - w1.y;
      const d2 = nx * nx + ny * ny;
      const dist = d2 === 0 ? 0 : 1 / fastInvSqrt(d2);
      const d = dist - (sA.radius + sB.radius);
      let p3x = 0;
      let p3y = 0;
      let p4x = 0;
      let p4y = 0;
      let p5x = 0;
      let p5y = 0;
      if (d < maxDist) {
        if (dist === 0) {
          nx = 1;
          ny = 0;
        } else {
          const inv = 1 / dist;
          nx *= inv;
          ny *= inv;
        }
        p3x = w1.x + nx * sA.radius;
        p3y = w1.y + ny * sA.radius;
        p4x = w2.x + nx * -sB.radius;
        p4y = w2.y + ny * -sB.radius;
        p5x = nx;
        p5y = ny;
      }
      return { d, p3x, p3y, p4x, p4y, p5x, p5y };
    }
    // normalize to (polygon, circle); remember if we swapped the caller's args
    let swapped = false;
    let pB: Body;
    let pS: PolygonShape;
    let cB: Body;
    let cS: CircleShape;
    if (sA.kind === 'circle' && sB.kind === 'polygon') {
      swapped = true;
      cB = bA; cS = sA; pB = bB; pS = sB;
    } else if (sA.kind === 'polygon' && sB.kind === 'circle') {
      pB = bA; pS = sA; cB = bB; cS = sB;
    } else if (sA.kind === 'polygon' && sB.kind === 'polygon') {
      return this.distancePolyPoly(bA, sA, bB, sB, maxDist);
    } else {
      throw new Error('distanceQuery: unhandled shape pair');
    }
    const r = cS.radius;
    const wc = this.shapeWorldCOM(cB, cS);
    const geom = this.polyWorldGeom(pB, pS);
    // deepest edge (ZPP_SweepDistance.as:2192)
    let best = -1e100;
    let be = -1;
    for (let i = 0; i < geom.edges.length; i++) {
      const e = geom.edges[i];
      const sep = e.gnx * wc.x + e.gny * wc.y - e.gproj - r;
      if (sep > maxDist) {
        best = sep;
        be = -2; // signal early-out (no witness needed)
        break;
      }
      if (sep > 0) {
        if (sep > best) {
          best = sep;
          be = i;
        }
      } else if (best < 0 && sep > best) {
        best = sep;
        be = i;
      }
    }
    let d = best;
    let polyx = 0;
    let polyy = 0;
    let circx = 0;
    let circy = 0;
    let nx = 0;
    let ny = 0;
    if (best < maxDist && be >= 0) {
      const e = geom.edges[be];
      const t = wc.y * e.gnx - wc.x * e.gny;
      const tp0 = e.gp0y * e.gnx - e.gp0x * e.gny;
      const tp1 = e.gp1y * e.gnx - e.gp1x * e.gny;
      if (t <= tp0) {
        ({ d, polyx, polyy, circx, circy, nx, ny } = this.distVertex(e.gp0x, e.gp0y, wc, r, maxDist));
      } else if (t >= tp1) {
        ({ d, polyx, polyy, circx, circy, nx, ny } = this.distVertex(e.gp1x, e.gp1y, wc, r, maxDist));
      } else {
        // face region (ZPP_SweepDistance.as:2290)
        circx = wc.x + e.gnx * -r;
        circy = wc.y + e.gny * -r;
        polyx = circx + e.gnx * -d;
        polyy = circy + e.gny * -d;
        nx = e.gnx;
        ny = e.gny;
      }
    }
    if (swapped) return { d, p3x: circx, p3y: circy, p4x: polyx, p4y: polyy, p5x: -nx, p5y: -ny };
    return { d, p3x: polyx, p3y: polyy, p4x: circx, p4y: circy, p5x: nx, p5y: ny };
  }

  // circle-vs-vertex closest distance branch of distanceQuery (the gp0/gp1 cases).
  private distVertex(
    vx: number, vy: number, wc: { x: number; y: number }, r: number, maxDist: number,
  ): { d: number; polyx: number; polyy: number; circx: number; circy: number; nx: number; ny: number } {
    let lx = wc.x - vx;
    let ly = wc.y - vy;
    const dd = lx * lx + ly * ly;
    const dist = dd === 0 ? 0 : 1 / fastInvSqrt(dd);
    const d = dist - r;
    let polyx = 0;
    let polyy = 0;
    let circx = 0;
    let circy = 0;
    let nx = 0;
    let ny = 0;
    if (d < maxDist) {
      if (dist === 0) {
        lx = 1;
        ly = 0;
      } else {
        const inv = 1 / dist;
        lx *= inv;
        ly *= inv;
      }
      polyx = vx; // gp + n*0
      polyy = vy;
      circx = wc.x + lx * -r;
      circy = wc.y + ly * -r;
      nx = lx;
      ny = ly;
    }
    return { d, polyx, polyy, circx, circy, nx, ny };
  }

  // [P2] polygon-vs-polygon closest distance (ZPP_SweepDistance.distance:2309).
  // SAT both directions selects the reference edge (max separation when apart, or
  // least-negative when overlapping); when SEPARATED, the closest points are the
  // segment-segment closest pair of the reference and incident edges (Math.sqrt —
  // NOT fast-inv-sqrt here); when OVERLAPPING, the incident edge is clipped to the
  // reference edge planes and the deeper clipped point gives the (negative) gap.
  // Returns d + witness p3 (on sA), p4 (on sB), p5 (normal, sA→sB).
  private distancePolyPoly(
    bA: Body, sA: PolygonShape, bB: Body, sB: PolygonShape, maxDist: number,
  ): { d: number; p3x: number; p3y: number; p4x: number; p4y: number; p5x: number; p5y: number } {
    const w1 = this.polyWorldGeom(bA, sA); // param1 = sA
    const w2 = this.polyWorldGeom(bB, sB); // param2 = sB
    type E = (typeof w1.edges)[number];
    const none = { d: maxDist, p3x: 0, p3y: 0, p4x: 0, p4y: 0, p5x: 0, p5y: 0 };
    // SAT: project the other poly's verts on each edge normal; track the best
    // separation (max if any positive; else least-negative). Returns false on a
    // separating axis beyond maxDist (early-out → no contribution).
    let best = -1e100; // loc9
    let loc24 = 0;
    let refE: E | null = null;
    const sat = (edges: E[], verts: number[], which: number): boolean => {
      for (const e of edges) {
        let mn = 1e100;
        for (let k = 0; k < verts.length; k += 2) {
          const p = e.gnx * verts[k] + e.gny * verts[k + 1];
          if (p < mn) mn = p;
        }
        const sep = mn - e.gproj;
        if (sep > maxDist) { best = sep; return false; }
        if (sep > 0) {
          if (sep > best) { best = sep; refE = e; loc24 = which; }
        } else if (best < 0 && sep > best) {
          best = sep; refE = e; loc24 = which;
        }
      }
      return true;
    };
    if (!sat(w1.edges, w2.gv, 1)) return none;
    if (best >= maxDist) return none;
    if (!sat(w2.edges, w1.gv, 2)) return none;
    if (best >= maxDist || refE == null) return none;
    const ref: E = refE;
    const incPoly = loc24 === 1 ? w2 : w1; // incident geometry
    const swap = loc24 === 2; // loc15: reference is poly2 ⇒ caller p3/p4 swap
    // incident edge = inc poly's edge most anti-parallel to the reference normal
    let inc: E | null = null;
    let mindot = 1e100;
    for (const e of incPoly.edges) {
      const dp = ref.gnx * e.gnx + ref.gny * e.gny;
      if (dp < mindot) { mindot = dp; inc = e; }
    }
    const ie: E = inc!;
    // ZPP writes ref-side point → (local) param3 = out3, inc-side → param4 = out4
    let out3x = 0;
    let out3y = 0;
    let out4x = 0;
    let out4y = 0;
    let p5x = swap ? -ref.gnx : ref.gnx;
    let p5y = swap ? -ref.gny : ref.gny;
    let d = best;
    if (best >= 0) {
      // SEPARATED: closest pair between reference segment and incident segment
      const a0x = ref.gp0x;
      const a0y = ref.gp0y;
      const a1x = ref.gp1x;
      const a1y = ref.gp1y;
      const b0x = ie.gp0x;
      const b0y = ie.gp0y;
      const b1x = ie.gp1x;
      const b1y = ie.gp1y;
      const ux = a1x - a0x;
      const uy = a1y - a0y;
      const vx = b1x - b0x;
      const vy = b1y - b0y;
      const iu = 1 / (ux * ux + uy * uy);
      const iv = 1 / (vx * vx + vy * vy);
      let t34 = -(ux * (a0x - b0x) + uy * (a0y - b0y)) * iu;
      let t35 = -(ux * (a0x - b1x) + uy * (a0y - b1y)) * iu;
      let t36 = -(vx * (b0x - a0x) + vy * (b0y - a0y)) * iv;
      let t37 = -(vx * (b0x - a1x) + vy * (b0y - a1y)) * iv;
      if (t34 < 0) t34 = 0; else if (t34 > 1) t34 = 1;
      if (t35 < 0) t35 = 0; else if (t35 > 1) t35 = 1;
      if (t36 < 0) t36 = 0; else if (t36 > 1) t36 = 1;
      if (t37 < 0) t37 = 0; else if (t37 > 1) t37 = 1;
      const q38x = a0x + ux * t34;
      const q38y = a0y + uy * t34;
      const q40x = a0x + ux * t35;
      const q40y = a0y + uy * t35;
      const q42x = b0x + vx * t36;
      const q42y = b0y + vy * t36;
      const q44x = b0x + vx * t37;
      const q44y = b0y + vy * t37;
      let dr46 = (q38x - b0x) * (q38x - b0x) + (q38y - b0y) * (q38y - b0y);
      const dr47 = (q40x - b1x) * (q40x - b1x) + (q40y - b1y) * (q40y - b1y);
      let dr48 = (q42x - a0x) * (q42x - a0x) + (q42y - a0y) * (q42y - a0y);
      const dr49 = (q44x - a1x) * (q44x - a1x) + (q44y - a1y) * (q44y - a1y);
      // best ref-side point (q50) vs an incident endpoint (q52)
      let q50x: number;
      let q50y: number;
      let q52x: number;
      let q52y: number;
      if (dr46 < dr47) { q50x = q38x; q50y = q38y; q52x = b0x; q52y = b0y; }
      else { q50x = q40x; q50y = q40y; q52x = b1x; q52y = b1y; dr46 = dr47; }
      // best inc-side point (q53) vs a reference endpoint (q55)
      let q53x: number;
      let q53y: number;
      let q55x: number;
      let q55y: number;
      if (dr48 < dr49) { q53x = q42x; q53y = q42y; q55x = a0x; q55y = a0y; }
      else { q53x = q44x; q53y = q44y; q55x = a1x; q55y = a1y; dr48 = dr49; }
      if (dr46 < dr48) {
        out3x = q50x; out3y = q50y; // ref-side
        out4x = q52x; out4y = q52y; // inc-side
        d = Math.sqrt(dr46);
      } else {
        out4x = q53x; out4y = q53y; // inc-side
        out3x = q55x; out3y = q55y; // ref-side
        d = Math.sqrt(dr48);
      }
      if (d !== 0) {
        p5x = out4x - out3x;
        p5y = out4y - out3y;
        const id = 1 / d;
        p5x *= id;
        p5y *= id;
        if (swap) { p5x = -p5x; p5y = -p5y; }
      }
    } else {
      // OVERLAPPING: clip the incident edge to the reference edge's side planes
      let c11x = ie.gp0x;
      let c11y = ie.gp0y;
      let c13x = ie.gp1x;
      let c13y = ie.gp1y;
      const dx = c13x - c11x;
      const dy = c13y - c11y;
      const c34 = ref.gny * c11x - ref.gnx * c11y;
      const c35 = ref.gny * c13x - ref.gnx * c13y;
      const c36 = 1 / (c35 - c34);
      const t37 = (-ref.tp1 - c34) * c36;
      if (t37 > 1e-8) { c11x += dx * t37; c11y += dy * t37; }
      const t38 = (-ref.tp0 - c35) * c36;
      if (t38 < -1e-8) { c13x += dx * t38; c13y += dy * t38; }
      const d39 = c11x * ref.gnx + c11y * ref.gny - ref.gproj;
      const d40 = c13x * ref.gnx + c13y * ref.gny - ref.gproj;
      if (d39 < d40) {
        out4x = c11x; out4y = c11y;
        out3x = out4x + ref.gnx * -d39;
        out3y = out4y + ref.gny * -d39;
        d = d39;
      } else {
        out4x = c13x; out4y = c13y;
        out3x = out4x + ref.gnx * -d40;
        out3y = out4y + ref.gny * -d40;
        d = d40;
      }
    }
    // map ZPP's (post-swap) param3/param4 back to caller order (p3 on sA, p4 on sB)
    if (swap) {
      return { d, p3x: out4x, p3y: out4y, p4x: out3x, p4y: out3y, p5x, p5y };
    }
    return { d, p3x: out3x, p3y: out3y, p4x: out4x, p4y: out4y, p5x, p5y };
  }

  // world-space centre of a shape (circle COM or polygon body COM), matching the
  // body transform used throughout (axis = (sin rot, cos rot)).
  private shapeWorldCOM(b: Body, s: Shape): { x: number; y: number } {
    const ax = Math.sin(b.rot);
    const ay = Math.cos(b.rot);
    return {
      x: b.posx + (ay * s.localCOMx - ax * s.localCOMy),
      y: b.posy + (s.localCOMx * ax + s.localCOMy * ay),
    };
  }

  // [M4-CCD] public closest-distance query between shape 0 of two bodies, in the
  // given (A, B) order (the witness/normal sign depends on it).
  distanceBetween(
    hA: number, hB: number,
  ): { d: number; p3x: number; p3y: number; p4x: number; p4y: number; p5x: number; p5y: number } | null {
    const bA = this.bodies.get(hA);
    const bB = this.bodies.get(hB);
    if (bA == null || bB == null) return null;
    return this.distanceQuery(bA, bA.shapes[0], bB, bB.shapes[0]);
  }

  // [M4-CCD] advance a body's transform from its sweepTime to `target` (a time in
  // [0,dt]) along its velocity (ZPP_Space.as:866 / 10827). Idempotent given sweepTime.
  private advanceSweep(b: Body, target: number): void {
    const adv = target - b.sweepTime;
    if (adv === 0) return;
    b.sweepTime = target;
    b.posx += b.velx * adv;
    b.posy += b.vely * adv;
    if (b.angvel !== 0) {
      const dr = b.sweep_angvel * adv;
      this.applyPosRotation(b, dr);
    }
  }

  // [M4-CCD] staticSweep — conservative advancement of a moving body (ev.mv, a
  // circle here) against a static polygon, to the time-of-impact (ZPP_SweepDistance.as:789).
  // Reuses distanceQuery (the inlined circle-poly distance is identical to distance()).
  private staticSweep(ev: ToiEvent, dt: number): void {
    const b1 = ev.mv;
    const negvx = -b1.velx;
    const negvy = -b1.vely;
    let sa = b1.sweep_angvel;
    if (sa < 0) sa = -sa;
    const angBound = ev.ms.sweepCoef * sa; // 0 for a centred circle
    let t = 0; // sweep fraction (param3)
    let iter = 0;
    for (;;) {
      this.advanceSweep(b1, t * dt);
      const dr = this.distanceQuery(b1, ev.ms, ev.stat, ev.ss);
      ev.c1x = dr.p3x;
      ev.c1y = dr.p3y;
      ev.axisx = dr.p5x;
      ev.axisy = dr.p5y;
      const loc18 = dr.d + 0.5; // + margin (param4)
      const approach = negvx * ev.axisx + negvy * ev.axisy;
      if (loc18 < 0.05) {
        const armx = ev.c1x - b1.posx;
        const army = ev.c1y - b1.posy;
        const sep = approach - b1.sweep_angvel * (ev.axisy * armx - ev.axisx * army);
        if (sep > 0) ev.slipped = true;
        if (sep <= 0 || loc18 < 0.025) break;
      }
      const denom = (angBound - approach) * dt;
      if (denom <= 0) {
        t = -1;
        break;
      }
      let step = loc18 / denom;
      if (step < 0.000001) step = 0.000001;
      t += step;
      if (t >= 1) {
        t = -1;
        break;
      }
      if (++iter >= 40) {
        if (loc18 > 0.5) ev.failed = true;
        break;
      }
    }
    ev.toi = t;
  }

  // [M4-CCD] dynamicSweep — conservative advancement of a moving body against a MOVING
  // (kinematic) obstacle, in the relative frame (ZPP_SweepDistance.dynamicSweep:24).
  // Same structure as staticSweep, but BOTH bodies advance each iteration and the approach
  // rate uses the RELATIVE velocity (mv − obstacle). For a separating pair (a ball that just
  // bounced off and is pulling ahead of the obstacle) this correctly yields toi<0 — no false
  // penetration, no re-solve, restitution preserved. The rewound kinematic obstacle is
  // restored to the full step by the finish loop in continuousCollisions.
  private dynamicSweep(ev: ToiEvent, dt: number): void {
    const b1 = ev.mv;
    const b2 = ev.stat; // kinematic obstacle — moves during the step
    let sa1 = b1.sweep_angvel;
    if (sa1 < 0) sa1 = -sa1;
    let sa2 = b2.sweep_angvel;
    if (sa2 < 0) sa2 = -sa2;
    const angBound = ev.ms.sweepCoef * sa1 + ev.ss.sweepCoef * sa2;
    let t = 0;
    let iter = 0;
    for (;;) {
      this.advanceSweep(b1, t * dt);
      this.advanceSweep(b2, t * dt);
      const dr = this.distanceQuery(b1, ev.ms, ev.stat, ev.ss);
      ev.c1x = dr.p3x;
      ev.c1y = dr.p3y;
      ev.axisx = dr.p5x;
      ev.axisy = dr.p5y;
      const loc18 = dr.d + 0.5; // + margin (param4)
      // relative closing rate: −((mv.vel − obstacle.vel) · axis)
      const negvx = -(b1.velx - b2.velx);
      const negvy = -(b1.vely - b2.vely);
      const approach = negvx * ev.axisx + negvy * ev.axisy;
      if (loc18 < 0.05) {
        const armx = ev.c1x - b1.posx;
        const army = ev.c1y - b1.posy;
        const sep = approach - b1.sweep_angvel * (ev.axisy * armx - ev.axisx * army);
        if (sep > 0) ev.slipped = true;
        if (sep <= 0 || loc18 < 0.025) break;
      }
      const denom = (angBound - approach) * dt;
      if (denom <= 0) {
        t = -1;
        break;
      }
      let step = loc18 / denom;
      if (step < 0.000001) step = 0.000001;
      t += step;
      if (t >= 1) {
        t = -1;
        break;
      }
      if (++iter >= 40) {
        if (loc18 > 0.5) ev.failed = true;
        break;
      }
    }
    ev.toi = t;
  }

  // [M4-CCD] continuousCollisions — between updatePos and iteratePos, arrest fast
  // (non-frozen) dynamic bodies at their first impact with static geometry so they
  // don't tunnel (ZPP_Space.as:10633). Currently the ball-vs-static-polygon path
  // (the only bullet case in the game); dynamic-vs-dynamic CCD is deferred.
  private continuousCollisions(dt: number): void {
    const arr = this.live;
    // build TOI events for fast dynamic circles vs static polygons
    const events: ToiEvent[] = [];
    for (let i = 0; i < arr.length; i++) {
      for (let j = i + 1; j < arr.length; j++) {
        const A = arr[i];
        const B = arr[j];
        let mv: Body;
        let stat: Body;
        if (A.type === TYPE_DYNAMIC && !A.sweepFrozen && !A.sleeping && B.type !== TYPE_DYNAMIC) {
          mv = A;
          stat = B;
        } else if (B.type === TYPE_DYNAMIC && !B.sweepFrozen && !B.sleeping && A.type !== TYPE_DYNAMIC) {
          mv = B;
          stat = A;
        } else {
          continue;
        }
        if (this.ignoredPairs.size > 0 && this.ignoredPairs.has(pairKey(mv.handle, stat.handle))) continue; // joint collide_joined=false
        // [E2] every shape pair (a fast ball can hit any shape of a multi-shape
        // static body). moving circle OR polygon vs static circle/polygon.
        for (const ms of mv.shapes) {
          for (const ss of stat.shapes) {
            if (!shouldCollide(ms, ss)) continue; // [F2] same interaction filter
            const ev: ToiEvent = {
              mv, ms, stat, ss,
              c1x: 0, c1y: 0, axisx: 0, axisy: 0, toi: 0, slipped: false, failed: false,
            };
            // Nape routes kinematic-involved pairs to dynamicSweep (relative-frame, both
            // bodies move) and static-only pairs to staticSweep (ZPP_Space.continuousEvent
            // :10593-10614). A static obstacle has zero velocity so the two coincide; a
            // KINEMATIC obstacle moves, and treating it as static makes a bounced/separating
            // body look like it's penetrating a fixed wall → false TOI → restitution clawed
            // back (the level-7 "ball sticks to the moving opponent" bug).
            if (stat.type === TYPE_KINEMATIC) this.dynamicSweep(ev, dt);
            else this.staticSweep(ev, dt);
            if (ev.toi >= 0 && !ev.failed) events.push(ev);
          }
        }
      }
    }
    // resolve TOIs in time order
    let t = 0;
    while (t < 1 && events.length > 0) {
      let bestIdx = -1;
      for (let k = 0; k < events.length; k++) {
        if (events[k].toi >= 0 && (bestIdx < 0 || events[k].toi < events[bestIdx].toi)) bestIdx = k;
      }
      if (bestIdx < 0) break;
      const ev = events[bestIdx];
      t = ev.toi;
      events.splice(bestIdx, 1);
      const mv = ev.mv;
      // a body already frozen at an earlier TOI is not advanced again (ZPP_Space.as:10748)
      if (!mv.sweepFrozen) this.advanceSweep(mv, t * dt);
      // re-solve at the frozen contact: narrowphase → prestep(continuous) → 1 vel iter.
      // Body order must match the discrete narrowphase so the arbiter (keyed per
      // pair) keeps a consistent b1/b2: circle is always b1; for poly-poly the order
      // mirrors the live-order pass (static body first here, as in p0pp).
      let arb: Arbiter | null;
      if (ev.ms.kind === 'circle' && ev.ss.kind === 'circle') {
        arb = this.narrowCircleCircle(mv, ev.ms, ev.stat, ev.ss);
      } else if (ev.ms.kind === 'circle' && ev.ss.kind === 'polygon') {
        arb = this.narrowCirclePoly(mv, ev.stat, ev.ms, ev.ss);
      } else if (ev.ms.kind === 'polygon' && ev.ss.kind === 'circle') {
        arb = this.narrowCirclePoly(ev.stat, mv, ev.ss, ev.ms);
      } else {
        arb = this.narrowPolyPoly(ev.stat, ev.ss as PolygonShape, mv, ev.ms as PolygonShape);
      }
      if (arb != null) {
        // NOTE: presteparb's param3=true does NOT set the arbiter's `continuous`
        // field, so biasCoef stays 0.6 (non-continuous) for the re-solve (ZPP_Space.as:4167-69).
        // Re-solve ONLY this swept arbiter (not a global iterateVel) — Nape's CCD inline-solves
        // the single pair (ZPP_Space.as:10912). A global sweep would re-solve an already-bounced
        // contact with its warm-started impulse and claw the restitution back (lost-bounce bug).
        this.prestep(dt, arb);
        this.iterateVel(1, arb);
        if (arb.active && !mv.sweepFrozen) {
          mv.sweepFrozen = true;
          mv.angvel = mv.sweep_angvel;
        }
      }
    }
    // finish: advance any still-moving body to the full step, then reset sweepTime.
    // KINEMATIC obstacles that a dynamicSweep rewound must also be carried back to dt here
    // (the sweep left them at an intermediate sweepTime; advanceSweep is a no-op for any
    // body still at dt), otherwise the obstacle would be left short of its end-of-step pose.
    for (const b of arr) {
      if ((b.type === TYPE_DYNAMIC && !b.sweepFrozen) || b.type === TYPE_KINEMATIC) {
        this.advanceSweep(b, dt);
      }
      b.sweepTime = 0;
    }
  }

  // ======================================================================== //
  //  [M4] Contact solver — the sequential-impulse pipeline (ZPP_Space.as).    //
  //  Faithful transcription of the original's prestep/warmStart/iterateVel/   //
  //  iteratePos. Currently wired for the circle-vs-static-polygon resting     //
  //  drop (single face contact); paths not exercised by that scenario throw a //
  //  clearly-marked error rather than run unverified.                         //
  // ======================================================================== //

  // Build/refresh arbiters for this step. Naive broadphase (all live pairs with
  // ≥1 dynamic body); per pair, narrowphase to a manifold. Only circle-vs-poly
  // is wired; other pairings are later sub-milestones.
  private narrowphase(): void {
    const arr = this.live;
    for (let i = 0; i < arr.length; i++) {
      for (let j = i + 1; j < arr.length; j++) {
        const A = arr[i];
        const B = arr[j];
        if (A.type !== TYPE_DYNAMIC && B.type !== TYPE_DYNAMIC) continue;
        if (this.ignoredPairs.size > 0 && this.ignoredPairs.has(pairKey(A.handle, B.handle))) continue; // joint collide_joined=false
        // [E2] every shape pair, not just shapes[0] (multi-shape bodies: goals,
        // switches, keeper). Each pair persists its own arbiter (keyed by shape id).
        for (const sa of A.shapes) {
          for (const sb of B.shapes) {
            if (!shouldCollide(sa, sb)) continue; // [F2] interaction filter (sensors fall out here)
            if (sa.kind === 'circle' && sb.kind === 'circle') this.narrowCircleCircle(A, sa, B, sb);
            else if (sa.kind === 'circle' && sb.kind === 'polygon') this.narrowCirclePoly(A, B, sa, sb);
            else if (sa.kind === 'polygon' && sb.kind === 'circle') this.narrowCirclePoly(B, A, sb, sa);
            else if (sa.kind === 'polygon' && sb.kind === 'polygon') this.narrowPolyPoly(A, sa, B, sb);
          }
        }
      }
    }
  }

  // [P0b] circle (b1) vs circle (b2) narrowphase → arbiter. A circle-circle contact
  // is ptype 2 (both witness points are circle centres), so it shares the
  // iteratePosVertex position solver (ZPP_Collide.as:1088). Returns the arbiter or null.
  private narrowCircleCircle(bA: Body, sA: CircleShape, bB: Body, sB: CircleShape): Arbiter | null {
    const wa = this.shapeWorldCOM(bA, sA);
    const wb = this.shapeWorldCOM(bB, sB);
    const rsum = sA.radius + sB.radius;
    const dx = wb.x - wa.x; // c2 − c1
    const dy = wb.y - wa.y;
    const d2 = dx * dx + dy * dy;
    if (d2 > rsum * rsum) return null;
    let nx: number;
    let ny: number;
    let px: number;
    let py: number;
    let cdist: number;
    if (d2 < 1e-8 * 1e-8) {
      nx = 1;
      ny = 0;
      px = wa.x;
      py = wa.y;
      cdist = -rsum;
    } else {
      const invSqrt = fastInvSqrt(d2);
      const dist = invSqrt < 1e-8 ? 1e100 : 1 / invSqrt;
      const interp = 0.5 + (sA.radius - 0.5 * rsum) * invSqrt; // ZPP_Collide.as:1160
      px = wa.x + dx * interp;
      py = wa.y + dy * interp;
      nx = dx * invSqrt; // param4=false (ZPP_Collide.as:1268)
      ny = dy * invSqrt;
      cdist = dist - rsum;
    }
    const arb = this.getArbiter(bA, bB, sA, sB);
    arb.nx = nx;
    arb.ny = ny;
    arb.ptype = 2;
    arb.rev = false;
    arb.radius = rsum;
    arb.stamp = this.stamp;
    let c = arb.contacts.find((k) => k.hash === 0);
    if (c == null) {
      c = {
        hash: 0, px, py, dist: cdist,
        lr1x: 0, lr1y: 0, lr2x: 0, lr2y: 0,
        r1x: 0, r1y: 0, r2x: 0, r2y: 0,
        nMass: 0, tMass: 0, bounce: 0, friction: 0, elasticity: 0,
        jnAcc: 0, jtAcc: 0, stamp: this.stamp, active: false, fresh: true, posOnly: false,
      };
      arb.jrAcc = 0;
      arb.contacts.push(c);
    } else {
      c.fresh = false;
    }
    c.px = px;
    c.py = py;
    c.dist = cdist;
    c.stamp = this.stamp;
    c.lr1x = sA.localCOMx; // each circle's local COM (ZPP_Collide.as:1289)
    c.lr1y = sA.localCOMy;
    c.lr2x = sB.localCOMx;
    c.lr2y = sB.localCOMy;
    c.posOnly = false;
    return arb;
  }

  // [P0b-2] polygon (b1) vs polygon (b2) narrowphase → arbiter (ZPP_Collide.as:219).
  // SAT over both polys' edge normals selects the reference edge (deepest
  // separating axis); the incident poly's most anti-parallel edge is clipped to the
  // reference edge's side planes, yielding up to two contacts. A face contact is
  // ptype 0 (reference = b1) or ptype 1 (reference = b2). lnorm/lproj come from the
  // reference edge's LOCAL frame; each contact's lr1 is the clipped point in the
  // INCIDENT body's local frame (the position solver reconstructs from these).
  // `param4` (the shape-swap flag) is false here: the caller passes the bodies in
  // the arbiter's own (b1,b2) order, so no negation — confirmed bit-exact vs golden.
  private narrowPolyPoly(bA: Body, sA: PolygonShape, bB: Body, sB: PolygonShape): Arbiter | null {
    const wA = this.polyWorldGeom(bA, sA);
    const wB = this.polyWorldGeom(bB, sB);
    type E = (typeof wA.edges)[number];
    let best = -1e100;
    let loc8 = -1;
    let refEdge: E | null = null;
    // SAT: each edge's outward normal is a candidate axis; project the OTHER poly's
    // verts, take the min, subtract this edge's projection → separation. The deepest
    // (largest, still negative) wins; any non-negative separation ⇒ no collision.
    const sat = (edges: E[], verts: number[], which: number): boolean => {
      for (const e of edges) {
        let mn = 1e100;
        for (let k = 0; k < verts.length; k += 2) {
          const proj = e.gnx * verts[k] + e.gny * verts[k + 1];
          if (proj < mn) mn = proj;
          if (mn - e.gproj <= best) break; // ZPP early-out (loc13 − gproj ≤ loc6)
        }
        const sep = mn - e.gproj;
        if (sep >= 0) return false;
        if (sep > best) {
          best = sep;
          refEdge = e;
          loc8 = which;
        }
      }
      return true;
    };
    if (!sat(wA.edges, wB.gv, 1)) return null;
    if (!sat(wB.edges, wA.gv, 2)) return null;
    if (refEdge == null) return null;
    const ref: E = refEdge;
    const incWorld = loc8 === 1 ? wB : wA;
    const incBody = loc8 === 1 ? bB : bA; // loc18 — lr1 is stored in this body's frame
    const sign = loc8 === 1 ? 1 : -1;
    // incident edge = inc poly's edge most anti-parallel to the reference normal
    let inc: E | null = null;
    let mindot = 1e100;
    for (const e of incWorld.edges) {
      const d = ref.gnx * e.gnx + ref.gny * e.gny;
      if (d < mindot) {
        mindot = d;
        inc = e;
      }
    }
    const ie: E = inc!;
    // clip the incident edge to the reference edge's side bounds (ZPP_Collide.as:331)
    let p0x = ie.gp0x;
    let p0y = ie.gp0y;
    let p1x = ie.gp1x;
    let p1y = ie.gp1y;
    const dx = p1x - p0x;
    const dy = p1y - p0y;
    const c27 = ref.gny * p0x - ref.gnx * p0y;
    const c28 = ref.gny * p1x - ref.gnx * p1y;
    const c29 = 1 / (c28 - c27);
    const t30 = (-ref.tp1 - c27) * c29;
    if (t30 > 1e-8) {
      p0x += dx * t30;
      p0y += dy * t30;
    }
    const t31 = (-ref.tp0 - c28) * c29;
    if (t31 < -1e-8) {
      p1x += dx * t31;
      p1y += dy * t31;
    }
    const nx = ref.gnx * sign; // param4 = false ⇒ no negation (ZPP_Collide.as:369)
    const ny = ref.gny * sign;
    const d34 = p0x * ref.gnx + p0y * ref.gny - ref.gproj;
    const d35 = p1x * ref.gnx + p1y * ref.gny - ref.gproj;
    if (d34 > 0 && d35 > 0) return null;
    // Nape labels the arbiter b1 = the HIGHER-id body (its broadphase pairs the
    // later-added shape first — every level-9 arbiter has b1.id > b2.id). `live` is
    // creation order so here bA.handle < bB.handle. Relabel b1/b2 to match WITHOUT
    // touching the manifold: the contacts are world/incident-frame and `lnorm` is in
    // the reference body's frame, all label-independent. We only swap b1↔b2, negate
    // the normal (it points b1→b2), and recompute ptype from which physical body is
    // the reference (the position solver reads each contact's `lr1` from the incident
    // body's frame, identified by ptype). Bit-INVARIANT for symmetric / dynamic↔static
    // pairs (why the crate-stack & box-on-floor gates already passed with either
    // label) but it gives an ASYMMETRIC dynamic↔dynamic contact — a tilted post on a
    // crate (unequal masses AND unequal contact depths) — the exact b1/b2 Nape uses,
    // killing the last-bit block-solve drift that accumulated up the level-9 tower.
    const swap = bA.handle < bB.handle;
    const refBody = loc8 === 1 ? bA : bB;
    const b1 = swap ? bB : bA;
    const b2 = swap ? bA : bB;
    const arb = this.getArbiter(b1, b2, swap ? sB : sA, swap ? sA : sB);
    arb.nx = swap ? -nx : nx;
    arb.ny = swap ? -ny : ny;
    arb.ptype = refBody === b1 ? 0 : 1;
    arb.rev = arb.ptype === 1;
    arb.lnormx = ref.lnx;
    arb.lnormy = ref.lny;
    arb.lproj = ref.lproj;
    arb.radius = 0;
    arb.stamp = this.stamp;
    // two contacts: hash arb.rev?1:0 (clipped p0) then arb.rev?0:1 (clipped p1)
    this.polyPolyContact(arb, arb.rev ? 1 : 0, p0x, p0y, d34, ref, incBody);
    this.polyPolyContact(arb, arb.rev ? 0 : 1, p1x, p1y, d35, ref, incBody);
    return arb;
  }

  // Persist/refresh one poly-poly contact (ZPP_Collide.as:374-491). px/py is the
  // clipped point pulled back half its penetration along the (un-signed) reference
  // normal; dist is the signed penetration (negative = overlapping); lr1 is the
  // clipped point expressed in the incident body's local frame.
  private polyPolyContact(
    arb: Arbiter, hash: number, clx: number, cly: number, d: number,
    ref: { gnx: number; gny: number }, incBody: Body,
  ): void {
    let c = arb.contacts.find((k) => k.hash === hash);
    if (c == null) {
      c = {
        hash, px: 0, py: 0, dist: 0,
        lr1x: 0, lr1y: 0, lr2x: 0, lr2y: 0,
        r1x: 0, r1y: 0, r2x: 0, r2y: 0,
        nMass: 0, tMass: 0, bounce: 0, friction: 0, elasticity: 0,
        jnAcc: 0, jtAcc: 0, stamp: this.stamp, active: false, fresh: true, posOnly: false,
      };
      arb.jrAcc = 0;
      // HEAD-insert, matching Nape's ZPP_Collide poly-poly contact insertion
      // (`head.next = new`, ZPP_Collide.as:406-410/465-469): the two contacts are
      // emitted p0 then p1 but each is prepended, so the list (and thus oc1/oc2 =
      // first/second active in prestep) is [p1, p0]. The replica previously appended
      // → [p0, p1], i.e. c1/c2 reversed vs Nape. Harmless for symmetric contacts
      // (equal depth → same sort key, symmetric block solve) but for an UNEQUAL-depth
      // 2-contact poly-poly (a tilted bar resting on a box) it made `c1.dist` the
      // wrong contact's penetration, mis-ordering the both-dynamic arbiter sort
      // (sortcontacts by oc1.dist) → a different Gauss-Seidel order → last-bit drift
      // that accumulates up a tall tower (level-9). See p0fs-tower.
      arb.contacts.unshift(c);
    } else {
      c.fresh = false;
    }
    c.px = clx - ref.gnx * d * 0.5;
    c.py = cly - ref.gny * d * 0.5;
    c.dist = d;
    c.stamp = this.stamp;
    c.posOnly = d > 0;
    // clipped point in the incident body's local frame (ZPP_Collide.as:429-432)
    const relx = clx - incBody.posx;
    const rely = cly - incBody.posy;
    c.lr1x = relx * incBody.axisy + rely * incBody.axisx;
    c.lr1y = rely * incBody.axisy - relx * incBody.axisx;
    c.lr2x = 0;
    c.lr2y = 0;
  }

  // [P0b] Active arbiters in Nape's solve order (ZPP_Space.as:306/1632/8327):
  // both-dynamic contacts FIRST (c_arbiters_false — sorted by penetration depth via
  // sortcontacts), then has-static contacts (c_arbiters_true). The order is
  // load-bearing for coupled Gauss-Seidel: solving static contacts last keeps
  // bodies out of static geometry. Recomputed per call so CCD's freshly-created
  // arbiters are included.
  private orderedActiveArbiters(): Arbiter[] {
    const bothDyn: Arbiter[] = [];
    const hasStatic: Arbiter[] = [];
    for (const arb of this.arbiters.values()) {
      if (arb.stamp !== this.stamp || !arb.active) continue;
      if (arb.b1.type !== TYPE_DYNAMIC || arb.b2.type !== TYPE_DYNAMIC) hasStatic.push(arb);
      else bothDyn.push(arb);
    }
    // stable ascending sort of the both-dynamic group by its first contact's dist
    bothDyn.sort((a, b) => (a.c1 ? a.c1.dist : 0) - (b.c1 ? b.c1.dist : 0));
    return bothDyn.concat(hasStatic);
  }

  // Get-or-create the persistent arbiter for a SHAPE pair, in a fixed internal
  // order. Keyed by the unordered shape-id pair so a multi-shape body keeps a
  // distinct, independently warm-started arbiter per shape-pair.
  private getArbiter(b1: Body, b2: Body, s1: Shape, s2: Shape): Arbiter {
    const key = pairKey(s1.sid, s2.sid);
    let arb = this.arbiters.get(key);
    if (arb == null) {
      arb = {
        key, b1, b2, s1, s2,
        invalidated: true,
        nx: 0, ny: 0, ptype: 0, rev: false,
        lnormx: 0, lnormy: 0, lproj: 0, radius: 0,
        biasCoef: 0, pre_dt: -1, continuous: false,
        restitution: 0, dyn_fric: 0, stat_fric: 0, rfric: 0,
        surfacex: 0, surfacey: 0, rMass: 0, jrAcc: 0,
        contacts: [],
        c1: null, c2: null, oc1: null, oc2: null, hc2: false, hpc2: false,
        k1x: 0, k1y: 0, k2x: 0, k2y: 0,
        rn1a: 0, rt1a: 0, rn1b: 0, rt1b: 0, rn2a: 0, rt2a: 0, rn2b: 0, rt2b: 0,
        Ka: 0, Kb: 0, Kc: 0, kMassa: 0, kMassb: 0, kMassc: 0,
        stamp: -1, active: false,
      };
      this.arbiters.set(key, arb);
    } else {
      arb.b1 = b1;
      arb.b2 = b2;
      arb.s1 = s1;
      arb.s2 = s2;
    }
    return arb;
  }

  // circle (b1) vs polygon (b2) narrowphase → arbiter. The internal order is
  // b1=circle, b2=polygon (ZPP_Collide.as circle-poly path; the only order under
  // which the solver's normal/contact reconstruction is self-consistent). On a
  // face contact this populates ptype=1, rev=true, normal=−gnorm, contact point
  // and local arms exactly as the original (ZPP_Collide.as:956-1084).
  private narrowCirclePoly(cBody: Body, pBody: Body, sc: CircleShape, sp: PolygonShape): Arbiter | null {
    const axc = Math.sin(cBody.rot);
    const ayc = Math.cos(cBody.rot);
    const wcx = cBody.posx + (ayc * sc.localCOMx - axc * sc.localCOMy);
    const wcy = cBody.posy + (sc.localCOMx * axc + sc.localCOMy * ayc);
    const r = sc.radius;
    const axp = Math.sin(pBody.rot);
    const ayp = Math.cos(pBody.rot);
    const v = sp.verts;
    const n = v.length / 2;
    const gvx: number[] = [];
    const gvy: number[] = [];
    for (let k = 0; k < n; k++) {
      gvx.push(pBody.posx + (ayp * v[2 * k] - axp * v[2 * k + 1]));
      gvy.push(pBody.posy + (v[2 * k] * axp + v[2 * k + 1] * ayp));
    }
    let best = -1e100;
    let bestEdge = -1;
    let bgnx = 0; // best edge WORLD normal (gnorm, pre-negation)
    let bgny = 0;
    let blnx = 0; // best edge LOCAL normal (lnorm, polygon frame)
    let blny = 0;
    let blproj = 0;
    let collision = true;
    for (let i = 0; i < n; i++) {
      const a2 = 2 * i;
      const b2 = 2 * ((i + 1) % n);
      const ex = v[a2] - v[b2];
      const ey = v[a2 + 1] - v[b2 + 1];
      const inv = 1 / Math.sqrt(ex * ex + ey * ey);
      const lnx = -(ey * inv);
      const lny = ex * inv;
      const lproj = lnx * v[a2] + lny * v[a2 + 1];
      const gnx = ayp * lnx - axp * lny;
      const gny = lnx * axp + lny * ayp;
      const gproj = pBody.posx * gnx + pBody.posy * gny + lproj;
      const sep = gnx * wcx + gny * wcy - gproj - r;
      if (sep > 0) {
        collision = false;
        break;
      }
      if (sep > best) {
        best = sep;
        bestEdge = i;
        bgnx = gnx;
        bgny = gny;
        blnx = lnx;
        blny = lny;
        blproj = lproj;
      }
    }
    if (!collision || bestEdge < 0) return null; // separated → no active contact this step
    // region test against the deepest edge's endpoints (ZPP_Collide.as:525)
    const gp0x = gvx[bestEdge];
    const gp0y = gvy[bestEdge];
    const e1 = (bestEdge + 1) % n;
    const gp1x = gvx[e1];
    const gp1y = gvy[e1];
    const t = wcy * bgnx - wcx * bgny;
    const tp0 = gp0y * bgnx - gp0x * bgny;
    const tp1 = gp1y * bgnx - gp1x * bgny;

    // contact fields (face = ptype 1, vertex/corner = ptype 2)
    let ptype: number;
    let nx: number;
    let ny: number;
    let px: number;
    let py: number;
    let cdist: number;
    let lr2x = 0;
    let lr2y = 0;
    if (t <= tp0 || t >= tp1) {
      // circle-vertex contact (ZPP_Collide.as:595): nearest feature is a corner.
      const vxw = t <= tp0 ? gp0x : gp1x;
      const vyw = t <= tp0 ? gp0y : gp1y;
      const lx = vxw - wcx; // vertex − circle centre
      const ly = vyw - wcy;
      const d2 = lx * lx + ly * ly;
      if (d2 > r * r) return null; // corner farther than the radius → no contact
      ptype = 2;
      if (d2 < 1e-8) {
        // degenerate: centre on the vertex
        nx = 1;
        ny = 0;
        px = wcx;
        py = wcy;
        cdist = -r;
      } else {
        const invSqrt = fastInvSqrt(d2); // raw (not its reciprocal)
        const dist = invSqrt < 1e-8 ? 1e100 : 1 / invSqrt;
        const interp = 0.5 + (r - 0.5 * r) * invSqrt; // ZPP_Collide.as:600
        px = wcx + lx * interp;
        py = wcy + ly * interp;
        nx = lx * invSqrt; // param4=false branch (ZPP_Collide.as:708)
        ny = ly * invSqrt;
        cdist = dist - r;
      }
      // vertex in the polygon's LOCAL frame, for the ptype-2 position solver (lr2)
      const dvx = vxw - pBody.posx;
      const dvy = vyw - pBody.posy;
      lr2x = dvx * ayp + dvy * axp;
      lr2y = dvy * ayp - dvx * axp;
    } else {
      // face contact (ZPP_Collide.as:956). Contact point sits between the circle
      // surface and the penetration depth: worldCOM − gnorm·(radius + sep·0.5).
      ptype = 1;
      const m = r + best * 0.5;
      px = wcx - bgnx * m;
      py = wcy - bgny * m;
      nx = -bgnx;
      ny = -bgny;
      cdist = best;
    }

    const arb = this.getArbiter(cBody, pBody, sc, sp);
    arb.nx = nx;
    arb.ny = ny;
    arb.ptype = ptype; // 1 = face owned by the polygon (rev flips); 2 = circle-vertex
    arb.rev = ptype === 1;
    arb.lnormx = blnx;
    arb.lnormy = blny;
    arb.lproj = blproj;
    arb.radius = r;
    arb.stamp = this.stamp;

    // persist the single hash-0 contact so its jnAcc/jtAcc warm-start
    let c = arb.contacts.find((k) => k.hash === 0);
    if (c == null) {
      c = {
        hash: 0, px, py, dist: cdist,
        lr1x: 0, lr1y: 0, lr2x: 0, lr2y: 0,
        r1x: 0, r1y: 0, r2x: 0, r2y: 0,
        nMass: 0, tMass: 0, bounce: 0, friction: 0, elasticity: 0,
        jnAcc: 0, jtAcc: 0, stamp: this.stamp, active: false, fresh: true, posOnly: false,
      };
      arb.jrAcc = 0;
      arb.contacts.push(c);
    } else {
      c.fresh = false;
    }
    c.px = px;
    c.py = py;
    c.dist = cdist;
    c.stamp = this.stamp;
    c.lr1x = sc.localCOMx; // contact arm on b1 (circle), in its local frame
    c.lr1y = sc.localCOMy;
    c.lr2x = lr2x; // contact arm on b2 (polygon) — the vertex in poly-local (ptype 2)
    c.lr2y = lr2y;
    c.posOnly = false;
    return arb;
  }

  // prestep — per-arbiter contact constraint setup (ZPP_Space.presteparb:4157).
  // Material combine (once), warm-scale, then per active contact: arms r1/r2,
  // effective masses nMass/tMass, restitution bounce, friction selection.
  private prestep(dt: number, only?: Arbiter): void {
    for (const arb of only ? [only] : this.arbiters.values()) {
      if (arb.stamp !== this.stamp) continue;
      const b1 = arb.b1;
      const b2 = arb.b2;
      // [E3] a sleeping arbiter (both bodies asleep — static counts as asleep) is
      // frozen: skip the solve but keep its warm-start impulses for when it wakes.
      if (b1.sleeping && b2.sleeping) { arb.active = false; continue; }
      if (arb.invalidated) {
        arb.invalidated = false;
        // restitution: combined elasticity, clamped to [0,1] (ZPP_Space.as:4115)
        let resti = (arb.s1.elasticity + arb.s2.elasticity) / 2;
        if (resti < 0) resti = 0;
        if (resti > 1) resti = 1;
        arb.restitution = resti;
        // NOTE: our Shape carries one `friction` (used for both dynamic & static,
        // which match in the test material) and `rolling`.
        arb.dyn_fric = combineGeoMean(arb.s1.friction, arb.s2.friction);
        arb.stat_fric = combineGeoMean(arb.s1.friction, arb.s2.friction);
        arb.rfric = combineGeoMean(arb.s1.rolling, arb.s2.rolling);
      }
      if (arb.pre_dt === -1) arb.pre_dt = dt;
      const warmScale = dt / arb.pre_dt;
      arb.pre_dt = dt;
      const loc53 = b1.smass + b2.smass; // inverse-mass sum
      arb.hc2 = false;
      let noContact = true;
      const nonDyn = b1.type !== TYPE_DYNAMIC || b2.type !== TYPE_DYNAMIC;
      arb.biasCoef = nonDyn ? (arb.continuous ? 0.5 : 0.6) : arb.continuous ? 0.4 : 0.3;
      arb.continuous = false;

      for (const c of arb.contacts) {
        c.active = c.stamp === arb.stamp;
        if (!c.active) continue;
        if (noContact) {
          noContact = false;
          arb.c1 = c;
          arb.oc1 = c;
        } else {
          arb.hc2 = true;
          arb.c2 = c;
          arb.oc2 = c;
        }
        c.r2x = c.px - b2.posx;
        c.r2y = c.py - b2.posy;
        c.r1x = c.px - b1.posx;
        c.r1y = c.py - b1.posy;
        // tangent effective mass
        let proj = c.r2x * arb.nx + c.r2y * arb.ny;
        let acc = loc53 + b2.sinertia * (proj * proj);
        proj = c.r1x * arb.nx + c.r1y * arb.ny;
        acc = acc + b1.sinertia * (proj * proj);
        c.tMass = acc < 1e-8 ? 0 : 1 / acc;
        // normal effective mass
        let cr = arb.ny * c.r2x - arb.nx * c.r2y;
        let nacc = loc53 + b2.sinertia * (cr * cr);
        cr = arb.ny * c.r1x - arb.nx * c.r1y;
        nacc = nacc + b1.sinertia * (cr * cr);
        c.nMass = nacc < 1e-8 ? 0 : 1 / nacc;
        // relative normal velocity at the contact → restitution bounce
        let w = b2.angvel + 0; // + kinangvel (0)
        let rvx = b2.velx - c.r2y * w;
        let rvy = b2.vely + c.r2x * w;
        w = b1.angvel + 0;
        rvx -= b1.velx - c.r1y * w;
        rvy -= b1.vely + c.r1x * w;
        w = arb.nx * rvx + arb.ny * rvy;
        c.elasticity = arb.restitution;
        c.bounce = w * c.elasticity;
        if (c.bounce > -20) c.bounce = 0;
        // friction: dynamic above a tangential-speed threshold, else static
        w = rvy * arb.nx - rvx * arb.ny;
        c.friction = w * w > 4 ? arb.dyn_fric : arb.stat_fric;
        c.jnAcc *= warmScale;
        c.jtAcc *= warmScale;
      }

      // hpc2 / posOnly resolution (ZPP_Space.as:4312). hpc2 (2-contact POSITION
      // solver) is enabled whenever there are two contacts; hc2 (2-contact VELOCITY
      // block) is disabled if either contact is position-only (separated) — the
      // penetrating one becomes c1. loc6 = both position-only ⇒ no velocity arms.
      let loc6 = false;
      if (arb.hc2) {
        arb.hpc2 = true;
        if (arb.oc1!.posOnly) {
          const tc = arb.c1; arb.c1 = arb.c2; arb.c2 = tc;
          const to = arb.oc1; arb.oc1 = arb.oc2; arb.oc2 = to;
          arb.hc2 = false;
        } else if (arb.oc2!.posOnly) {
          arb.hc2 = false;
        }
        if (arb.oc1!.posOnly) loc6 = true;
      } else {
        arb.hpc2 = false;
      }
      arb.jrAcc *= warmScale;
      if (!noContact && !loc6) {
        const c1 = arb.c1!;
        arb.rn1a = arb.ny * c1.r1x - arb.nx * c1.r1y;
        arb.rt1a = c1.r1x * arb.nx + c1.r1y * arb.ny;
        arb.rn1b = arb.ny * c1.r2x - arb.nx * c1.r2y;
        arb.rt1b = c1.r2x * arb.nx + c1.r2y * arb.ny;
        arb.k1x = 0; // no kinematic bodies
        arb.k1y = 0;
      }
      if (arb.hc2) {
        // two-contact normal block: arms for c2 and the 2×2 effective-mass matrix
        // K = [[a,b],[b,c]] (ZPP_Space.as:4348). When well-conditioned, store the
        // ORIGINAL K in Ka/Kb/Kc and the INVERSE in kMassa/kMassb/kMassc; when not,
        // drop to the deeper single contact.
        const c2 = arb.c2!;
        arb.rn2a = arb.ny * c2.r1x - arb.nx * c2.r1y;
        arb.rt2a = c2.r1x * arb.nx + c2.r1y * arb.ny;
        arb.rn2b = arb.ny * c2.r2x - arb.nx * c2.r2y;
        arb.rt2b = c2.r2x * arb.nx + c2.r2y * arb.ny;
        arb.k2x = 0;
        arb.k2y = 0;
        arb.kMassa = loc53 + b1.sinertia * arb.rn1a * arb.rn1a + b2.sinertia * arb.rn1b * arb.rn1b;
        arb.kMassb = loc53 + b1.sinertia * arb.rn1a * arb.rn2a + b2.sinertia * arb.rn1b * arb.rn2b;
        arb.kMassc = loc53 + b1.sinertia * arb.rn2a * arb.rn2a + b2.sinertia * arb.rn2b * arb.rn2b;
        if (arb.kMassa * arb.kMassa < 400000 * (arb.kMassa * arb.kMassc - arb.kMassb * arb.kMassb)) {
          arb.Ka = arb.kMassa;
          arb.Kb = arb.kMassb;
          arb.Kc = arb.kMassc;
          let det = arb.kMassa * arb.kMassc - arb.kMassb * arb.kMassb;
          if (det !== det) {
            arb.kMassa = arb.kMassb = arb.kMassc = 0;
          } else if (det === 0) {
            if (arb.kMassa !== 0) arb.kMassa = 1 / arb.kMassa; else arb.kMassa = 0;
            if (arb.kMassc !== 0) arb.kMassc = 1 / arb.kMassc; else arb.kMassc = 0;
            arb.kMassb = 0;
          } else {
            det = 1 / det;
            const t4 = arb.kMassc * det;
            arb.kMassc = arb.kMassa * det;
            arb.kMassa = t4;
            arb.kMassb *= -det;
          }
        } else {
          arb.hc2 = false;
          if (arb.oc2!.dist < arb.oc1!.dist) {
            const tc = arb.c1; arb.c1 = arb.c2; arb.c2 = tc;
          }
          arb.oc2!.active = false;
        }
      }
      // surface velocity (0 here) and rolling effective mass
      arb.surfacex = b2.velx * 0; // b2.svelx (surface velocity) = 0
      arb.surfacey = b2.vely * 0;
      arb.surfacex = -(arb.surfacex + b1.velx * 0);
      arb.surfacey = -(arb.surfacey + b1.vely * 0);
      let rMass = b1.sinertia + b2.sinertia;
      if (rMass !== 0) rMass = 1 / rMass;
      arb.rMass = rMass;
      arb.active = !noContact;
    }
    // constraint preStep (ZPP_Space.prestep:4901) — skipped for the CCD re-solve
    // (only), which presteps just the swept pair's arbiter (ZPP_Space.as:10912).
    if (only == null)
      for (const c of this.constraints) {
        if (c.b1.sleeping && c.b2.sleeping) continue; // [E3] sleeping constraint
        if (c.kind === 'pivot') this.pivotPreStep(c, dt);
        else if (c.kind === 'weld') this.weldPreStep(c, dt);
        else if (c.kind === 'distance') this.distancePreStep(c, dt);
        else if (c.kind === 'angle') this.anglePreStep(c, dt);
        else this.motorPreStep(c, dt);
      }
  }

  // PivotJoint.preStep (ZPP_PivotJoint.as:171) — world anchor arms a1rel/a2rel,
  // the 2×2 effective-mass matrix kMass (inverted), and warm-scale of jAcc.
  // `stiff` (always true here) ⇒ no soft bias/gamma.
  private pivotPreStep(c: PivotJoint, dt: number): void {
    const b1 = c.b1;
    const b2 = c.b2;
    if (c.pre_dt === -1) c.pre_dt = dt;
    const warmScale = dt / c.pre_dt;
    c.pre_dt = dt;
    c.a1relx = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    c.a1rely = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    c.a2relx = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    c.a2rely = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    const m = b1.smass + b2.smass;
    let kMassa = m;
    let kMassb = 0;
    let kMassc = m;
    if (b1.sinertia !== 0) {
      const t4 = c.a1relx * b1.sinertia;
      const t5 = c.a1rely * b1.sinertia;
      kMassa += t5 * c.a1rely;
      kMassb += -t5 * c.a1relx;
      kMassc += t4 * c.a1relx;
    }
    if (b2.sinertia !== 0) {
      const t4 = c.a2relx * b2.sinertia;
      const t5 = c.a2rely * b2.sinertia;
      kMassa += t5 * c.a2rely;
      kMassb += -t5 * c.a2relx;
      kMassc += t4 * c.a2relx;
    }
    let det = kMassa * kMassc - kMassb * kMassb;
    let flag = 0;
    if (det !== det) {
      kMassa = kMassb = kMassc = 0;
      flag = 3;
    } else if (det === 0) {
      if (kMassa !== 0) kMassa = 1 / kMassa;
      else { kMassa = 0; flag |= 1; }
      if (kMassc !== 0) kMassc = 1 / kMassc;
      else { kMassc = 0; flag |= 2; }
      kMassb = 0;
    } else {
      det = 1 / det;
      const t4 = kMassc * det;
      kMassc = kMassa * det;
      kMassa = t4;
      kMassb *= -det;
    }
    c.kMassa = kMassa;
    c.kMassb = kMassb;
    c.kMassc = kMassc;
    if ((flag & 1) !== 0) c.jAccx = 0;
    if ((flag & 2) !== 0) c.jAccy = 0;
    // stiff ⇒ no positional bias in the velocity solve
    c.biasx = 0;
    c.biasy = 0;
    c.gamma = 0;
    c.jAccx *= warmScale;
    c.jAccy *= warmScale;
    c.jMax = Infinity; // maxForce ∞ (no force limit / breaking)
  }

  // warmStart — re-apply each contact's persisted impulse so the solver resumes
  // near last step's solution (ZPP_Space.warmStart:313).
  private warmStart(): void {
    // same order as iterateVel — FP addition isn't associative, so a body shared by
    // several contacts must accumulate its warm-start impulses in Nape's order.
    for (const arb of this.orderedActiveArbiters()) {
      const b1 = arb.b1;
      const b2 = arb.b2;
      const c1 = arb.c1!;
      let jx = arb.nx * c1.jnAcc - arb.ny * c1.jtAcc;
      let jy = arb.ny * c1.jnAcc + arb.nx * c1.jtAcc;
      b1.velx -= jx * b1.imass;
      b1.vely -= jy * b1.imass;
      b1.angvel -= b1.iinertia * (jy * c1.r1x - jx * c1.r1y);
      b2.velx += jx * b2.imass;
      b2.vely += jy * b2.imass;
      b2.angvel += b2.iinertia * (jy * c1.r2x - jx * c1.r2y);
      if (arb.hc2) {
        const c2 = arb.c2!;
        jx = arb.nx * c2.jnAcc - arb.ny * c2.jtAcc;
        jy = arb.ny * c2.jnAcc + arb.nx * c2.jtAcc;
        b1.velx -= jx * b1.imass;
        b1.vely -= jy * b1.imass;
        b1.angvel -= b1.iinertia * (jy * c2.r1x - jx * c2.r1y);
        b2.velx += jx * b2.imass;
        b2.vely += jy * b2.imass;
        b2.angvel += b2.iinertia * (jy * c2.r2x - jx * c2.r2y);
      }
      b2.angvel += arb.jrAcc * b2.iinertia;
      b1.angvel -= arb.jrAcc * b1.iinertia;
    }
    // constraints warm-started after contacts (ZPP_Space.warmStart:351)
    for (const c of this.constraints) {
      if (c.b1.sleeping && c.b2.sleeping) continue; // [E3] sleeping constraint
      const b1 = c.b1;
      const b2 = c.b2;
      if (c.kind === 'distance') {
        // 1-DOF impulse along the constraint direction (ZPP_DistanceJoint.warmStart:99)
        if (!c.slack) {
          let j = b1.imass * c.jAcc;
          b1.velx -= c.nx * j;
          b1.vely -= c.ny * j;
          j = b2.imass * c.jAcc;
          b2.velx += c.nx * j;
          b2.vely += c.ny * j;
          b1.angvel -= c.cx1 * b1.iinertia * c.jAcc;
          b2.angvel += c.cx2 * b2.iinertia * c.jAcc;
        }
        continue;
      }
      if (c.kind === 'angle') {
        // pure angular impulse (ZPP_AngleJoint.warmStart:65)
        if (!c.slack) {
          b1.angvel -= c.scale * b1.iinertia * c.jAcc;
          b2.angvel += c.ratio * c.scale * b2.iinertia * c.jAcc;
        }
        continue;
      }
      if (c.kind === 'motor') {
        // pure angular impulse, always active (ZPP_MotorJoint.warmStart:47)
        b1.angvel -= b1.iinertia * c.jAcc;
        b2.angvel += c.ratio * b2.iinertia * c.jAcc;
        continue;
      }
      // pivot/weld: linear impulse (jAccx, jAccy) + (weld) angular jAccz
      b1.velx -= c.jAccx * b1.imass;
      b1.vely -= c.jAccy * b1.imass;
      b2.velx += c.jAccx * b2.imass;
      b2.vely += c.jAccy * b2.imass;
      const az = c.kind === 'weld' ? c.jAccz : 0;
      b1.angvel -= (c.jAccy * c.a1relx - c.jAccx * c.a1rely + az) * b1.iinertia;
      b2.angvel += (c.jAccy * c.a2relx - c.jAccx * c.a2rely + az) * b2.iinertia;
    }
  }

  // iterateVel — sequential impulse, `velIters` sweeps (ZPP_Space.iterateVel:8222).
  // Single-contact path: tangent friction, then rolling friction, then the
  // non-penetration normal impulse, each accumulated and clamped.
  private iterateVel(iters: number, only?: Arbiter): void {
    const ordered = only ? [only] : this.orderedActiveArbiters();
    for (let it = 0; it < iters; it++) {
      // constraints solve before contacts each sweep (ZPP_Space.iterateVel:8292) —
      // skipped for the CCD re-solve (only), which solves just the swept arbiter.
      if (only == null)
        for (const c of this.constraints) {
          if (c.b1.sleeping && c.b2.sleeping) continue; // [E3] sleeping constraint
          if (c.kind === 'pivot') this.pivotApplyImpulseVel(c);
          else if (c.kind === 'weld') this.weldApplyImpulseVel(c);
          else if (c.kind === 'distance') this.distanceApplyImpulseVel(c);
          else if (c.kind === 'angle') this.angleApplyImpulseVel(c);
          else this.motorApplyImpulseVel(c);
        }
      for (const arb of ordered) {
        const b1 = arb.b1;
        const b2 = arb.b2;
        const c1 = arb.c1!;
        // --- tangent friction (always, before the normal solve) ---
        let rvx = arb.k1x + b2.velx - c1.r2y * b2.angvel - (b1.velx - c1.r1y * b1.angvel);
        let rvy = arb.k1y + b2.vely + c1.r2x * b2.angvel - (b1.vely + c1.r1x * b1.angvel);
        let j = (rvy * arb.nx - rvx * arb.ny + arb.surfacex) * c1.tMass;
        let maxf = c1.friction * c1.jnAcc;
        let old = c1.jtAcc;
        let nw = old - j;
        if (nw > maxf) nw = maxf;
        else if (nw < -maxf) nw = -maxf;
        j = nw - old;
        c1.jtAcc = nw;
        let ix = -arb.ny * j;
        let iy = arb.nx * j;
        b2.velx += ix * b2.imass;
        b2.vely += iy * b2.imass;
        b1.velx -= ix * b1.imass;
        b1.vely -= iy * b1.imass;
        b2.angvel += arb.rt1b * j * b2.iinertia;
        b1.angvel -= arb.rt1a * j * b1.iinertia;
        if (arb.hc2) {
          // === two-contact block (ZPP_Space.as:8363) ===
          const c2 = arb.c2!;
          // c2 tangent friction
          let rvx2 = arb.k2x + b2.velx - c2.r2y * b2.angvel - (b1.velx - c2.r1y * b1.angvel);
          let rvy2 = arb.k2y + b2.vely + c2.r2x * b2.angvel - (b1.vely + c2.r1x * b1.angvel);
          let j2 = (rvy2 * arb.nx - rvx2 * arb.ny + arb.surfacex) * c2.tMass;
          const maxf2 = c2.friction * c2.jnAcc;
          const old2 = c2.jtAcc;
          let nw2 = old2 - j2;
          if (nw2 > maxf2) nw2 = maxf2;
          else if (nw2 < -maxf2) nw2 = -maxf2;
          j2 = nw2 - old2;
          c2.jtAcc = nw2;
          const ix2 = -arb.ny * j2;
          const iy2 = arb.nx * j2;
          b2.velx += ix2 * b2.imass;
          b2.vely += iy2 * b2.imass;
          b1.velx -= ix2 * b1.imass;
          b1.vely -= iy2 * b1.imass;
          b2.angvel += arb.rt2b * j2 * b2.iinertia;
          b1.angvel -= arb.rt2a * j2 * b1.iinertia;
          // normal block LCP — solve both contacts' non-penetration together
          const r18 = arb.k1x + b2.velx - c1.r2y * b2.angvel - (b1.velx - c1.r1y * b1.angvel);
          const r19 = arb.k1y + b2.vely + c1.r2x * b2.angvel - (b1.vely + c1.r1x * b1.angvel);
          const r20 = arb.k2x + b2.velx - c2.r2y * b2.angvel - (b1.velx - c2.r1y * b1.angvel);
          const r21 = arb.k2y + b2.vely + c2.r2x * b2.angvel - (b1.vely + c2.r1x * b1.angvel);
          const j1n = c1.jnAcc; // loc22
          const j2n = c2.jnAcc; // loc23
          const b24 = r18 * arb.nx + r19 * arb.ny + arb.surfacey + c1.bounce - (arb.Ka * j1n + arb.Kb * j2n);
          const b25 = r20 * arb.nx + r21 * arb.ny + arb.surfacey + c2.bounce - (arb.Kb * j1n + arb.Kc * j2n);
          const x26 = -(arb.kMassa * b24 + arb.kMassb * b25);
          const x27 = -(arb.kMassb * b24 + arb.kMassc * b25);
          let d24: number;
          let d25: number;
          if (x26 >= 0 && x27 >= 0) {
            d24 = x26 - j1n;
            d25 = x27 - j2n;
            c1.jnAcc = x26;
            c2.jnAcc = x27;
          } else {
            const y26 = -c1.nMass * b24;
            if (y26 >= 0 && arb.Kb * y26 + b25 >= 0) {
              d24 = y26 - j1n;
              d25 = -j2n;
              c1.jnAcc = y26;
              c2.jnAcc = 0;
            } else {
              const y27 = -c2.nMass * b25;
              if (y27 >= 0 && arb.Kb * y27 + b24 >= 0) {
                d24 = -j1n;
                d25 = y27 - j2n;
                c1.jnAcc = 0;
                c2.jnAcc = y27;
              } else if (b24 >= 0 && b25 >= 0) {
                d24 = -j1n;
                d25 = -j2n;
                c1.jnAcc = 0;
                c2.jnAcc = 0;
              } else {
                d24 = 0;
                d25 = 0;
              }
            }
          }
          const tot = d24 + d25;
          const ixn = arb.nx * tot;
          const iyn = arb.ny * tot;
          b2.velx += ixn * b2.imass;
          b2.vely += iyn * b2.imass;
          b1.velx -= ixn * b1.imass;
          b1.vely -= iyn * b1.imass;
          b2.angvel += (arb.rn1b * d24 + arb.rn2b * d25) * b2.iinertia;
          b1.angvel -= (arb.rn1a * d24 + arb.rn2a * d25) * b1.iinertia;
        } else {
          // === single contact (ZPP_Space.as:8449) ===
          // --- rolling friction (circle radius ≠ 0) ---
          if (arb.radius !== 0) {
            const rel = b2.angvel - b1.angvel;
            j = rel * arb.rMass;
            maxf = arb.rfric * c1.jnAcc;
            old = arb.jrAcc;
            arb.jrAcc -= j;
            if (arb.jrAcc > maxf) arb.jrAcc = maxf;
            else if (arb.jrAcc < -maxf) arb.jrAcc = -maxf;
            j = arb.jrAcc - old;
            b2.angvel += j * b2.iinertia;
            b1.angvel -= j * b1.iinertia;
          }
          // --- normal (non-penetration) impulse ---
          rvx = arb.k1x + b2.velx - c1.r2y * b2.angvel - (b1.velx - c1.r1y * b1.angvel);
          rvy = arb.k1y + b2.vely + c1.r2x * b2.angvel - (b1.vely + c1.r1x * b1.angvel);
          j = (c1.bounce + (arb.nx * rvx + arb.ny * rvy) + arb.surfacey) * c1.nMass;
          old = c1.jnAcc;
          nw = old - j;
          if (nw < 0) nw = 0;
          j = nw - old;
          c1.jnAcc = nw;
          ix = arb.nx * j;
          iy = arb.ny * j;
          b2.velx += ix * b2.imass;
          b2.vely += iy * b2.imass;
          b1.velx -= ix * b1.imass;
          b1.vely -= iy * b1.imass;
          b2.angvel += arb.rn1b * j * b2.iinertia;
          b1.angvel -= arb.rn1a * j * b1.iinertia;
        }
      }
    }
  }

  // iteratePos — split-impulse position correction, `posIters` sweeps
  // (ZPP_Space.iteratePos:8501). Reconstructs world normal + contact point from
  // the bodies' CURRENT transforms each iteration (they move as we correct),
  // then pushes apart by biasCoef·penetration, leaving a 0.2 slop.
  private iteratePos(iters: number): void {
    const ordered = this.orderedActiveArbiters();
    for (let it = 0; it < iters; it++) {
      // stiff constraints corrected before contacts each sweep (ZPP_Space.iteratePos:8553)
      for (const c of this.constraints) {
        if (c.b1.sleeping && c.b2.sleeping) continue; // [E3] sleeping constraint
        if (c.kind === 'pivot') this.pivotApplyImpulsePos(c);
        else if (c.kind === 'weld') this.weldApplyImpulsePos(c);
        else if (c.kind === 'distance') this.distanceApplyImpulsePos(c);
        else if (c.kind === 'angle') this.angleApplyImpulsePos(c);
        // motor: no position correction (ZPP_MotorJoint.applyImpulsePos returns false)
      }
      for (const arb of ordered) {
        const b1 = arb.b1;
        const b2 = arb.b2;
        const c1 = arb.c1!;
        if (arb.ptype === 2) {
          this.iteratePosVertex(arb, c1);
          continue;
        }
        // Reconstruct the reference-face world normal (loc11,loc12) + projection
        // (loc13) and each contact point from its lr1 in the incident body's frame,
        // from the bodies' CURRENT transforms (ZPP_Space.as:8707). ptype 0: ref = b1,
        // incident = b2; ptype 1: ref = b2, incident = b1. hpc2 ⇒ a second contact.
        const c2 = arb.hpc2 ? arb.c2! : null;
        let nlx: number;
        let nly: number;
        let proj: number;
        let cx: number;
        let cy: number;
        let c2x = 0;
        let c2y = 0;
        if (arb.ptype === 0) {
          nlx = b1.axisy * arb.lnormx - b1.axisx * arb.lnormy;
          nly = arb.lnormx * b1.axisx + arb.lnormy * b1.axisy;
          proj = arb.lproj + (nlx * b1.posx + nly * b1.posy);
          cx = b2.axisy * c1.lr1x - b2.axisx * c1.lr1y + b2.posx;
          cy = c1.lr1x * b2.axisx + c1.lr1y * b2.axisy + b2.posy;
          if (c2 !== null) {
            c2x = b2.axisy * c2.lr1x - b2.axisx * c2.lr1y + b2.posx;
            c2y = c2.lr1x * b2.axisx + c2.lr1y * b2.axisy + b2.posy;
          }
        } else {
          nlx = b2.axisy * arb.lnormx - b2.axisx * arb.lnormy;
          nly = arb.lnormx * b2.axisx + arb.lnormy * b2.axisy;
          proj = arb.lproj + (nlx * b2.posx + nly * b2.posy);
          cx = b1.axisy * c1.lr1x - b1.axisx * c1.lr1y + b1.posx;
          cy = c1.lr1x * b1.axisx + c1.lr1y * b1.axisy + b1.posy;
          if (c2 !== null) {
            c2x = b1.axisy * c2.lr1x - b1.axisx * c2.lr1y + b1.posx;
            c2y = c2.lr1x * b1.axisx + c2.lr1y * b1.axisy + b1.posy;
          }
        }
        let sep = cx * nlx + cy * nly - proj - arb.radius;
        sep = sep + 0.2; // resting slop
        let sep2 = 0;
        if (c2 !== null) {
          sep2 = c2x * nlx + c2y * nly - proj - arb.radius + 0.2;
        }
        if (sep < 0 || sep2 < 0) {
          if (arb.rev) {
            nlx = -nlx;
            nly = -nly;
          }
          const a1x = cx - b1.posx;
          const a1y = cy - b1.posy;
          const a2x = cx - b2.posx;
          const a2y = cy - b2.posy;
          if (c2 !== null) {
            // === two-contact block position solve (ZPP_Space.as:8772) ===
            const a1px = c2x - b1.posx;
            const a1py = c2y - b1.posy;
            const a2px = c2x - b2.posx;
            const a2py = c2y - b2.posy;
            const cr11 = nly * a1x - nlx * a1y; // loc28 (c1 on b1)
            const cr12 = nly * a2x - nlx * a2y; // loc29 (c1 on b2)
            const cr21 = nly * a1px - nlx * a1py; // loc30 (c2 on b1)
            const cr22 = nly * a2px - nlx * a2py; // loc31 (c2 on b2)
            const m = b1.smass + b2.smass;
            const kma = m + b1.sinertia * cr11 * cr11 + b2.sinertia * cr12 * cr12;
            const kmb = m + b1.sinertia * cr11 * cr21 + b2.sinertia * cr12 * cr22;
            const kmc = m + b1.sinertia * cr21 * cr21 + b2.sinertia * cr22 * cr22;
            const bs1 = sep * arb.biasCoef; // loc37
            const bs2 = sep2 * arb.biasCoef; // loc38
            let l39 = -bs1;
            let l40 = -bs2;
            let apply = false;
            const det = kma * kmc - kmb * kmb;
            if (det !== det) {
              l39 = 0;
              l40 = 0;
            } else if (det === 0) {
              l39 = kma !== 0 ? l39 / kma : 0;
              l40 = kmc !== 0 ? l40 / kmc : 0;
            } else {
              const id = 1 / det;
              const t4 = id * (kmc * l39 - kmb * l40);
              l40 = id * (kma * l40 - kmb * l39);
              l39 = t4;
            }
            if (l39 >= 0 && l40 >= 0) {
              apply = true;
            } else {
              l39 = -bs1 / kma;
              l40 = 0;
              if (l39 >= 0 && kmb * l39 + bs2 >= 0) {
                apply = true;
              } else {
                l39 = 0;
                l40 = -bs2 / kmc;
                if (l40 >= 0 && kmb * l40 + bs1 >= 0) apply = true;
              }
            }
            if (apply) {
              const lin1 = (l39 + l40) * b1.imass;
              b1.posx -= nlx * lin1;
              b1.posy -= nly * lin1;
              this.applyPosRotation(b1, -b1.iinertia * (cr11 * l39 + cr21 * l40));
              const lin2 = (l39 + l40) * b2.imass;
              b2.posx += nlx * lin2;
              b2.posy += nly * lin2;
              this.applyPosRotation(b2, b2.iinertia * (cr12 * l39 + cr22 * l40));
            }
          } else {
            const cr1 = nly * a1x - nlx * a1y;
            const cr2 = nly * a2x - nlx * a2y;
            const denom = b2.smass + cr2 * cr2 * b2.sinertia + b1.smass + cr1 * cr1 * b1.sinertia;
            if (denom !== 0) {
              const lambda = (-arb.biasCoef * sep) / denom;
              const dx = nlx * lambda;
              const dy = nly * lambda;
              b1.posx -= dx * b1.imass;
              b1.posy -= dy * b1.imass;
              this.applyPosRotation(b1, -cr1 * b1.iinertia * lambda);
              b2.posx += dx * b2.imass;
              b2.posy += dy * b2.imass;
              this.applyPosRotation(b2, cr2 * b2.iinertia * lambda);
            }
          }
        }
      }
    }
  }

  // [P0a] iteratePos for a circle-vertex contact (ptype 2, ZPP_Space.as:8601).
  // Reconstructs the polygon vertex (lr2 in b2's frame) and the circle centre (lr1
  // in b1's frame) from current transforms, then pushes them to the target
  // separation (radius − 0.2) along their connecting line via the fast-inv-sqrt distance.
  private iteratePosVertex(arb: Arbiter, c1: SolverContact): void {
    const b1 = arb.b1;
    const b2 = arb.b2;
    const p2x = b2.axisy * c1.lr2x - b2.axisx * c1.lr2y + b2.posx;
    const p2y = c1.lr2x * b2.axisx + c1.lr2y * b2.axisy + b2.posy;
    const p1x = b1.axisy * c1.lr1x - b1.axisx * c1.lr1y + b1.posx;
    const p1y = c1.lr1x * b1.axisx + c1.lr1y * b1.axisy + b1.posy;
    let dx = p2x - p1x;
    let dy = p2y - p1y;
    const d2 = dx * dx + dy * dy;
    const dist = d2 === 0 ? 0 : 1 / fastInvSqrt(d2);
    const target = arb.radius - 0.2;
    let sep = dist - target;
    if (dx * arb.nx + dy * arb.ny < 0) {
      dx = -dx;
      dy = -dy;
      sep -= arb.radius;
    }
    if (sep >= 0) return;
    if (dist < 1e-8) {
      if (b1.smass !== 0) b1.posx += 1e-7;
      else b2.posx += 1e-7;
      return;
    }
    const inv = 1 / dist;
    dx *= inv;
    dy *= inv;
    const mx = 0.5 * (p1x + p2x);
    const my = 0.5 * (p1y + p2y);
    const err = dist - target;
    const cr1 = dy * (mx - b1.posx) - dx * (my - b1.posy);
    const cr2 = dy * (mx - b2.posx) - dx * (my - b2.posy);
    const denom = b2.smass + cr2 * cr2 * b2.sinertia + b1.smass + cr1 * cr1 * b1.sinertia;
    if (denom === 0) return;
    const lambda = (-arb.biasCoef * err) / denom;
    const ix = dx * lambda;
    const iy = dy * lambda;
    b1.posx -= ix * b1.imass;
    b1.posy -= iy * b1.imass;
    this.applyPosRotation(b1, -cr1 * b1.iinertia * lambda);
    b2.posx += ix * b2.imass;
    b2.posy += iy * b2.imass;
    this.applyPosRotation(b2, cr2 * b2.iinertia * lambda);
  }

  // Position-solver rotation update: advance rot and sync axis with the same
  // small-angle path the original uses (ZPP_Space.as:8667 et al).
  private applyPosRotation(b: Body, dr: number): void {
    b.rot += dr;
    if (dr * dr > 0.0001) {
      b.axisx = Math.sin(b.rot);
      b.axisy = Math.cos(b.rot);
    } else {
      const d2 = dr * dr;
      const p = 1 - 0.5 * d2;
      const mm = 1 - (d2 * d2) / 8;
      const nx = (p * b.axisx + dr * b.axisy) * mm;
      b.axisy = (p * b.axisy - dr * b.axisx) * mm;
      b.axisx = nx;
    }
  }

  // PivotJoint.applyImpulseVel (ZPP_PivotJoint.as:637). Drives the relative
  // velocity at the anchor to zero via the kMass matrix; jAcc accumulates.
  // `stiff` + infinite maxForce ⇒ no clamp/break.
  private pivotApplyImpulseVel(c: PivotJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const rel1 = b2.velx - c.a2rely * b2.angvel - (b1.velx - c.a1rely * b1.angvel);
    const rel2 = b2.vely + c.a2relx * b2.angvel - (b1.vely + c.a1relx * b1.angvel);
    let d3 = c.biasx - rel1;
    let d4 = c.biasy - rel2;
    const d5 = c.kMassa * d3 + c.kMassb * d4;
    d4 = c.kMassb * d3 + c.kMassc * d4;
    d3 = d5;
    d3 -= c.jAccx * c.gamma;
    d4 -= c.jAccy * c.gamma;
    const ox = c.jAccx;
    const oy = c.jAccy;
    c.jAccx += d3;
    c.jAccy += d4;
    d3 = c.jAccx - ox;
    d4 = c.jAccy - oy;
    b1.velx -= d3 * b1.imass;
    b1.vely -= d4 * b1.imass;
    b2.velx += d3 * b2.imass;
    b2.vely += d4 * b2.imass;
    b1.angvel -= (d4 * c.a1relx - d3 * c.a1rely) * b1.iinertia;
    b2.angvel += (d4 * c.a2relx - d3 * c.a2rely) * b2.iinertia;
  }

  // PivotJoint.applyImpulsePos (ZPP_PivotJoint.as:693) — split-impulse position
  // correction: re-derive the world anchors from current transforms, pull them
  // together by half the error (with a large-error pre-shift and length clamps
  // via fast-inv-sqrt), distributing through the kMass matrix.
  private pivotApplyImpulsePos(c: PivotJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const l1 = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    const l2 = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    const l3 = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    const l4 = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    let l5 = b2.posx + l3 - (b1.posx + l1);
    let l6 = b2.posy + l4 - (b1.posy + l2);
    if (l5 * l5 + l6 * l6 < 0.01) return;
    l5 *= 0.5;
    l6 *= 0.5;
    if (l5 * l5 + l6 * l6 > 6) {
      let m = b1.smass + b2.smass;
      if (m > 1e-8) {
        m = 0.75 / m;
        let q7 = -l5 * m;
        let q8 = -l6 * m;
        const lsq = q7 * q7 + q8 * q8;
        if (lsq > 20 * 20) {
          const sc = 20 * fastInvSqrt(lsq);
          q7 *= sc;
          q8 *= sc;
        }
        b1.posx -= q7 * b1.imass;
        b1.posy -= q8 * b1.imass;
        b2.posx += q7 * b2.imass;
        b2.posy += q8 * b2.imass;
        l5 = b2.posx + l3 - (b1.posx + l1);
        l6 = b2.posy + l4 - (b1.posy + l2);
        l5 *= 0.5;
        l6 *= 0.5;
      }
    }
    let m9 = b1.smass + b2.smass;
    let m11 = 0;
    let m12 = m9;
    if (b1.sinertia !== 0) {
      const t14 = l1 * b1.sinertia;
      const t15 = l2 * b1.sinertia;
      m9 += t15 * l2;
      m11 += -t15 * l1;
      m12 += t14 * l1;
    }
    if (b2.sinertia !== 0) {
      const t14 = l3 * b2.sinertia;
      const t15 = l4 * b2.sinertia;
      m9 += t15 * l4;
      m11 += -t15 * l3;
      m12 += t14 * l3;
    }
    let p7 = -l5;
    let p8 = -l6;
    const psq = p7 * p7 + p8 * p8;
    if (psq > 6 * 6) {
      const sc = 6 * fastInvSqrt(psq);
      p7 *= sc;
      p8 *= sc;
    }
    let det = m9 * m12 - m11 * m11;
    if (det !== det) {
      p7 = 0;
      p8 = 0;
    } else if (det === 0) {
      p7 = m9 !== 0 ? p7 / m9 : 0;
      p8 = m12 !== 0 ? p8 / m12 : 0;
    } else {
      det = 1 / det;
      const t14 = det * (m12 * p7 - m11 * p8);
      p8 = det * (m9 * p8 - m11 * p7);
      p7 = t14;
    }
    b1.posx -= p7 * b1.imass;
    b1.posy -= p8 * b1.imass;
    b2.posx += p7 * b2.imass;
    b2.posy += p8 * b2.imass;
    this.applyPosRotation(b1, -(p8 * l1 - p7 * l2) * b1.iinertia);
    this.applyPosRotation(b2, (p8 * l3 - p7 * l4) * b2.iinertia);
  }

  // WeldJoint.preStep (ZPP_WeldJoint.as:191) — builds the symmetric 3×3 effective
  // mass [a b c; b d e; c e f] (point + angular DOFs) and inverts it (cofactors).
  // `stiff` ⇒ no soft bias/gamma; jAcc(x,y,z) warm-scaled.
  private weldPreStep(c: WeldJoint, dt: number): void {
    const b1 = c.b1;
    const b2 = c.b2;
    if (c.pre_dt === -1) c.pre_dt = dt;
    const warmScale = dt / c.pre_dt;
    c.pre_dt = dt;
    c.a1relx = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    c.a1rely = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    c.a2relx = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    c.a2rely = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    const m = b1.smass + b2.smass;
    let a = m;
    let b = 0;
    let d = m;
    let cM = 0;
    let e = 0;
    let f = 0;
    if (b1.sinertia !== 0) {
      const t4 = c.a1relx * b1.sinertia;
      const t5 = c.a1rely * b1.sinertia;
      a += t5 * c.a1rely;
      b += -t5 * c.a1relx;
      d += t4 * c.a1relx;
      cM += -t5;
      e += t4;
      f += b1.sinertia;
    }
    if (b2.sinertia !== 0) {
      const t4 = c.a2relx * b2.sinertia;
      const t5 = c.a2rely * b2.sinertia;
      a += t5 * c.a2rely;
      b += -t5 * c.a2relx;
      d += t4 * c.a2relx;
      cM += -t5;
      e += t4;
      f += b2.sinertia;
    }
    let det = a * (d * f - e * e) + b * (cM * e - b * f) + cM * (b * e - cM * d);
    let flag = 0;
    if (det !== det) {
      a = b = d = cM = e = f = 0;
      flag = 7;
    } else if (det === 0) {
      if (a !== 0) a = 1 / a;
      else { a = 0; flag |= 1; }
      if (d !== 0) d = 1 / d;
      else { d = 0; flag |= 2; }
      if (f !== 0) f = 1 / f;
      else { f = 0; flag |= 4; }
      b = cM = e = 0;
    } else {
      det = 1 / det;
      const na = det * (d * f - e * e);
      const nb = det * (e * cM - b * f);
      const nd = det * (a * f - cM * cM);
      const nc = det * (b * e - cM * d);
      const ne = det * (b * cM - a * e);
      const nf = det * (a * d - b * b);
      a = na;
      b = nb;
      d = nd;
      cM = nc;
      e = ne;
      f = nf;
    }
    c.kMassa = a;
    c.kMassb = b;
    c.kMassd = d;
    c.kMassc = cM;
    c.kMasse = e;
    c.kMassf = f;
    if ((flag & 1) !== 0) c.jAccx = 0;
    if ((flag & 2) !== 0) c.jAccy = 0;
    if ((flag & 4) !== 0) c.jAccz = 0;
    c.biasx = 0;
    c.biasy = 0;
    c.biasz = 0;
    c.gamma = 0;
    c.jAccx *= warmScale;
    c.jAccy *= warmScale;
    c.jAccz *= warmScale;
    c.jMax = Infinity;
  }

  // WeldJoint.applyImpulseVel (ZPP_WeldJoint.as:769): drive the relative anchor
  // velocity AND relative angular velocity to zero through the 3×3 inverse.
  private weldApplyImpulseVel(c: WeldJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const rel1 = b2.velx - c.a2rely * b2.angvel - (b1.velx - c.a1rely * b1.angvel);
    const rel2 = b2.vely + c.a2relx * b2.angvel - (b1.vely + c.a1relx * b1.angvel);
    const rel3 = b2.angvel - b1.angvel;
    let r4 = c.biasx - rel1;
    let r5 = c.biasy - rel2;
    let r6 = c.biasz - rel3;
    const s7 = c.kMassa * r4 + c.kMassb * r5 + c.kMassc * r6;
    const s8 = c.kMassb * r4 + c.kMassd * r5 + c.kMasse * r6;
    r6 = c.kMassc * r4 + c.kMasse * r5 + c.kMassf * r6;
    r4 = s7;
    r5 = s8;
    r4 -= c.jAccx * c.gamma;
    r5 -= c.jAccy * c.gamma;
    r6 -= c.jAccz * c.gamma;
    const ox = c.jAccx;
    const oy = c.jAccy;
    const oz = c.jAccz;
    c.jAccx += r4;
    c.jAccy += r5;
    c.jAccz += r6;
    r4 = c.jAccx - ox;
    r5 = c.jAccy - oy;
    r6 = c.jAccz - oz;
    b1.velx -= r4 * b1.imass;
    b1.vely -= r5 * b1.imass;
    b2.velx += r4 * b2.imass;
    b2.vely += r5 * b2.imass;
    b1.angvel -= (r5 * c.a1relx - r4 * c.a1rely + r6) * b1.iinertia;
    b2.angvel += (r5 * c.a2relx - r4 * c.a2rely + r6) * b2.iinertia;
  }

  // WeldJoint.applyImpulsePos (ZPP_WeldJoint.as:835): split-impulse correction of
  // the 3-DOF error (point + angle). The angular error is clamped to ±0.25 rad
  // (the assignment the decompiler dropped at lines 958–970) before the 3×3 solve.
  private weldApplyImpulsePos(c: WeldJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const l1 = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    const l2 = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    const l3 = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    const l4 = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    let l5 = b2.posx + l3 - (b1.posx + l1);
    let l6 = b2.posy + l4 - (b1.posy + l2);
    let l7 = b2.rot - b1.rot - c.phase;
    let active = true;
    if (l5 * l5 + l6 * l6 < 0.01) {
      active = false;
      l5 = 0;
      l6 = 0;
    }
    if (l7 * l7 < 0.000001) {
      if (!active) return;
      l7 = 0;
    }
    l5 *= 0.5;
    l6 *= 0.5;
    l7 *= 0.5;
    if (l5 * l5 + l6 * l6 > 6) {
      let mm = b1.smass + b2.smass;
      if (mm > 1e-8) {
        mm = 0.75 / mm;
        let q8 = -l5 * mm;
        let q9 = -l6 * mm;
        const lsq = q8 * q8 + q9 * q9;
        if (lsq > 20 * 20) {
          const sc = 20 * fastInvSqrt(lsq);
          q8 *= sc;
          q9 *= sc;
        }
        b1.posx -= q8 * b1.imass;
        b1.posy -= q9 * b1.imass;
        b2.posx += q8 * b2.imass;
        b2.posy += q9 * b2.imass;
        l5 = b2.posx + l3 - (b1.posx + l1);
        l6 = b2.posy + l4 - (b1.posy + l2);
        l7 = b2.rot - b1.rot - c.phase;
        l5 *= 0.5;
        l6 *= 0.5;
        l7 *= 0.5;
      }
    }
    let A = b1.smass + b2.smass;
    let B = 0;
    let D = A;
    let C = 0;
    let E = 0;
    let F = 0;
    if (b1.sinertia !== 0) {
      const t20 = l1 * b1.sinertia;
      const t21 = l2 * b1.sinertia;
      A += t21 * l2;
      B += -t21 * l1;
      D += t20 * l1;
      C += -t21;
      E += t20;
      F += b1.sinertia;
    }
    if (b2.sinertia !== 0) {
      const t20 = l3 * b2.sinertia;
      const t21 = l4 * b2.sinertia;
      A += t21 * l4;
      B += -t21 * l3;
      D += t20 * l3;
      C += -t21;
      E += t20;
      F += b2.sinertia;
    }
    let p8 = -l5;
    let p9 = -l6;
    let p10 = -l7;
    const psq = p8 * p8 + p9 * p9;
    if (psq > 6 * 6) {
      const sc = 6 * fastInvSqrt(psq);
      p8 *= sc;
      p9 *= sc;
    }
    if (p10 < -0.25) p10 = -0.25;
    else if (p10 > 0.25) p10 = 0.25;
    let det = A * (D * F - E * E) + B * (C * E - B * F) + C * (B * E - C * D);
    if (det !== det) {
      p8 = p9 = p10 = 0;
    } else if (det === 0) {
      p8 = A !== 0 ? p8 / A : 0;
      p9 = D !== 0 ? p9 / D : 0;
      p10 = F !== 0 ? p10 / F : 0;
    } else {
      det = 1 / det;
      const co20 = E * C - B * F;
      const co21 = B * E - C * D;
      const co22 = B * C - A * E;
      const r23 = det * (p8 * (D * F - E * E) + p9 * co20 + p10 * co21);
      const r24 = det * (p8 * co20 + p9 * (A * F - C * C) + p10 * co22);
      p10 = det * (p8 * co21 + p9 * co22 + p10 * (A * D - B * B));
      p8 = r23;
      p9 = r24;
    }
    b1.posx -= p8 * b1.imass;
    b1.posy -= p9 * b1.imass;
    b2.posx += p8 * b2.imass;
    b2.posy += p9 * b2.imass;
    this.applyPosRotation(b1, -(p9 * l1 - p8 * l2 + p10) * b1.iinertia);
    this.applyPosRotation(b2, (p9 * l3 - p8 * l4 + p10) * b2.iinertia);
  }

  // Distance direction + signed range error from a separation vector (sx,sy),
  // shared by preStep and applyImpulsePos (ZPP_DistanceJoint.as:202-244). Distance
  // via 1/fastInvSqrt(d²); returns the (possibly flipped) unit direction, the error
  // (distance beyond the active bound), and whether the joint is slack (in range).
  private distanceDir(c: DistanceJoint, sx: number, sy: number): { nx: number; ny: number; err: number; slack: boolean } {
    const distSq = sx * sx + sy * sy;
    if (distSq < 1e-8) return { nx: 0, ny: 0, err: 0, slack: true };
    const dist = 1 / fastInvSqrt(distSq);
    const inv = 1 / dist;
    const nx = sx * inv;
    const ny = sy * inv;
    if (c.equal) return { nx, ny, err: dist - c.jointMax, slack: false };
    if (dist < c.jointMin) return { nx: -nx, ny: -ny, err: c.jointMin - dist, slack: false };
    if (dist > c.jointMax) return { nx, ny, err: dist - c.jointMax, slack: false };
    return { nx: 0, ny: 0, err: 0, slack: true };
  }

  // DistanceJoint.preStep (ZPP_DistanceJoint.as:185): anchor arms, constraint
  // direction + range, the 1-DOF effective mass kMass, warm-scale of jAcc.
  private distancePreStep(c: DistanceJoint, dt: number): void {
    const b1 = c.b1;
    const b2 = c.b2;
    if (c.pre_dt === -1) c.pre_dt = dt;
    const warmScale = dt / c.pre_dt;
    c.pre_dt = dt;
    c.equal = c.jointMin === c.jointMax;
    c.a1relx = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    c.a1rely = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    c.a2relx = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    c.a2rely = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    const sx = b2.posx + c.a2relx - (b1.posx + c.a1relx);
    const sy = b2.posy + c.a2rely - (b1.posy + c.a1rely);
    const dir = this.distanceDir(c, sx, sy);
    c.nx = dir.nx;
    c.ny = dir.ny;
    c.slack = dir.slack;
    if (!c.slack) {
      c.cx1 = c.ny * c.a1relx - c.nx * c.a1rely;
      c.cx2 = c.ny * c.a2relx - c.nx * c.a2rely;
      let kMass = b1.smass + b2.smass + c.cx1 * c.cx1 * b1.sinertia + c.cx2 * c.cx2 * b2.sinertia;
      if (kMass !== 0) kMass = 1 / kMass;
      else c.jAcc = 0;
      c.kMass = kMass;
      c.bias = 0; // stiff
      c.gamma = 0;
      c.jAcc *= warmScale;
      c.jMax = Infinity;
    }
  }

  // DistanceJoint.applyImpulseVel (ZPP_DistanceJoint.as:652): drive the relative
  // velocity along the constraint direction to (bias=)0. For a rope (!equal) the
  // accumulated impulse is clamped non-positive (it can only pull inward).
  private distanceApplyImpulseVel(c: DistanceJoint): void {
    if (c.slack) return;
    const b1 = c.b1;
    const b2 = c.b2;
    const rel = c.nx * (b2.velx - b1.velx) + c.ny * (b2.vely - b1.vely) + b2.angvel * c.cx2 - b1.angvel * c.cx1;
    let dj = c.kMass * (c.bias - rel) - c.jAcc * c.gamma;
    const old = c.jAcc;
    c.jAcc += dj;
    if (!c.equal && c.jAcc > 0) c.jAcc = 0;
    dj = c.jAcc - old;
    let j = b1.imass * dj;
    b1.velx -= c.nx * j;
    b1.vely -= c.ny * j;
    j = b2.imass * dj;
    b2.velx += c.nx * j;
    b2.vely += c.ny * j;
    b1.angvel -= c.cx1 * b1.iinertia * dj;
    b2.angvel += c.cx2 * b2.iinertia * dj;
  }

  // DistanceJoint.applyImpulsePos (ZPP_DistanceJoint.as:689): split-impulse
  // correction along the constraint direction, with the large-error pre-shift.
  private distanceApplyImpulsePos(c: DistanceJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const l3 = b1.axisy * c.a1localx - b1.axisx * c.a1localy;
    const l4 = c.a1localx * b1.axisx + c.a1localy * b1.axisy;
    const l5 = b2.axisy * c.a2localx - b2.axisx * c.a2localy;
    const l6 = c.a2localx * b2.axisx + c.a2localy * b2.axisy;
    let sx = b2.posx + l5 - (b1.posx + l3);
    let sy = b2.posy + l6 - (b1.posy + l4);
    let dir = this.distanceDir(c, sx, sy);
    if (dir.slack) return;
    let nx = dir.nx;
    let ny = dir.ny;
    let err = dir.err;
    if (err * err < 0.01) return;
    err *= 0.5;
    if (err * err > 6) {
      let m = b1.smass + b2.smass;
      if (m > 1e-8) {
        m = 0.75 / m;
        const lambda = -err * m;
        if (c.equal || lambda < 0) {
          let s = lambda * b1.imass;
          b1.posx -= nx * s;
          b1.posy -= ny * s;
          s = lambda * b2.imass;
          b2.posx += nx * s;
          b2.posy += ny * s;
          sx = b2.posx + l5 - (b1.posx + l3);
          sy = b2.posy + l6 - (b1.posy + l4);
          dir = this.distanceDir(c, sx, sy);
          nx = dir.nx;
          ny = dir.ny;
          err = dir.err;
          err *= 0.5;
        }
      }
    }
    const cc1 = ny * l3 - nx * l4;
    const cc2 = ny * l5 - nx * l6;
    let kMass = b1.smass + b2.smass + cc1 * cc1 * b1.sinertia + cc2 * cc2 * b2.sinertia;
    if (kMass !== 0) kMass = 1 / kMass;
    const lambda = -err * kMass;
    if (c.equal || lambda < 0) {
      let s = b1.imass * lambda;
      b1.posx -= nx * s;
      b1.posy -= ny * s;
      s = b2.imass * lambda;
      b2.posx += nx * s;
      b2.posy += ny * s;
      this.applyPosRotation(b1, -cc1 * b1.iinertia * lambda);
      this.applyPosRotation(b2, cc2 * b2.iinertia * lambda);
    }
  }

  // AngleJoint.preStep (ZPP_AngleJoint.as:116): the active angular error + limit
  // direction `scale`, the scalar effective mass kMass, warm-scale of jAcc.
  private anglePreStep(c: AngleJoint, dt: number): void {
    const b1 = c.b1;
    const b2 = c.b2;
    if (c.pre_dt === -1) c.pre_dt = dt;
    const warmScale = dt / c.pre_dt;
    c.pre_dt = dt;
    c.equal = c.jointMin === c.jointMax;
    let err = c.ratio * b2.rot - b1.rot;
    if (c.equal) {
      err -= c.jointMax;
      c.slack = false;
      c.scale = 1;
    } else if (err < c.jointMin) {
      err = c.jointMin - err;
      c.scale = -1;
      c.slack = false;
    } else if (err > c.jointMax) {
      err -= c.jointMax;
      c.scale = 1;
      c.slack = false;
    } else {
      c.scale = 0;
      err = 0;
      c.slack = true;
    }
    void err;
    if (!c.slack) {
      let kMass = b1.sinertia + c.ratio * c.ratio * b2.sinertia;
      if (kMass !== 0) kMass = 1 / kMass;
      else c.jAcc = 0;
      c.kMass = kMass;
      c.bias = 0; // stiff
      c.gamma = 0;
      c.jAcc *= warmScale;
      c.jMax = Infinity;
    }
  }

  // AngleJoint.applyImpulseVel (ZPP_AngleJoint.as:596): drive the relative angular
  // velocity to zero; for a limit (!equal) the impulse is clamped non-positive.
  private angleApplyImpulseVel(c: AngleJoint): void {
    if (c.slack) return;
    const b1 = c.b1;
    const b2 = c.b2;
    const rel = c.scale * (c.ratio * b2.angvel - b1.angvel);
    let dj = c.kMass * (c.bias - rel) - c.jAcc * c.gamma;
    const old = c.jAcc;
    c.jAcc += dj;
    if (!c.equal && c.jAcc > 0) c.jAcc = 0;
    dj = c.jAcc - old;
    b1.angvel -= c.scale * b1.iinertia * dj;
    b2.angvel += c.ratio * c.scale * b2.iinertia * dj;
  }

  // AngleJoint.applyImpulsePos (ZPP_AngleJoint.as:631): split-impulse angular
  // correction (re-evaluating the active limit), then rotate both bodies.
  private angleApplyImpulsePos(c: AngleJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    let err = c.ratio * b2.rot - b1.rot;
    let slack: boolean;
    if (c.equal) {
      err -= c.jointMax;
      slack = false;
      c.scale = 1;
    } else if (err < c.jointMin) {
      err = c.jointMin - err;
      c.scale = -1;
      slack = false;
    } else if (err > c.jointMax) {
      err -= c.jointMax;
      c.scale = 1;
      slack = false;
    } else {
      c.scale = 0;
      err = 0;
      slack = true;
    }
    if (slack) return;
    err *= 0.5;
    const lambda = -err * c.kMass;
    if (c.equal || lambda < 0) {
      this.applyPosRotation(b1, -c.scale * lambda * b1.iinertia);
      this.applyPosRotation(b2, c.ratio * c.scale * lambda * b2.iinertia);
    }
  }

  // MotorJoint.preStep (ZPP_MotorJoint.as:90): scalar effective mass + warm-scale.
  private motorPreStep(c: MotorJoint, dt: number): void {
    const b1 = c.b1;
    const b2 = c.b2;
    if (c.pre_dt === -1) c.pre_dt = dt;
    const warmScale = dt / c.pre_dt;
    c.pre_dt = dt;
    c.kMass = b1.sinertia + c.ratio * c.ratio * b2.sinertia;
    c.kMass = 1 / c.kMass;
    c.jAcc *= warmScale;
    c.jMax = Infinity; // maxForce ∞ → no torque limit
  }

  // MotorJoint.applyImpulseVel (ZPP_MotorJoint.as:352): drive the relative angular
  // velocity to `rate`. With infinite maxForce the ±jMax clamp is inert.
  private motorApplyImpulseVel(c: MotorJoint): void {
    const b1 = c.b1;
    const b2 = c.b2;
    const rel = c.ratio * b2.angvel - b1.angvel - c.rate;
    let dj = -c.kMass * rel;
    const old = c.jAcc;
    c.jAcc += dj;
    if (c.jAcc < -c.jMax) c.jAcc = -c.jMax;
    else if (c.jAcc > c.jMax) c.jAcc = c.jMax;
    dj = c.jAcc - old;
    b1.angvel -= b1.iinertia * dj;
    b2.angvel += c.ratio * b2.iinertia * dj;
  }
}
