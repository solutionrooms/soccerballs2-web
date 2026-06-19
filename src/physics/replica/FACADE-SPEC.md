# Facade spec — completing `NapeReplica` as a drop-in for `window.NapeWorld`

**STATUS: IMPLEMENTED (2026-06-18).** All §0–§5 below are done in `nape-core.ts` +
`nape-world.ts`. `NapeReplica` now satisfies the full `NapeNative` interface; the cutover is
wired behind `?physics=replica` / `setReplicaEngine(true)` (default OFF). 44 replica tests green
(incl. `p0fac-facade` smoke + `p0fac-e2e` end-to-end through the adapter), `tsc` clean. The text
below is retained as the design record.

Status (2026-06-18): the **engine is complete** (poly-poly + 2-contact solver, multi-shape,
filtering, sleeping/wake — 37 tests green). What remains is the **facade surface**: the
`NapeNative` methods the game calls (`nape-world.ts:30–65`) that don't exist on `NapeReplica`
yet. All of it is plumbing over the finished solvers — **no engine/solver math changes.**

Reference implementation for every method below is `tools/nape/NapeWorld.hx` (the Haxe facade
`nape.js` was compiled from). Add these as methods on the `NapeReplica` class so
`new NapeReplica(gravity)` *is* a `NapeNative`. Line refs are into `nape-core.ts` as of this writing.

---

## 0. Shared plumbing (build these first)

### 0.1 World body at handle 0
Joints attach to "the world" via handle 0 (`createLevelJoint` passes `0` for a null side,
`nape-world.ts:260`). Create one static body and register it so the existing joint primitives
(`this.bodies.get(hA)`) resolve it.

```
// in the constructor, AFTER this.bodies is initialised:
this.worldBody = makeStaticBodyLiteral({ handle: 0, posx: 0, posy: 0, rot: 0 });
//   axisx=0, axisy=1, type=TYPE_STATIC, imass=0, iinertia=0, smass=0, sinertia=0,
//   sleeping=true, shapes=[], same field defaults as createBody() produces for a static body.
this.bodies.set(0, this.worldBody);
// MUST NOT: bump nextHandle, push to this.live. (Keeps it out of narrowphase / step / sleep.)
```
Verify nothing iterates `this.bodies.values()` over live bodies (today only `this.arbiters`
is iterated — safe). The world body being static+sleeping makes it inert everywhere.

### 0.2 `worldPointToLocal(b, px, py)` — world point → body-local anchor
The joint solvers read `a1local`/`a2local` as `a1rel = R·a1local` with `axisx=sin(rot)`,
`axisy=cos(rot)`, origin at `pos` (see `pivotPreStep` `c.a1relx = b1.axisy*a1localx − b1.axisx*a1localy`).
So the inverse is `Rᵀ·(P − pos)`:
```
const dx = px - b.posx, dy = py - b.posy;
return { x: b.axisy*dx + b.axisx*dy, y: -b.axisx*dx + b.axisy*dy };
```
`pos`/`axis` are the **post-finalize** values (origin already moved to COM by `align()`), which
is exactly what Nape's `worldPointToLocal` uses at joint-creation time. For the world body
(pos 0, rot 0) this returns `(px, py)` unchanged — correct.

### 0.3 `lookup(h)` + joint-partner graph
```
private lookup(h) { return this.bodies.get(h); }   // h===0 already resolves to worldBody
private jointPartners = new Map<number, number[]>();
private addPartner(hA, hB) {                         // NapeWorld.hx:358
  if (hA === 0 || hB === 0) return;
  (this.jointPartners.get(hA) ?? this.jointPartners.set(hA, []).get(hA)).push(hB);
  (this.jointPartners.get(hB) ?? this.jointPartners.set(hB, []).get(hB)).push(hA);
}
```

### 0.4 Event buffers + begin detection (for `takeContacts`/`takeImpacts`)
```
private contactsBuf: number[] = [];   // [hA,hB,sensorFlag, ...]
private impactsBuf:  number[] = [];   // [hA,hB,|normalImpulse|,nx,ny, ...]
private activeColPairs = new Set<string>();
private activeSenPairs = new Set<string>();
```
Add **one line** at the end of `step()`: `this.collectEvents();` — the only engine touch, and it
only reads solver output. `collectEvents()`:
- **Collisions:** iterate `this.arbiters.values()`; an arbiter is active this step iff
  `arb.stamp === this.stamp`. Build `nowCol` = set of those keys. For each key in `nowCol` not in
  `activeColPairs` → a *begin*: push `[arb.b1.handle, arb.b2.handle, 0]` to `contactsBuf`, and
  `[arb.b1.handle, arb.b2.handle, Math.abs(c1.jnAcc + (c2?.jnAcc ?? 0)), arb.nx, arb.ny]` to
  `impactsBuf` (sum the contacts' accumulated normal impulse; this is Nape's `normalImpulse`
  magnitude, the value `GameObj.as:3299` read for crate breaking). Set `activeColPairs = nowCol`.
- **Sensors** (the solver does NOT create arbiters for sensor pairs — `shouldCollide` filters them
  out, `nape-core.ts:127`): scan live body pairs like `narrowphase`, over **all shape pairs**; for a
  pair where `(sa.senGroup & sb.senMask) !== 0 && (sb.senGroup & sa.senMask) !== 0`, test overlap with
  `this.distanceQuery(A, sa, B, sb).d <= 0`. **`distanceQuery` is now total over every pairing**
  (circle-circle / circle-poly / **poly-poly** — `distancePolyPoly` was added in the poly-CCD work,
  so the old "throws for poly-poly" caveat is gone) and never throws here, so a single test covers
  all sensors incl. goals (sensor on `shapes[1]`). Use `distanceQuery(A, sa, B, sb)` per shape pair —
  NOT `distanceBetween(hA,hB)`, which only looks at `shapes[0]`. New overlaps (key not in
  `activeSenPairs`) → push `[hA, hB, 1]` to `contactsBuf`; update `activeSenPairs`.

Pair key: use the shape `sid`s (`a.sid < b.sid ? `${a.sid}-${b.sid}` : …`) so it survives the
per-shape-pair arbiter keying.

`takeContacts()` / `takeImpacts()`: `const c = this.contactsBuf; this.contactsBuf = []; return c;`
(same drain pattern as `NapeWorld.hx:234`).

---

## 1. Joint builders (the unblocker — `nape-world.ts:259` calls these)

Primitives are unchanged and take **local** anchors:
`addPivotJoint(hA,hB,a1x,a1y,a2x,a2y)` (`:1030`), `addWeldJoint(hA,hB,a1x,a1y,a2x,a2y,phase=0)`
(`:1049`), `addDistanceJoint(hA,hB,a1x,a1y,a2x,a2y,jointMin,jointMax)` (`:1068`).

### `jointRev(hA,hB,ax,ay, enableMotor,motorSpeed,maxTorque, enableLimit,lo,hi)` — NapeWorld.hx:378
```
const b1 = this.lookup(hA), b2 = this.lookup(hB);
if (!b1 || !b2 || b1 === b2) return;
this.addPartner(hA, hB);
const a1 = this.worldPointToLocal(b1, ax, ay);
const a2 = this.worldPointToLocal(b2, ax, ay);
this.addPivotJoint(hA, hB, a1.x, a1.y, a2.x, a2.y);
// Motor/limit: ALL 19 shipped rev joints have enableMotor=false AND enableLimit=false,
// so these branches are dead in practice. Include for safety, but note maxTorque is NOT
// honoured (motor jMax is hard-Infinity, nape-core.ts:2918) — fine, since it's unused:
if (enableMotor) this.addMotorJoint(hA, hB, motorSpeed, 1);
if (enableLimit) this.addAngleJoint(hA, hB, lo, hi, 1);
```

### `jointWeld(hA,hB,soft,freq)` — NapeWorld.hx:397
```
const b1 = this.lookup(hA), b2 = this.lookup(hB);
if (!b1 || !b2 || b1 === b2) return;
if (b1.type !== TYPE_DYNAMIC && b2.type !== TYPE_DYNAMIC) return;   // weld of two statics = no-op
this.addPartner(hA, hB);
const ax = b2.posx, ay = b2.posy;            // anchor = bodyB origin (the AS3 intent)
const phase = b2.rot - b1.rot;
const a1 = this.worldPointToLocal(b1, ax, ay);   // a2 is (0,0) by construction
this.addWeldJoint(hA, hB, a1.x, a1.y, 0, 0, phase);
// soft/freq: SKIP — 0 soft joints in any level.
```

### `jointDist(hA,hB,x0,y0,x1,y1,distLimit,soft,freq)` — NapeWorld.hx:411
```
const b1 = this.lookup(hA), b2 = this.lookup(hB);
if (!b1 || !b2 || b1 === b2) return;
this.addPartner(hA, hB);
const dx = x1 - x0, dy = y1 - y0;
const dist = Math.sqrt(dx*dx + dy*dy);
const minLen = Math.max(dist - distLimit, 0);
const maxLen = dist + distLimit;
const a1 = this.worldPointToLocal(b1, x0, y0);
const a2 = this.worldPointToLocal(b2, x1, y1);
this.addDistanceJoint(hA, hB, a1.x, a1.y, a2.x, a2.y, minLen, maxLen);
// soft/freq: SKIP.
```

---

## 2. Queries (read-only)

### `bodyContains(h,x,y)` — NapeWorld.hx:257
For each shape: circle → `(x−wc.x)² + (y−wc.y)² <= radius²` (wc = `shapeWorldCOM`); polygon →
transform `(x,y)` to local via `worldPointToLocal`, then convex point-test (point is left of
every edge `v[i]→v[i+1]`). Return true on first hit.

### `bodyArea(h)` — NapeWorld.hx:268
`b.shapes.reduce((a,s)=>a+s.area, 0)` (areas already computed in `validateShapeGeom`).

### `touchingBodies(h)` — NapeWorld.hx:329
Iterate `this.arbiters.values()`; for arbiters with `arb.stamp === this.stamp` (touching this
step) where `arb.b1===b || arb.b2===b`, push the OTHER body's handle if it's `TYPE_DYNAMIC`.
Collision arbiters only (sensor overlaps aren't arbiters, so they're naturally excluded).

### `raycastDown(x, fromY, maxDist, colCat)` — NapeWorld.hx:345
Ray from `(x, fromY)` direction `(0,+1)`, length `maxDist`. Filter matches Nape's
`new InteractionFilter(colCat, colCat, 0, 0)`: a shape is hit iff
`(colCat & shape.colMask) !== 0 && (shape.colGroup & colCat) !== 0`. For each matching shape
(static terrain is the usual target; include dynamic for fidelity), intersect the downward ray
with its world geometry: polygon → ray-vs-each-edge segment intersection; circle → ray-vs-circle.
Return the **nearest** hit's `y`; `NaN` if none. Self-contained read-only geometry — no solver state.

---

## 3. Lifecycle

### `setTransform(h,x,y,rotDeg)` — NapeWorld.hx:276
```
const b = this.bodies.get(h); if (!b) return;
if (b.type === TYPE_STATIC) return;                 // Nape forbids moving a static body
b.posx = x; b.posy = y; b.rot = rotDeg*Math.PI/180;
b.axisx = Math.sin(b.rot); b.axisy = Math.cos(b.rot);
// resync worldCOM and wake:
b.worldCOMx = b.posx + (b.axisy*b.localCOMx - b.axisx*b.localCOMy);
b.worldCOMy = b.posy + (b.localCOMx*b.axisx + b.localCOMy*b.axisy);
b.sleeping = false; b.waket = this.stamp;
```

### `setBodyType(h,type)` — NapeWorld.hx:211  (type: 0=static,1=dynamic, 2=kinematic→unused)
Set `b.type = (type===0 ? TYPE_STATIC : TYPE_DYNAMIC)`, then **re-validate mass props** so
imass/iinertia match the new type: re-run the body's `validateMassProps`/`align` path
(static ⇒ mass=STATIC_MASS, imass=0, iinertia=0, sleeping=true; dynamic ⇒ finite mass, wake).
Only static↔dynamic is needed (no kinematic in the data). This is the one lifecycle method that
must re-touch mass terms — keep it to the existing `validateMassProps` call, no new math.

### `setAwake(h,awake)` — NapeWorld.hx:291
Only the wake case is used: `if (awake) { b.sleeping = false; b.waket = this.stamp; }`.

### `wakeJointPartners(h)` — NapeWorld.hx:369
```
for (const ph of this.jointPartners.get(h) ?? []) {
  const b = this.bodies.get(ph);
  if (b && b.type === TYPE_DYNAMIC && b.sleeping) { b.sleeping = false; b.waket = this.stamp; }
}
```

---

## 4. Collision toggles (need an origin-mask stash)

Add `origColMask`/`origSenMask` to each shape at creation (= the colMask/senMask passed in), so a
toggle can restore exactly. `shouldCollide` already reads the live `colMask`; the sensor pass reads
`senMask`; setting either to 0 disables that interaction (an AND test fails on the zeroed side).

### `setBodyCollision(h,enabled)` — NapeWorld.hx:302
For every shape: if sensor → `s.senMask = enabled ? s.origSenMask : 0`; else
`s.colMask = enabled ? s.origColMask : 0`.

### `setBodyCollisionAboveTop(h,topThresholdPx,enabled)` — NapeWorld.hx:315
Same, but only for shapes whose top reaches above the threshold:
`topPx = b.posy − shapeAABB(h,i).miny`; skip shapes with `topPx <= topThresholdPx`. (One-way
keeper-duck: the tall idle shape toggles, the short crouch shape stays solid.)

---

## 5. Cutover wiring (`nape-world.ts`, my side once §1–4 land)

- Construct `NapeReplica` instead of `window.NapeWorld` when an engine flag is set (the project
  already has a planck/Nape engine switch in Settings — add a "Nape (replica)" option).
- `destroyBody(h)` should also drop the body's arbiters from `this.arbiters` and its
  `jointPartners` entries (avoid stale-handle leaks across level reloads).
- Validate level-by-level vs the original: joint-heavy first (weld 74 / rev 19 / dist 5), then
  ball-on-terrain (CCD), then crate levels (poly-poly). A/B diffs vs `nape.js` are EXPECTED — the
  replica matches the *original* engine, which is the point.

**Done =** every `NapeNative` method present (or proven-unused), `tsc --noEmit` clean, all replica
tests green, representative levels feel correct vs the original.
