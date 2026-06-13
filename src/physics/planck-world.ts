// planck.js (Box2D) engine wrapped in the pixel-space PhysWorld API mirroring
// PhysicsBase.as. Step 1/60 with 10/10 iterations; gravity in px/s^2 from
// VarsData; Nape's global linear drag (default 0.015, never overridden by the
// game) is mapped to per-body linearDamping.
import * as pl from 'planck';
import earcut from 'earcut';
import { PX_PER_METER, VARS } from '../game/defs';
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

const S = PX_PER_METER;
// TODO(fidelity): Nape Space.worldLinearDrag library default — verify side by side.
export const NAPE_LINEAR_DRAG = 0.015;

/**
 * Ear-clip triangulation of a flattened [x0,y0,x1,y1,...] outline.
 * Degenerate slivers are dropped; winding is normalized CCW for Box2D.
 */
export function triangulate(points: number[]): [number, number][][] {
  const indices = earcut(points);
  const tris: [number, number][][] = [];
  for (let i = 0; i < indices.length; i += 3) {
    const tri: [number, number][] = [0, 1, 2].map((k) => {
      const idx = indices[i + k];
      return [points[idx * 2], points[idx * 2 + 1]] as [number, number];
    });
    // signed area: skip slivers, flip CW -> CCW
    const area =
      (tri[1][0] - tri[0][0]) * (tri[2][1] - tri[0][1]) -
      (tri[2][0] - tri[0][0]) * (tri[1][1] - tri[0][1]);
    if (Math.abs(area) < 1) continue;
    if (area > 0) tri.reverse(); // canvas y-down: positive cross = CW for Box2D
    tris.push(tri);
  }
  return tris;
}

function toVec2s(flat: number[], scale: number): pl.Vec2[] {
  const out: pl.Vec2[] = [];
  for (let i = 0; i < flat.length; i += 2) out.push(new pl.Vec2(flat[i] / scale, flat[i + 1] / scale));
  return out;
}

/** true if the polygon is convex (all cross products share one sign). */
function isConvex(v: pl.Vec2[]): boolean {
  const n = v.length;
  if (n < 3) return false;
  let pos = false;
  let neg = false;
  for (let i = 0; i < n; i++) {
    const a = v[i];
    const b = v[(i + 1) % n];
    const c = v[(i + 2) % n];
    const cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (cross > 1e-9) pos = true;
    else if (cross < -1e-9) neg = true;
    if (pos && neg) return false;
  }
  return true;
}

/** Box2D wants CCW winding; canvas y is down so flip if signed area is negative. */
function ensureCCW(v: pl.Vec2[]): pl.Vec2[] {
  let area = 0;
  for (let i = 0; i < v.length; i++) {
    const a = v[i];
    const b = v[(i + 1) % v.length];
    area += a.x * b.y - b.x * a.y;
  }
  // y-down screen space: positive shoelace area = clockwise on screen = CCW for Box2D
  return area > 0 ? v : v.slice().reverse();
}

export class PlanckWorld implements PhysWorld {
  readonly world: pl.World;
  private contacts: ContactEvent[] = [];
  private materials: Record<string, MaterialDef>;
  private ground: pl.Body | null = null;
  private impactCbs: ImpactCb[] = [];

  constructor(materials: Record<string, MaterialDef>) {
    this.materials = materials;
    this.world = new pl.World({ gravity: new pl.Vec2(0, VARS.gravity / S) });
    PhysicsWorld.active = this;
    this.world.on('begin-contact', (contact) => {
      const fa = contact.getFixtureA();
      const fb = contact.getFixtureB();
      const a = fa.getUserData() as FixtureTag | null;
      const b = fb.getUserData() as FixtureTag | null;
      if (!a || !b) return;
      this.contacts.push({ a, b, sensor: fa.isSensor() || fb.isSensor() });
      if (this.impactCbs.length) this.dispatchImpact(contact, fa, fb, a, b);
    });
    // Match Nape's DEFAULT elasticity combiner so planck feels like the
    // original: restitution = clamp((eA + eB) / 2, 0, 1). Verified empirically
    // against the compiled Nape engine — e.g. ball(1)+ground(0) -> ~0.5 (the
    // ball really does bounce off the pitch), ball(1)+crate(0.2) -> ~0.6 (the
    // wall-bounce pass), ball(1)+springboard(2) -> clamped to 1.0 (perfectly
    // elastic). Box2D's own default is max, and the earlier PRODUCT guess made
    // every bounce far too flat (ground 0, crate 0.2).
    this.world.on('pre-solve', (contact) => {
      const rA = contact.getFixtureA().getRestitution();
      const rB = contact.getFixtureB().getRestitution();
      contact.setRestitution(Math.min(1, (rA + rB) / 2));
    });
  }

  step(): void {
    // Game.as re-sets gravity from VarsData every frame
    this.world.setGravity(new pl.Vec2(0, VARS.gravity / S));
    this.world.step(1 / 60, 10, 10);
    this.applyRollingFriction();
  }

  // Nape rolling friction has no Box2D equivalent: damp angular velocity of
  // dynamic bodies while they touch something, scaled by the contact pair's
  // combined friction_rolling. TODO(fidelity): tune factor vs the original.
  private applyRollingFriction(): void {
    for (let contact = this.world.getContactList(); contact; contact = contact.getNext()) {
      if (!contact.isTouching()) continue;
      const fa = contact.getFixtureA();
      const fb = contact.getFixtureB();
      if (fa.isSensor() || fb.isSensor()) continue;
      const ta = fa.getUserData() as FixtureTag | null;
      const tb = fb.getUserData() as FixtureTag | null;
      const fr = Math.sqrt((ta?.rollingFriction ?? 0) * (tb?.rollingFriction ?? 0));
      if (fr <= 0) continue;
      for (const body of [fa.getBody(), fb.getBody()]) {
        if (!body.isDynamic()) continue;
        body.setAngularVelocity(body.getAngularVelocity() * Math.max(0, 1 - fr * 0.15));
      }
    }
  }

  takeContacts(): ContactEvent[] {
    const out = this.contacts;
    this.contacts = [];
    return out;
  }

  onImpact(cb: ImpactCb): void {
    this.impactCbs.push(cb);
  }

  // Nape exposes the accumulated contact impulse (normalImpulse) directly, but
  // planck has none at begin-contact, so estimate from pre-solve velocities:
  // j = (1 + e) * vRel_n / (invMassA + invMassB).
  private dispatchImpact(
    contact: pl.Contact,
    fa: pl.Fixture,
    fb: pl.Fixture,
    ta: FixtureTag,
    tb: FixtureTag,
  ): void {
    if (fa.isSensor() || fb.isSensor()) return;
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
    for (const cb of this.impactCbs) {
      cb({ owner: ta.owner, mass: bodyA.getMass() }, { owner: tb.owner, mass: bodyB.getMass() }, j, n.x, n.y);
    }
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

  /**
   * Create a body at pixel position with the given shape defs.
   * Nape density is g/px^2; with S=30 a planck fixture density of
   * 0.9 * napeDensity makes body mass numerically equal to Nape's
   * (mass_kg = density_nape * area_px / 1000).
   */
  createBody(
    owner: unknown,
    xPx: number,
    yPx: number,
    rotDeg: number,
    scale: number,
    shapes: ShapeDef[],
    opts: CreateBodyOpts,
  ): pl.Body {
    const body = this.world.createBody({
      type: opts.fixed ? 'static' : 'dynamic',
      position: new pl.Vec2(xPx / S, yPx / S),
      angle: (rotDeg * Math.PI) / 180,
      linearDamping: NAPE_LINEAR_DRAG,
      // Nape worldAngularDrag (library default, never overridden by the game)
      angularDamping: NAPE_LINEAR_DRAG,
      bullet: opts.bullet ?? false,
    });
    for (const shape of shapes) {
      this.addFixtures(body, owner, shape, scale);
    }
    return body;
  }

  private addFixtures(body: pl.Body, owner: unknown, shape: ShapeDef, scale: number): void {
    const mat = this.material(shape.material);
    const geoms: pl.Shape[] = [];
    if (shape.type === 'circle') {
      geoms.push(
        new pl.Circle(
          new pl.Vec2((shape.pos[0] * scale) / S, (shape.pos[1] * scale) / S),
          ((shape.radius ?? 10) * scale) / S,
        ),
      );
    } else if (shape.vertices && shape.vertices.length >= 6) {
      const rot = ((shape.rotDeg ?? 0) * Math.PI) / 180;
      const cos = Math.cos(rot);
      const sin = Math.sin(rot);
      const flat: number[] = [];
      for (let i = 0; i < shape.vertices.length; i += 2) {
        const vx = shape.vertices[i] * scale;
        const vy = shape.vertices[i + 1] * scale;
        flat.push(vx * cos - vy * sin + shape.pos[0] * scale, vx * sin + vy * cos + shape.pos[1] * scale);
      }
      // A convex polygon (crates, posts, most editor boxes) becomes ONE native
      // planck.Polygon — box-vs-box contacts stack stably. Triangulating a
      // convex box into 2 triangles gives erratic triangle-vs-triangle contacts
      // (jitter, scatter), which is what broke the level-9 crate stack.
      // Only genuinely concave shapes (e.g. the goal post) are ear-clipped.
      const verts = toVec2s(flat, S);
      if (verts.length <= 8 && isConvex(verts)) {
        geoms.push(new pl.Polygon(ensureCCW(verts)));
      } else {
        for (const tri of triangulate(flat)) {
          geoms.push(new pl.Polygon(tri.map((p) => new pl.Vec2(p[0] / S, p[1] / S))));
        }
      }
    }

    for (const geom of geoms) {
      // Solid fixture (Nape collision filter)
      if (shape.colCat !== 0 && shape.colMask !== 0) {
        const f = body.createFixture({
          shape: geom,
          density: mat.density * 0.9,
          friction: mat.frictionDynamic,
          restitution: mat.elasticity,
          filterCategoryBits: shape.colCat,
          filterMaskBits: shape.colMask,
        });
        f.setUserData({
          owner,
          isSensor: false,
          colCat: shape.colCat,
          colMask: shape.colMask,
          rollingFriction: mat.frictionRolling,
        } satisfies FixtureTag);
      }
      // Sensor fixture (Nape sensor filter)
      if (shape.senCat !== 0 && shape.senMask !== 0) {
        const f = body.createFixture({
          shape: geom,
          density: 0,
          isSensor: true,
          filterCategoryBits: shape.senCat,
          filterMaskBits: shape.senMask,
        });
        f.setUserData({ owner, isSensor: true, colCat: shape.senCat, colMask: shape.senMask } satisfies FixtureTag);
      }
    }
  }

  /**
   * Static terrain polygon from a flattened point list. Mirrors
   * PhysicsBase.InitLines: ear-clip triangulate the (possibly self-touching)
   * outline — Nape's GeomPoly.triangularDecomposition — and add one polygon
   * fixture per triangle.
   */
  createStaticLoop(
    owner: unknown,
    points: number[],
    materialName: string,
    colCat: number,
    colMask: number,
    asSensor = false,
  ): pl.Body {
    const mat = this.material(materialName);
    const body = this.world.createBody({ type: 'static' });
    for (const tri of triangulate(points)) {
      const f = body.createFixture({
        shape: new pl.Polygon(tri.map((p) => new pl.Vec2(p[0] / S, p[1] / S))),
        friction: mat.frictionDynamic,
        restitution: mat.elasticity,
        isSensor: asSensor,
        filterCategoryBits: colCat,
        filterMaskBits: colMask,
      });
      f.setUserData({ owner, isSensor: asSensor, colCat, colMask } satisfies FixtureTag);
    }
    return body;
  }

  /** Raycast straight down, category-1 (floor) only — used for ground snapping. */
  raycastFloorY(xPx: number, fromYPx: number, maxDistPx: number): number | null {
    let hitY: number | null = null;
    this.world.rayCast(
      new pl.Vec2(xPx / S, fromYPx / S),
      new pl.Vec2(xPx / S, (fromYPx + maxDistPx) / S),
      (fixture, point, _normal, fraction) => {
        const tag = fixture.getUserData() as FixtureTag | null;
        if (!tag || tag.isSensor || (tag.colCat & 1) === 0) return -1; // skip
        hitY = point.y * S;
        return fraction; // clip to nearest
      },
    );
    return hitY;
  }

  destroyBody(body: PhysBody): void {
    this.world.destroyBody(body as pl.Body);
  }

  private groundBody(): pl.Body {
    if (!this.ground) this.ground = this.world.createBody({ type: 'static' });
    return this.ground;
  }

  // Joints against the world (obj name "") attach to Nape's static space.world
  // body; planck needs an explicit static ground body per world.
  createLevelJoint(spec: JointSpec, bodyAh: PhysBody | null, bodyBh: PhysBody | null): void {
    const world = this.world;
    const bodyA = (bodyAh as pl.Body | null) ?? this.groundBody();
    const bodyB = (bodyBh as pl.Body | null) ?? this.groundBody();
    const collideConnected = spec.collideConnected;

    if (spec.type === 'rev') {
      // PhysicsBase.as:641-695 — PivotJoint (+ optional MotorJoint + AngleJoint)
      const anchor = new pl.Vec2(spec.anchorXPx / S, spec.anchorYPx / S);
      const rev = new pl.RevoluteJoint({
        bodyA,
        bodyB,
        collideConnected,
        localAnchorA: bodyA.getLocalPoint(anchor),
        localAnchorB: bodyB.getLocalPoint(anchor),
        // Nape's AngleJoint limits the absolute relative rotation (b2-b1), not
        // an offset from the starting pose — referenceAngle 0 reproduces that.
        referenceAngle: 0,
        enableMotor: spec.enableMotor,
        motorSpeed: spec.motorSpeed,
        // Nape px torque units -> divide by 30^2 for N*m.
        maxMotorTorque: spec.maxMotorTorquePx / (S * S),
        enableLimit: spec.enableLimit,
        lowerAngle: spec.lowerAngleRad,
        upperAngle: spec.upperAngleRad,
      });
      world.createJoint(rev);
    } else if (spec.type === 'weld') {
      // PhysicsBase.as:696-742 — WeldJoint; a weld is rigid regardless of anchor,
      // so we use bodyB's origin (the AS3 anchor math is a discarded no-op).
      if (!bodyA.isDynamic() && !bodyB.isDynamic()) {
        console.error('Weld joints cannot have both bodies non-dynamic — joint not created');
        return;
      }
      const p = bodyB.getPosition();
      const anchor = new pl.Vec2(p.x, p.y);
      const weld = new pl.WeldJoint({
        bodyA,
        bodyB,
        collideConnected,
        localAnchorA: bodyA.getLocalPoint(anchor),
        localAnchorB: bodyB.getLocalPoint(anchor),
        referenceAngle: bodyB.getAngle() - bodyA.getAngle(), // phase
        frequencyHz: spec.soft ? spec.softFreq : 0,
        dampingRatio: spec.soft ? 1 : 0, // Nape Constraint.damping default = 1
      });
      world.createJoint(weld);
    } else {
      // PhysicsBase.as:744-783 — DistanceJoint with jointMin = dist-limit and
      // jointMax = dist+limit around the anchor separation.
      const a0 = new pl.Vec2(spec.x0Px / S, spec.y0Px / S);
      const a1 = new pl.Vec2(spec.x1Px / S, spec.y1Px / S);
      const dist = Math.hypot(spec.x1Px - spec.x0Px, spec.y1Px - spec.y0Px);
      if (spec.distLimitPx === 0) {
        // rigid rod (min == max == dist)
        const dj = new pl.DistanceJoint({
          bodyA,
          bodyB,
          collideConnected,
          localAnchorA: bodyA.getLocalPoint(a0),
          localAnchorB: bodyB.getLocalPoint(a1),
          length: dist / S,
          frequencyHz: spec.soft ? spec.softFreq : 0,
          dampingRatio: spec.soft ? 1 : 0,
        });
        world.createJoint(dj);
      } else {
        // planck has no min/max distance joint; a rope joint enforces the upper
        // bound (dist+limit). TODO(M5): lower bound not enforced — acceptable.
        const rj = new pl.RopeJoint({
          bodyA,
          bodyB,
          collideConnected,
          localAnchorA: bodyA.getLocalPoint(a0),
          localAnchorB: bodyB.getLocalPoint(a1),
          maxLength: (dist + spec.distLimitPx) / S,
        });
        world.createJoint(rj);
      }
    }
  }

  // --- body ops -----------------------------------------------------------
  getPosPx(body: PhysBody): { x: number; y: number; rot: number } {
    const b = body as pl.Body;
    const p = b.getPosition();
    return { x: p.x * S, y: p.y * S, rot: (b.getAngle() * 180) / Math.PI };
  }

  setPosPx(body: PhysBody, xPx: number, yPx: number, rotDeg: number): void {
    const b = body as pl.Body;
    const p = b.getPosition();
    const nx = xPx / S;
    const ny = yPx / S;
    const na = (rotDeg * Math.PI) / 180;
    const moved =
      Math.abs(p.x - nx) > 1e-6 || Math.abs(p.y - ny) > 1e-6 || Math.abs(b.getAngle() - na) > 1e-6;
    b.setPosition(new pl.Vec2(nx, ny));
    b.setAngle(na);
    if (moved) {
      // Nape wakes constraint partners when a body is repositioned; Box2D's
      // SetTransform doesn't — sleeping welded/jointed bodies would stay
      // frozen in place while their anchor moves away (switch-driven walls).
      for (let je = b.getJointList(); je; je = je.next) {
        je.other?.setAwake(true);
      }
      for (let ce = b.getContactList(); ce; ce = ce.next) {
        ce.other?.setAwake(true);
      }
    }
  }

  setVelPx(body: PhysBody, vxPx: number, vyPx: number): void {
    (body as pl.Body).setLinearVelocity(new pl.Vec2(vxPx / S, vyPx / S));
  }

  getVelPx(body: PhysBody): { x: number; y: number } {
    const v = (body as pl.Body).getLinearVelocity();
    return { x: v.x * S, y: v.y * S };
  }

  massNape(body: PhysBody): number {
    // planck mass (kg) with our 0.9x density convention equals Nape's mass number
    return (body as pl.Body).getMass();
  }

  /**
   * Apply an impulse given in original Nape pixel units (J = mass * v_px).
   * Ball kicks happen from rest, so this sets velocity directly — immune to
   * any mass-model mismatch (Football_Launch zeroes velocity first anyway).
   */
  applyImpulsePx(body: PhysBody, jx: number, jy: number): void {
    const b = body as pl.Body;
    const m = b.getMass();
    if (m <= 0) return;
    const v = b.getLinearVelocity();
    b.setLinearVelocity(new pl.Vec2(v.x + jx / m / S, v.y + jy / m / S));
  }

  setAngularVelocity(body: PhysBody, w: number): void {
    (body as pl.Body).setAngularVelocity(w);
  }

  isDynamic(body: PhysBody): boolean {
    return (body as pl.Body).isDynamic();
  }

  setAwake(body: PhysBody, awake: boolean): void {
    (body as pl.Body).setAwake(awake);
  }

  setType(body: PhysBody, type: 'static' | 'dynamic' | 'kinematic'): void {
    (body as pl.Body).setType(type);
  }

  bodyAngleRad(body: PhysBody): number {
    return (body as pl.Body).getAngle();
  }

  bodyContainsPoint(body: PhysBody, xPx: number, yPx: number): boolean {
    const p = new pl.Vec2(xPx / S, yPx / S);
    for (let f = (body as pl.Body).getFixtureList(); f; f = f.getNext()) {
      if (f.testPoint(p)) return true;
    }
    return false;
  }

  bodyArea(body: PhysBody): number {
    // Nape shape.area is px^2; planck computeMass with density 1 yields area in
    // m^2, so scale by S^2.
    let area = 0;
    const md: pl.MassData = { mass: 0, center: new pl.Vec2(0, 0), I: 0 };
    for (let f = (body as pl.Body).getFixtureList(); f; f = f.getNext()) {
      f.getShape().computeMass(md, 1);
      area += md.mass * S * S;
    }
    return area;
  }

  // Football_MoveToPlayer zeroes the masks and restores origCollisionMask /
  // origSensorMask afterwards — the originals live on each fixture's tag.
  setCollisionEnabled(body: PhysBody, on: boolean): void {
    for (let f = (body as pl.Body).getFixtureList(); f; f = f.getNext()) {
      const tag = f.getUserData() as { colMask: number } | null;
      f.setFilterData({
        groupIndex: f.getFilterGroupIndex(),
        categoryBits: f.getFilterCategoryBits(),
        maskBits: on ? (tag?.colMask ?? 0xffff) : 0,
      });
    }
  }

  // keeper duck: toggle only the upper-body shapes (the tall idle shape reaches
  // above -50px; the crouch shape does not) so the ball flies over the head.
  setUpperShapesCollision(body: PhysBody, enabled: boolean, topThresholdPx: number): void {
    const b = body as pl.Body;
    const bodyY = b.getPosition().y;
    for (let f = b.getFixtureList(); f; f = f.getNext()) {
      const tag = f.getUserData() as { colMask: number } | null;
      const topPx = (bodyY - f.getAABB(0).lowerBound.y) * S;
      if (topPx <= topThresholdPx) continue; // crouch-height shape stays solid
      f.setFilterData({
        groupIndex: f.getFilterGroupIndex(),
        categoryBits: f.getFilterCategoryBits(),
        maskBits: enabled ? (tag?.colMask ?? 14) : 0,
      });
    }
  }

  touchingDynamicBodies(body: PhysBody): PhysBody[] {
    const out: pl.Body[] = [];
    for (let edge = (body as pl.Body).getContactList(); edge; edge = edge.next) {
      if (!edge.contact?.isTouching()) continue;
      const other = edge.other;
      if (!other || !other.isDynamic()) continue;
      out.push(other);
    }
    return out;
  }

  wakeJointPartners(body: PhysBody): void {
    for (let je = (body as pl.Body).getJointList(); je; je = je.next) {
      je.other?.setAwake(true);
    }
  }
}
