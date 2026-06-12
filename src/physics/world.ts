// planck.js world wrapped in a pixel-space API mirroring PhysicsBase.as.
// Step 1/60 with 10/10 iterations; gravity in px/s^2 from VarsData; Nape's
// global linear drag (default 0.015, never overridden by the game) is mapped
// to per-body linearDamping.
import * as pl from 'planck';
import earcut from 'earcut';
import { PX_PER_METER, VARS } from '../game/defs';

const S = PX_PER_METER;
// TODO(fidelity): Nape Space.worldLinearDrag library default — verify side by side.
export const NAPE_LINEAR_DRAG = 0.015;

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

export class PhysicsWorld {
  readonly world: pl.World;
  contacts: ContactEvent[] = [];
  private materials: Record<string, MaterialDef>;

  constructor(materials: Record<string, MaterialDef>) {
    this.materials = materials;
    this.world = new pl.World({ gravity: new pl.Vec2(0, VARS.gravity / S) });
    this.world.on('begin-contact', (contact) => {
      const fa = contact.getFixtureA();
      const fb = contact.getFixtureB();
      const a = fa.getUserData() as FixtureTag | null;
      const b = fb.getUserData() as FixtureTag | null;
      if (!a || !b) return;
      this.contacts.push({ a, b, sensor: fa.isSensor() || fb.isSensor() });
    });
    // Nape combines elasticity by AVERAGE; Box2D's default is max(a, b),
    // which makes the e=1 football bounce forever off dead (e=0) ground.
    this.world.on('pre-solve', (contact) => {
      const rA = contact.getFixtureA().getRestitution();
      const rB = contact.getFixtureB().getRestitution();
      contact.setRestitution((rA + rB) / 2);
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

  /** drain contact events queued since last call */
  takeContacts(): ContactEvent[] {
    const out = this.contacts;
    this.contacts = [];
    return out;
  }

  /**
   * All hit events for this frame: begin-contacts (catches one-step bullet
   * passes) plus every currently-touching pair — Nape dispatched arbiters
   * every frame while overlapping, and handlers are state-guarded for that.
   */
  collectContactEvents(): ContactEvent[] {
    const out = this.takeContacts();
    for (let c = this.world.getContactList(); c; c = c.getNext()) {
      if (!c.isTouching()) continue;
      const fa = c.getFixtureA();
      const fb = c.getFixtureB();
      const a = fa.getUserData() as FixtureTag | null;
      const b = fb.getUserData() as FixtureTag | null;
      if (!a || !b) continue;
      out.push({ a, b, sensor: fa.isSensor() || fb.isSensor() });
    }
    return out;
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
    opts: { fixed: boolean; bullet?: boolean },
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
      // Fan-triangulate like PhysicsBase.AddPhysObjAt — works for the convex
      // and mildly concave editor shapes the game uses.
      const pts: pl.Vec2[] = [];
      const rot = ((shape.rotDeg ?? 0) * Math.PI) / 180;
      const cos = Math.cos(rot);
      const sin = Math.sin(rot);
      for (let i = 0; i < shape.vertices.length; i += 2) {
        const vx = shape.vertices[i] * scale;
        const vy = shape.vertices[i + 1] * scale;
        pts.push(
          new pl.Vec2(
            (vx * cos - vy * sin + shape.pos[0] * scale) / S,
            (vx * sin + vy * cos + shape.pos[1] * scale) / S,
          ),
        );
      }
      for (let i = 1; i < pts.length - 1; i++) {
        geoms.push(new pl.Polygon([pts[0], pts[i], pts[i + 1]]));
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

  destroyBody(body: pl.Body): void {
    this.world.destroyBody(body);
  }

  // --- pixel-space body helpers -------------------------------------------
  static getPosPx(body: pl.Body): { x: number; y: number; rot: number } {
    const p = body.getPosition();
    return { x: p.x * S, y: p.y * S, rot: (body.getAngle() * 180) / Math.PI };
  }

  static setPosPx(body: pl.Body, xPx: number, yPx: number, rotDeg: number): void {
    const p = body.getPosition();
    const nx = xPx / S;
    const ny = yPx / S;
    const na = (rotDeg * Math.PI) / 180;
    const moved =
      Math.abs(p.x - nx) > 1e-6 || Math.abs(p.y - ny) > 1e-6 || Math.abs(body.getAngle() - na) > 1e-6;
    body.setPosition(new pl.Vec2(nx, ny));
    body.setAngle(na);
    if (moved) {
      // Nape wakes constraint partners when a body is repositioned; Box2D's
      // SetTransform doesn't — sleeping welded/jointed bodies would stay
      // frozen in place while their anchor moves away (switch-driven walls).
      for (let je = body.getJointList(); je; je = je.next) {
        je.other?.setAwake(true);
      }
      for (let ce = body.getContactList(); ce; ce = ce.next) {
        ce.other?.setAwake(true);
      }
    }
  }

  static setVelPx(body: pl.Body, vxPx: number, vyPx: number): void {
    body.setLinearVelocity(new pl.Vec2(vxPx / S, vyPx / S));
  }

  static getVelPx(body: pl.Body): { x: number; y: number } {
    const v = body.getLinearVelocity();
    return { x: v.x * S, y: v.y * S };
  }

  static massNape(body: pl.Body): number {
    // planck mass (kg) with our 0.9x density convention equals Nape's mass number
    return body.getMass();
  }

  /**
   * Apply an impulse given in original Nape pixel units (J = mass * v_px).
   * Ball kicks happen from rest, so this sets velocity directly — immune to
   * any mass-model mismatch (Football_Launch zeroes velocity first anyway).
   */
  static applyImpulsePx(body: pl.Body, jx: number, jy: number): void {
    const m = body.getMass();
    if (m <= 0) return;
    const v = body.getLinearVelocity();
    body.setLinearVelocity(new pl.Vec2(v.x + jx / m / S, v.y + jy / m / S));
  }
}
