// Engine-agnostic physics abstraction so the game can run on either Box2D
// (planck.js) or Nape (the original AS3 engine, compiled to JS) and switch
// between them at runtime from the settings menu.
//
// The game holds bodies as opaque `PhysBody` handles (a pl.Body for planck, an
// integer for Nape) and never touches engine objects directly. Two kinds of
// access:
//   - world ops (step, create/destroy bodies, raycast) go through a `PhysWorld`
//     instance, held as `g.physics`.
//   - body ops that used to be static helpers or direct planck method calls go
//     through the `PhysicsWorld` static facade, which forwards to the active
//     engine (`PhysicsWorld.active`). Keeping the facade means the ~40 call
//     sites stay `PhysicsWorld.xxx(body)` regardless of engine.

/** Opaque physics body handle: a pl.Body for planck, an integer for Nape. */
export type PhysBody = unknown;

export interface ShapeDef {
  type: string;
  colCat: number;
  colMask: number;
  senCat: number;
  senMask: number;
  material: string;
  pos: [number, number];
  radius?: number;
  vertices?: number[];
  rotDeg?: number;
}

export interface MaterialDef {
  density: number;
  frictionStatic: number;
  frictionDynamic: number;
  frictionRolling: number;
  elasticity: number;
}

export interface FixtureTag {
  owner: unknown; // GameObj
  isSensor: boolean;
  colCat: number;
  colMask: number;
  /** material friction_rolling — emulated post-step (Box2D has no equivalent) */
  rollingFriction?: number;
}

export interface ContactEvent {
  a: FixtureTag;
  b: FixtureTag;
  sensor: boolean;
}

/** One body's role in a collision impulse report (owner + mass for thresholds). */
export interface ImpactBody {
  owner: unknown; // GameObj
  mass: number;
}

/**
 * Collision-impulse callback (breakable crates read the impact magnitude). `j`
 * is the Nape-equivalent normalImpulse length; (nx, ny) is the contact normal
 * pointing from body a to body b. planck estimates j from pre-solve velocities;
 * Nape computes it the same way from arbiter normal + relative velocity.
 */
export type ImpactCb = (a: ImpactBody, b: ImpactBody, j: number, nx: number, ny: number) => void;

/**
 * Engine-neutral level-joint description, built from LevelJointDef by movers.ts
 * (`normalizeJoint`) and consumed by each engine's `createLevelJoint`. Anchors
 * and lengths are in pixels; angles in radians. `maxMotorTorquePx` is in Nape's
 * px torque units — planck divides by S^2 to get N·m.
 */
export interface JointSpec {
  type: 'rev' | 'weld' | 'dist';
  collideConnected: boolean;
  // rev
  anchorXPx: number;
  anchorYPx: number;
  enableMotor: boolean;
  motorSpeed: number;
  maxMotorTorquePx: number;
  enableLimit: boolean;
  lowerAngleRad: number;
  upperAngleRad: number;
  // weld / dist soft constraint
  soft: boolean;
  softFreq: number;
  // dist
  x0Px: number;
  y0Px: number;
  x1Px: number;
  y1Px: number;
  distLimitPx: number;
}

export interface CreateBodyOpts {
  fixed: boolean;
  bullet?: boolean;
}

/** What every physics engine must provide. Units are pixels at the API edge. */
export interface PhysWorld {
  // --- world lifecycle -----------------------------------------------------
  step(): void;
  /** drain begin-contact events queued since last call */
  takeContacts(): ContactEvent[];
  /** register a collision-impulse listener (breakable-crate impact threshold) */
  onImpact(cb: ImpactCb): void;
  material(name: string): MaterialDef;
  createBody(
    owner: unknown,
    xPx: number,
    yPx: number,
    rotDeg: number,
    scale: number,
    shapes: ShapeDef[],
    opts: CreateBodyOpts,
  ): PhysBody;
  createStaticLoop(
    owner: unknown,
    points: number[],
    materialName: string,
    colCat: number,
    colMask: number,
    asSensor?: boolean,
  ): PhysBody;
  destroyBody(body: PhysBody): void;
  raycastFloorY(xPx: number, fromYPx: number, maxDistPx: number): number | null;
  /** bodyA/bodyB null attaches to the static world/ground body */
  createLevelJoint(spec: JointSpec, bodyA: PhysBody | null, bodyB: PhysBody | null): void;

  // --- body ops (take an opaque handle) ------------------------------------
  getPosPx(body: PhysBody): { x: number; y: number; rot: number };
  setPosPx(body: PhysBody, xPx: number, yPx: number, rotDeg: number): void;
  getVelPx(body: PhysBody): { x: number; y: number };
  setVelPx(body: PhysBody, vxPx: number, vyPx: number): void;
  massNape(body: PhysBody): number;
  applyImpulsePx(body: PhysBody, jx: number, jy: number): void;
  setAngularVelocity(body: PhysBody, w: number): void;
  isDynamic(body: PhysBody): boolean;
  setAwake(body: PhysBody, awake: boolean): void;
  setType(body: PhysBody, type: 'static' | 'dynamic' | 'kinematic'): void;
  /** body rotation in radians (wind reads GetBodyAngle) */
  bodyAngleRad(body: PhysBody): number;
  /** true if any shape of the body contains the world-space point (wind persist) */
  bodyContainsPoint(body: PhysBody, xPx: number, yPx: number): boolean;
  /** summed shape area in px^2 (burstable-ball explosion force) */
  bodyArea(body: PhysBody): number;
  /** toggle all shapes' solid collision (ball MoveToPlayer); restores originals */
  setCollisionEnabled(body: PhysBody, on: boolean): void;
  /** toggle only shapes whose top reaches above topThresholdPx (keeper duck) */
  setUpperShapesCollision(body: PhysBody, enabled: boolean, topThresholdPx: number): void;
  /** dynamic bodies currently touching this body (switch-weight persist scan) */
  touchingDynamicBodies(body: PhysBody): PhysBody[];
  /** wake bodies joined to this one (kinematic movers carry sleeping partners) */
  wakeJointPartners(body: PhysBody): void;
}

/**
 * Static facade forwarding body ops to the active engine. Engine constructors
 * set `PhysicsWorld.active = this`. Game code calls `PhysicsWorld.xxx(body)`
 * exactly as before; the facade is engine-agnostic.
 */
export class PhysicsWorld {
  static active: PhysWorld;

  static getPosPx(body: PhysBody): { x: number; y: number; rot: number } {
    return PhysicsWorld.active.getPosPx(body);
  }
  static setPosPx(body: PhysBody, xPx: number, yPx: number, rotDeg: number): void {
    PhysicsWorld.active.setPosPx(body, xPx, yPx, rotDeg);
  }
  static getVelPx(body: PhysBody): { x: number; y: number } {
    return PhysicsWorld.active.getVelPx(body);
  }
  static setVelPx(body: PhysBody, vxPx: number, vyPx: number): void {
    PhysicsWorld.active.setVelPx(body, vxPx, vyPx);
  }
  static massNape(body: PhysBody): number {
    return PhysicsWorld.active.massNape(body);
  }
  static applyImpulsePx(body: PhysBody, jx: number, jy: number): void {
    PhysicsWorld.active.applyImpulsePx(body, jx, jy);
  }
  static setAngularVelocity(body: PhysBody, w: number): void {
    PhysicsWorld.active.setAngularVelocity(body, w);
  }
  static isDynamic(body: PhysBody): boolean {
    return PhysicsWorld.active.isDynamic(body);
  }
  static setAwake(body: PhysBody, awake: boolean): void {
    PhysicsWorld.active.setAwake(body, awake);
  }
  static setType(body: PhysBody, type: 'static' | 'dynamic' | 'kinematic'): void {
    PhysicsWorld.active.setType(body, type);
  }
  static bodyAngleRad(body: PhysBody): number {
    return PhysicsWorld.active.bodyAngleRad(body);
  }
  static bodyContainsPoint(body: PhysBody, xPx: number, yPx: number): boolean {
    return PhysicsWorld.active.bodyContainsPoint(body, xPx, yPx);
  }
  static bodyArea(body: PhysBody): number {
    return PhysicsWorld.active.bodyArea(body);
  }
  static setCollisionEnabled(body: PhysBody, on: boolean): void {
    PhysicsWorld.active.setCollisionEnabled(body, on);
  }
  static setUpperShapesCollision(body: PhysBody, enabled: boolean, topThresholdPx: number): void {
    PhysicsWorld.active.setUpperShapesCollision(body, enabled, topThresholdPx);
  }
  static touchingDynamicBodies(body: PhysBody): PhysBody[] {
    return PhysicsWorld.active.touchingDynamicBodies(body);
  }
  static wakeJointPartners(body: PhysBody): void {
    PhysicsWorld.active.wakeJointPartners(body);
  }
}
