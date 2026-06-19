# Interface compatibility — replica vs the existing `nape.js`

To replace the compiled `nape.js` at runtime, the replica (`NapeReplica`) must
satisfy the handle-based facade the game actually calls — the **`NapeNative`**
interface in `src/physics/nape-world.ts` (`window.NapeWorld`). This is the
drop-in contract. Below is every method of that contract and the replica's status.

Legend: ✅ implemented & bit-exact · 🟡 solver done, thin adapter still needed ·
⬜ not yet implemented (no simulation-math risk) · ❎ not needed (confirmed unused).

## The contract, method by method

| `NapeNative` method | Status | Notes |
|---------------------|:------:|-------|
| `setGravity(g)` | ✅ | |
| `createBody(isStatic,x,y,rotDeg,linDamp,angDamp)` | ✅ | |
| `addCircle(h,…,colCat,colMask,isSensor)` | ✅ | colCat/colMask/isSensor stored; filtering ⬜ |
| `addPolygon(h,verts,…,colCat,colMask,isSensor)` | ✅ | convex pieces (decomposition out of the bit-exact loop) |
| `finalizeBody(h,bullet)` | ✅ | bullet flag accepted; auto-sweep already arrests fast bodies |
| `step(dt,velIters,posIters)` | ✅ | full pipeline incl. continuous collision |
| `destroyBody(h)` | ✅ | |
| `getX` `getY` `getRot` `getRotRad` `getVX` `getVY` `getAngVel` | ✅ | all seven |
| `getMass(h)` | ✅ | |
| `getInertia(h)` *(extra)* | ✅ | replica exposes this too |
| `isDynamic(h)` | ✅ | |
| `setVel(h,vx,vy)` | ✅ | |
| `setAngVel(h,w)` | ✅ | |
| `applyImpulse(h,jx,jy)` | ✅ | central impulse |
| `jointRev(hA,hB,ax,ay,enableMotor,motorSpeed,maxTorque,enableLimit,lo,hi)` | 🟡 | **solvers done** — compose `addPivotJoint` + (optional) `addMotorJoint` + (optional) `addAngleJoint`. Needs the builder + `maxTorque`→`maxForce` and world-anchor→local-anchor mapping. |
| `jointWeld(hA,hB,soft,freq)` | 🟡 | `addWeldJoint` done. Builder must derive the two local anchors from current world transforms; `soft`/`freq` ❎ (0 soft joints in any level). |
| `jointDist(hA,hB,x0,y0,x1,y1,distLimit,soft,freq)` | 🟡 | `addDistanceJoint` done. Builder maps world anchors → local + `distLimit`→`jointMin/Max`; `soft`/`freq` ❎. |
| `raycastDown(x,fromY,maxDist,colCat)` | ⬜ | downward ray vs static geometry (floor detection). Self-contained read-only query. |
| `takeContacts()` | ⬜ | per-step contact list for game logic (`headless.ts`). Arbiters exist internally; needs an export buffer. |
| `takeImpacts()` | ⬜ | impact (first-touch) list — drives switches (`switches.ts onImpact`). |
| `touchingBodies(h)` | ⬜ | query over the body's active arbiters. |
| `setAwake(h,awake)` | ⬜ | sleeping system (see below). |
| `wakeJointPartners(h)` | ⬜ | sleeping + joint graph. |
| `setBodyType(h,type)` | ✅ | static / dynamic / **kinematic** (type 2). Kinematic = no align, no gravity, infinite mass, position-from-velocity, carries riders. `p0kn` (bit-exact motion) + `p0kn-kinematic` (behavioural carry). |
| `setTransform(h,x,y,rotDeg)` | ⬜ | teleport/reposition. |
| `bodyContains(h,x,y)` | ⬜ | point-in-shape query. |
| `bodyArea(h)` | ⬜ | sum of shape areas (already computed internally). |
| `setBodyCollision(h,enabled)` | ✅ | collision on/off toggle (zero/restore masks); now also drops stale already-touching arbiters + wakes the dynamic side. |
| `setBodyCollisionMask(h,mask)` *(extra)* | ✅ | **runtime mask change** (game `SetBodyCollisionMask`; level-19 disappearing switches). Sets `colMask=mask` on non-sensor shapes, drops now-non-colliding arbiters, wakes the resting body. `p0sw` (bit-exact) + `p0sw-switchmask` (behavioural wake). |
| `setBodyCollisionGroup(h,group)` *(extra)* | ✅ | runtime group change (symmetric; solver). `p0rf` behavioural; bit-exact mechanism shared with `p0sw`. *(game doesn't change group at runtime — added for safety.)* |
| `setBodySensorMask(h,mask)` *(extra)* | ✅ | **runtime sensor-mask change** (game `SetBodySensorMask`; flying-bird hit-detect toggle 0↔8). Sets `senMask` on all shapes → gates `collectEvents` overlaps. `p0rf`. ⚠️ bird needs independent sensor filters — see below. |
| `setBodySensorGroup(h,group)` *(extra)* | ✅ | runtime sensor-group change (events only). `p0rf`. |
| `setBodySensorEnabled(h,sensor)` *(extra)* | ✅ | runtime `shape.sensorEnabled` toggle (collider↔sensor swap; drops contacts + wakes when becoming a sensor). `p0se` (bit-exact). |
| `setBodyCollisionAboveTop(h,topPx,enabled)` | ✅ | one-way platform / keeper duck (toggle only shapes whose top reaches above the threshold). |

## ⚠️ Solver coverage — read this before trusting "✅" above

The facade table above tracks *API surface*, not *physics breadth*. The simulation
math that IS wired is bit-exact — but it is **narrower than a naive read suggests**,
and some unimplemented cases **hard-throw** (killing the frame) rather than no-op.
Bit-exact narrowphase *manifolds* exist for all three pairings (M3 tests), but only
some are *wired into the solver*:

| Collision case | Manifold | Wired to solver | Status |
|----------------|:--------:|:---------------:|--------|
| circle ↔ polygon **face** | ✅ | ✅ | done, tested, CCD too |
| circle ↔ polygon **vertex/corner** | ✅ | ✅ | **DONE** — ptype 2 wired (narrowphase + iteratePos); gated by `p0a-vertex.test.ts` |
| circle ↔ circle | ✅ | ✅ | **DONE** — ptype 2; single-dynamic (`p0cc`), **dynamic-dynamic ball↔ball** (`p0cc2`), and circle-circle CCD, all bit-for-bit |
| polygon ↔ polygon (resting/stacking) | ✅ | ✅ | **DONE** — full SAT/clip arbiter + **two-contact block solver** (`hc2` velocity LCP + `hpc2` position solve); gated bit-exact by `p0pp.test.ts` (box settling on a static floor). Crates rest & stack. |
| polygon ↔ polygon (**rotating/tumbling**) | ✅ | ✅ | **DONE** (logic bit-exact) — poly continuous-collision sweeps the rotating crate (rewind-to-TOI + freeze). `p0ppr.test.ts`: bit-exact 10 steps with the sweep engaged, then trig-limited (the sensitive corner-tip amplifies the V8/AVM2 `Math.sin/cos` ≤1-ULP ceiling) → settles to the same pose. |
| poly-poly closest distance | ✅ | ✅ | **DONE** — `distancePolyPoly` (SAT + segment-segment closest pair / overlap clip); gated bit-exact by `p0pd.test.ts` (6 cases, both arg orders). |
| multi-shape bodies | ✅ | ✅ | **DONE** — narrowphase + CCD loop ALL shape pairs; arbiters keyed per shape-id pair. `p0ms.test.ts` (ball lands on `shapes[1]`, bit-exact). |
| collision filtering + sensors | ✅ | 🟡 | **DONE for collider XOR sensor** — `shouldCollide` filter in narrowphase + CCD; sensors excluded from the solver, overlaps detected in `collectEvents`. Runtime changes wired (`setBodyCollision{Mask,Group}`, `setBodySensor{Mask,Group,Enabled}`). **LIMITATION:** a shape carries ONE category (`makeFilter` is collider XOR sensor), so a solid body has `sensorGroup=0` and cannot be detected by a sensor (the flying bird vs the solid ball). Fixing needs `addCircle/addPolygon` extended to **independent sensor cat/mask** + the shim passing them. Not yet needed by the gated levels. `p0fl.test.ts` (bit-exact). |
| sleeping (atRest + island + wake) | ✅ | ✅ | **DONE** — `doForests` islands + atRest + 60-stamp freeze + wake-on-contact. `p0sl.test.ts` (240-step stack sleeps at step 67) + `p0wk.test.ts` (sleeping ball woken by an impact). |
| kinematic bodies | ✅ | ✅ | **DONE** — `TYPE_KINEMATIC` via `setBodyType(h,2)`: no align (keeps registration origin), no gravity, infinite mass, integrates position from its set velocity, carries riders via the contact solver. Used by referees + moving platforms/lifts/switch-walls (`SetBodyXForm`). `p0kn.test.ts` locks the kinematic motion + offset-origin bit-exact; `p0kn-kinematic.test.ts` covers the carry. **Caveat:** rider-carry CONTACT-ONSET timing follows Nape's component sleep/wake lifecycle (replica uses a simpler island model) → behavioural, not bit-exact (converges to the same carried motion). |

> **Arbiter solve order (fixed during circle-circle).** Coupled contacts must be
> solved in Nape's order — both-dynamic first (sorted by depth), has-static last —
> in warmStart AND every velocity/position sweep, or a body shared by multiple
> contacts (ball-on-ball-on-floor) diverges. Implemented as `orderedActiveArbiters()`.

**So:** ball-on-polygon (face + corner), **circle-circle (incl. ball↔ball)**, and CCD
are done and game-usable. Still gating: **polygon-polygon** solver wiring + the
two-contact block solver (P0 — crates). See "Remaining solver work" below.

## Summary (API surface)

- **The contact/joint math that IS wired is bit-exact** — integration, circle-poly-face
  contacts, continuous collision, and all five joint solvers, verified vs the original
  Nape AS3. But several collision cases the game needs are **not yet wired** (table
  above) — that is the real gating work, not the facade plumbing.
- **19 facade methods are implemented and signature-compatible today**
  (setGravity, createBody, addCircle, addPolygon, finalizeBody, step, destroyBody,
  the 7 getters, getMass, isDynamic, setVel, setAngVel, applyImpulse).
- **3 joint builders (🟡)** are thin adapters over solvers that already exist — they
  translate the game's world-anchor/limit/motor parameters into the replica's
  `add*Joint` primitives. No new physics.
- **12 methods (⬜) remain**, none of which carry simulation-math risk:
  - *Queries* (read-only, no state change): `raycastDown`, `touchingBodies`,
    `bodyContains`, `bodyArea`.
  - *Collision events* (game logic): `takeContacts`, `takeImpacts`.
  - *Lifecycle*: `setBodyType`, `setTransform`.
  - *Sleeping*: `setAwake`, `wakeJointPartners`.
  - *Collision filtering / one-way platforms*: `setBodyCollision`,
    `setBodyCollisionAboveTop` (+ honouring `colCat`/`colMask`/`isSensor`, which are
    already stored on shapes).
- **Confirmed NOT needed (❎):** soft/elastic constraints (`soft`/`freq`) — the
  level-data audit found **0** soft joints across every level, so those code paths
  can be skipped entirely.

## Remaining solver work (gating — must precede the facade plumbing)

These are NOT facade adapters — they are bit-exact solver work, each needing its own
captured golden:

1. ~~**P0 — circle-vertex contact**~~ ✅ **DONE** — ptype 2 wired (narrowphase build +
   `iteratePosVertex`), gated by `p0a-vertex.test.ts`. Terrain corners no longer throw.
2. ~~**P0 — circle-circle**~~ ✅ **DONE** (incl. dynamic-dynamic + CCD + the coupled-
   contact solve-order fix). **Poly-poly still P0** — manifold done (M3c); needs the
   **two-contact block solver** (the `hc2` path in prestep/iterateVel/iteratePos,
   currently throws). The arbiter spec + block-solver source are fully read; this is
   a focused ~250-line port + golden, the next big piece.
3. **P1 — multi-shape bodies**: loop all shape pairs in `narrowphase()`, not `[0]×[0]`.
4. **P1 — kinematic body type**: add `TYPE_KINEMATIC`; integrate its velocity in
   `updatePos`; carry riders.
5. **P2 — poly-poly CCD distance** (`distanceQuery` currently throws) — only if a
   polygon is bullet/fast.
6. **Check motor `maxTorque`**: `addMotorJoint` hard-codes `jMax = Infinity`; the
   original `jointRev` sets `motor.maxForce = maxTorque`. Wire it if any level uses a
   finite motor torque.

## Recommended cutover order (facade — only after the solver work above)

Per the game-needs audit (`memory/nape-replica-game-needs-audit.md`):

1. **Joint builders** `jointRev` / `jointWeld` / `jointDist` — unblocks every level
   that uses joints (weld 74, rev 19, dist 5), with no new physics.
2. **Collision filtering + sensors** + **contact/impact events** — gameplay logic
   (scoring, switches, one-way platforms).
3. **`raycastDown`** — floor detection (characters, grass).
4. **Sleeping** (`setAwake`, `wakeJointPartners`) + lifecycle
   (`setBodyType`, `setTransform`) + the remaining queries.
5. **Cutover behind an A/B flag**, validating against `nape.js` on real levels.
