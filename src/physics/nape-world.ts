// Nape engine wrapper. The original AS3 game ran on Nape; we compiled Nape
// (Haxe) to public/assets/nape.js, which exposes `window.NapeWorld`. This class
// adapts that handle-based, PIXEL-unit API to the engine-neutral PhysWorld so
// the game can switch between Box2D (planck) and Nape at runtime.
//
// Nape runs in pixels (no meter scaling), so the API edge needs no /S
// conversion, and rolling friction + mass + collision impulse are all native —
// which is exactly why it matches the original feel more closely than planck.
import { VARS } from '../game/defs';
import { triangulate } from './planck-world';
import {
  PhysicsWorld,
  type PhysWorld,
  type PhysBody,
  type ShapeDef,
  type MaterialDef,
  type FixtureTag,
  type ContactEvent,
  type CreateBodyOpts,
  type JointSpec,
  type ImpactCb,
} from './phys-world';

// Nape worldLinearDrag/worldAngularDrag library default (never overridden by
// the game), applied per-body inside the Haxe step().
const NAPE_DRAG = 0.015;

/** The handle-based facade exposed by the compiled nape.js (window.NapeWorld). */
interface NapeNative {
  setGravity(gpxY: number): void;
  createBody(isStatic: boolean, x: number, y: number, rotDeg: number, linDamp: number, angDamp: number): number;
  addCircle(h: number, posX: number, posY: number, radius: number, density: number, friction: number, rolling: number, elasticity: number, colCat: number, colMask: number, isSensor: boolean): void;
  addPolygon(h: number, vertsFlat: number[], density: number, friction: number, rolling: number, elasticity: number, colCat: number, colMask: number, isSensor: boolean): void;
  finalizeBody(h: number, bullet: boolean): void;
  setBodyType(h: number, type: number): void;
  destroyBody(h: number): void;
  step(dt: number, velIters: number, posIters: number): void;
  takeContacts(): number[];
  takeImpacts(): number[];
  getX(h: number): number;
  getY(h: number): number;
  getRot(h: number): number;
  getRotRad(h: number): number;
  getVX(h: number): number;
  getVY(h: number): number;
  getAngVel(h: number): number;
  getMass(h: number): number;
  isDynamic(h: number): boolean;
  bodyContains(h: number, x: number, y: number): boolean;
  bodyArea(h: number): number;
  setTransform(h: number, x: number, y: number, rotDeg: number): void;
  setVel(h: number, vx: number, vy: number): void;
  setAngVel(h: number, w: number): void;
  setAwake(h: number, awake: boolean): void;
  applyImpulse(h: number, jx: number, jy: number): void;
  setBodyCollision(h: number, enabled: boolean): void;
  setBodyCollisionAboveTop(h: number, topThresholdPx: number, enabled: boolean): void;
  touchingBodies(h: number): number[];
  raycastDown(x: number, fromY: number, maxDist: number, colCat: number): number;
  jointRev(hA: number, hB: number, ax: number, ay: number, enableMotor: boolean, motorSpeed: number, maxTorque: number, enableLimit: boolean, lowerRad: number, upperRad: number): void;
  jointWeld(hA: number, hB: number, soft: boolean, freq: number): void;
  jointDist(hA: number, hB: number, x0: number, y0: number, x1: number, y1: number, distLimit: number, soft: boolean, freq: number): void;
}

interface NapeGlobal {
  NapeWorld?: new (gravityPxY: number) => NapeNative;
}

const BASE = import.meta.env.BASE_URL;
// Cache-buster for the compiled engine: bump this whenever nape.js is rebuilt
// so browsers fetch the new physics instead of a stale cached copy (a cached
// old build was why level-9 felt unreachable under Nape).
const NAPE_BUILD = '20260613d';
let napeLoadPromise: Promise<void> | null = null;

/** true once nape.js has been loaded and window.NapeWorld is constructible */
export function napeLoaded(): boolean {
  return typeof (globalThis as unknown as NapeGlobal).NapeWorld === 'function';
}

/** Inject nape.js once; resolves when window.NapeWorld is available. */
export function ensureNapeLoaded(): Promise<void> {
  if (napeLoaded()) return Promise.resolve();
  if (napeLoadPromise) return napeLoadPromise;
  napeLoadPromise = new Promise<void>((resolve, reject) => {
    const s = document.createElement('script');
    s.src = `${BASE}assets/nape.js?v=${NAPE_BUILD}`;
    s.async = true;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error('failed to load nape.js'));
    document.head.appendChild(s);
  });
  return napeLoadPromise;
}

export class NapePhysWorld implements PhysWorld {
  private nape: NapeNative;
  private materials: Record<string, MaterialDef>;
  private owners = new Map<number, unknown>();
  private impactCbs: ImpactCb[] = [];

  constructor(materials: Record<string, MaterialDef>) {
    const Ctor = (globalThis as unknown as NapeGlobal).NapeWorld;
    if (!Ctor) throw new Error('NapeWorld not loaded — call ensureNapeLoaded() first');
    this.materials = materials;
    this.nape = new Ctor(VARS.gravity); // px/s^2 (Nape runs in pixels)
    PhysicsWorld.active = this;
  }

  material(name: string): MaterialDef {
    return (
      this.materials[name] ?? {
        density: 0.5,
        frictionStatic: 0.1,
        frictionDynamic: 0.1,
        frictionRolling: 0.1,
        elasticity: 0.2,
      }
    );
  }

  step(): void {
    this.nape.setGravity(VARS.gravity); // Game.as re-sets gravity each frame
    this.nape.step(1 / 60, 10, 10);
    // drain collision impulses -> onImpact listeners (breakable crates)
    if (this.impactCbs.length) {
      const im = this.nape.takeImpacts(); // [hA, hB, j, nx, ny, ...]
      for (let i = 0; i + 4 < im.length; i += 5) {
        const ha = im[i];
        const hb = im[i + 1];
        const a = { owner: this.owners.get(ha), mass: this.nape.getMass(ha) };
        const b = { owner: this.owners.get(hb), mass: this.nape.getMass(hb) };
        for (const cb of this.impactCbs) cb(a, b, im[i + 2], im[i + 3], im[i + 4]);
      }
    }
  }

  takeContacts(): ContactEvent[] {
    const raw = this.nape.takeContacts(); // [hA, hB, sensorFlag, ...]
    const out: ContactEvent[] = [];
    for (let i = 0; i + 2 < raw.length; i += 3) {
      const a = this.tagFor(raw[i]);
      const b = this.tagFor(raw[i + 1]);
      if (!a || !b) continue;
      out.push({ a, b, sensor: raw[i + 2] === 1 });
    }
    return out;
  }

  // Synthesize a FixtureTag from a body handle. Contact consumers only read
  // owner + the event's sensor flag, so the geometric fields are placeholders.
  private tagFor(h: number): FixtureTag | null {
    const owner = this.owners.get(h);
    if (owner === undefined) return null;
    return { owner, isSensor: false, colCat: 0, colMask: 0 };
  }

  onImpact(cb: ImpactCb): void {
    this.impactCbs.push(cb);
  }

  createBody(
    owner: unknown,
    xPx: number,
    yPx: number,
    rotDeg: number,
    scale: number,
    shapes: ShapeDef[],
    opts: CreateBodyOpts,
  ): PhysBody {
    const h = this.nape.createBody(opts.fixed, xPx, yPx, rotDeg, NAPE_DRAG, NAPE_DRAG);
    this.owners.set(h, owner);
    for (const shape of shapes) this.addShape(h, shape, scale);
    this.nape.finalizeBody(h, opts.bullet ?? false);
    return h;
  }

  private addShape(h: number, shape: ShapeDef, scale: number): void {
    const mat = this.material(shape.material);
    const f = mat.frictionDynamic;
    const e = mat.elasticity;
    const roll = mat.frictionRolling;
    // Nape applies density/1000 internally, so pass the raw AS3 density — the
    // resulting mass equals the game's massNape. Sensor copies use density 0.
    const addCircle = (sensor: boolean, cat: number, mask: number): void =>
      this.nape.addCircle(
        h,
        shape.pos[0] * scale,
        shape.pos[1] * scale,
        (shape.radius ?? 10) * scale,
        sensor ? 0 : mat.density,
        f,
        roll,
        e,
        cat,
        mask,
        sensor,
      );
    const addPoly = (sensor: boolean, cat: number, mask: number, verts: number[]): void =>
      this.nape.addPolygon(h, verts, sensor ? 0 : mat.density, f, roll, e, cat, mask, sensor);

    if (shape.type === 'circle') {
      if (shape.colCat !== 0 && shape.colMask !== 0) addCircle(false, shape.colCat, shape.colMask);
      if (shape.senCat !== 0 && shape.senMask !== 0) addCircle(true, shape.senCat, shape.senMask);
    } else if (shape.vertices && shape.vertices.length >= 6) {
      // transform local verts by rot + pos + scale (pixel space, no /S). Nape's
      // addPolygon convex-decomposes internally, so concave crates are fine.
      const rot = ((shape.rotDeg ?? 0) * Math.PI) / 180;
      const cos = Math.cos(rot);
      const sin = Math.sin(rot);
      const flat: number[] = [];
      for (let i = 0; i < shape.vertices.length; i += 2) {
        const vx = shape.vertices[i] * scale;
        const vy = shape.vertices[i + 1] * scale;
        flat.push(vx * cos - vy * sin + shape.pos[0] * scale, vx * sin + vy * cos + shape.pos[1] * scale);
      }
      if (shape.colCat !== 0 && shape.colMask !== 0) addPoly(false, shape.colCat, shape.colMask, flat);
      if (shape.senCat !== 0 && shape.senMask !== 0) addPoly(true, shape.senCat, shape.senMask, flat);
    }
  }

  createStaticLoop(
    owner: unknown,
    points: number[],
    materialName: string,
    colCat: number,
    colMask: number,
    asSensor = false,
  ): PhysBody {
    const mat = this.material(materialName);
    const h = this.nape.createBody(true, 0, 0, 0, 0, 0);
    this.owners.set(h, owner);
    // Terrain outlines can be concave / self-touching; triangulate in TS (same
    // decomposition planck uses) and add one Nape polygon per triangle.
    for (const tri of triangulate(points)) {
      const flat = [tri[0][0], tri[0][1], tri[1][0], tri[1][1], tri[2][0], tri[2][1]];
      this.nape.addPolygon(h, flat, asSensor ? 0 : mat.density, mat.frictionDynamic, 0, mat.elasticity, colCat, colMask, asSensor);
    }
    this.nape.finalizeBody(h, false);
    return h;
  }

  destroyBody(body: PhysBody): void {
    const h = body as number;
    this.nape.destroyBody(h);
    this.owners.delete(h);
  }

  raycastFloorY(xPx: number, fromYPx: number, maxDistPx: number): number | null {
    const y = this.nape.raycastDown(xPx, fromYPx, maxDistPx, 1);
    return Number.isNaN(y) ? null : y;
  }

  createLevelJoint(spec: JointSpec, bodyA: PhysBody | null, bodyB: PhysBody | null): void {
    const ha = (bodyA as number | null) ?? 0; // handle 0 == static world body
    const hb = (bodyB as number | null) ?? 0;
    if (spec.type === 'rev') {
      this.nape.jointRev(
        ha, hb, spec.anchorXPx, spec.anchorYPx,
        spec.enableMotor, spec.motorSpeed, spec.maxMotorTorquePx,
        spec.enableLimit, spec.lowerAngleRad, spec.upperAngleRad,
      );
    } else if (spec.type === 'weld') {
      this.nape.jointWeld(ha, hb, spec.soft, spec.softFreq);
    } else {
      this.nape.jointDist(ha, hb, spec.x0Px, spec.y0Px, spec.x1Px, spec.y1Px, spec.distLimitPx, spec.soft, spec.softFreq);
    }
  }

  // --- body ops -----------------------------------------------------------
  getPosPx(body: PhysBody): { x: number; y: number; rot: number } {
    const h = body as number;
    return { x: this.nape.getX(h), y: this.nape.getY(h), rot: this.nape.getRot(h) };
  }
  setPosPx(body: PhysBody, xPx: number, yPx: number, rotDeg: number): void {
    this.nape.setTransform(body as number, xPx, yPx, rotDeg);
  }
  getVelPx(body: PhysBody): { x: number; y: number } {
    const h = body as number;
    return { x: this.nape.getVX(h), y: this.nape.getVY(h) };
  }
  setVelPx(body: PhysBody, vxPx: number, vyPx: number): void {
    this.nape.setVel(body as number, vxPx, vyPx);
  }
  massNape(body: PhysBody): number {
    return this.nape.getMass(body as number);
  }
  applyImpulsePx(body: PhysBody, jx: number, jy: number): void {
    // Nape applyImpulse gives dv = J/mass in px/s — exactly the kick model.
    this.nape.applyImpulse(body as number, jx, jy);
  }
  setAngularVelocity(body: PhysBody, w: number): void {
    this.nape.setAngVel(body as number, w);
  }
  isDynamic(body: PhysBody): boolean {
    return this.nape.isDynamic(body as number);
  }
  setAwake(body: PhysBody, awake: boolean): void {
    this.nape.setAwake(body as number, awake);
  }
  setType(body: PhysBody, type: 'static' | 'dynamic' | 'kinematic'): void {
    this.nape.setBodyType(body as number, type === 'static' ? 0 : type === 'kinematic' ? 2 : 1);
  }
  bodyAngleRad(body: PhysBody): number {
    return this.nape.getRotRad(body as number);
  }
  bodyContainsPoint(body: PhysBody, xPx: number, yPx: number): boolean {
    return this.nape.bodyContains(body as number, xPx, yPx);
  }
  bodyArea(body: PhysBody): number {
    return this.nape.bodyArea(body as number);
  }
  setCollisionEnabled(body: PhysBody, on: boolean): void {
    this.nape.setBodyCollision(body as number, on);
  }
  setUpperShapesCollision(body: PhysBody, enabled: boolean, topThresholdPx: number): void {
    this.nape.setBodyCollisionAboveTop(body as number, topThresholdPx, enabled);
  }
  touchingDynamicBodies(body: PhysBody): PhysBody[] {
    return this.nape.touchingBodies(body as number);
  }
  wakeJointPartners(_body: PhysBody): void {
    // No-op: Nape keeps constraint partners awake natively (unlike Box2D, which
    // needed an explicit wake when a kinematic mover carried a sleeping body).
  }
}
