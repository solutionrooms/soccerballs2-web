# Replica → Haxe game integration plan ("the glue")

**One-line goal:** make the live Haxe/OpenFL game (`haxe-port`, served on `localhost:8753`)
run on the bit-exact **replica** engine instead of `nape-haxe4`, so the physics *feel*
matches the 2012 original — **without changing the replica and without changing the game code.**

---

## Decisions (settled — don't re-litigate)

- **Target = the Haxe port** at `~/Projects/soccerballs2-web/haxe-port` (8753). It is a faithful
  Flash→Haxe port; OpenFL reproduces the Flash display list / SWF symbols / rigs / fonts for free.
  The TS/Vite port (`~/Projects/soccerballs2-web/src`) is **abandoned** — ignore it.
- **The problem is the engine, not the API.** Nape was one Haxe codebase cross-compiled to an AS3
  `.swc` (the original game) and to `nape-haxe4` (the port) — *same API*. The game shipped on
  **2012 Nape**; `nape-haxe4 2.0.22` is newer with a **refactored solver** → wrong feel. The
  **replica** (`src/physics/replica/nape-core.ts`) is a hand-rebuild of the 2012 engine, verified
  **bit-exact** (44 tests vs the original under Ruffle).
- **Engine stays TypeScript.** No Haxe re-port of the engine — it's pure math (no Flash deps),
  already verified; porting it would risk the exactness for ~zero benefit (both compile to the
  same JS). Ship it **verbatim** as a JS bundle.
- **Engine ships unchanged; game ships unchanged.** The only new code is a **Haxe `nape` package
  shim** that re-presents the `nape-haxe4` API the game already calls, routing every call to the
  replica's handle API. Swapped in by a build define so the game's `import nape.*` resolve to the
  shim with **zero edits to the ~350 game call-sites**.
- **Verification = behaviour, not bit-exactness, at the game level.** Levels **9** (wall bank shot)
  and **19** (rev joints) are the first acceptance gates. The strong follow-up idea: a **Ruffle
  game-state oracle** (capture per-frame object positions/scores/flags from the original SWF under
  Ruffle for fixed input, diff the running game against them). This is decoupled from the glue and
  verifies the *Haxe game + replica* directly.

---

## Architecture

```
Haxe game (unchanged)
  import nape.phys.Body / nape.space.Space / ...        ← resolves to the SHIM under -D replica
        │
        ▼
nape-shim/nape/**  (new Haxe; presents the nape-haxe4 API)
        │  calls
        ▼
rnape.NapeReplicaJS  (Haxe @:native extern → global `NapeReplica`)
        │  JS calls (cheap, same runtime)
        ▼
nape-replica.js  (esbuild bundle of src/physics/replica/nape-core.ts, UNCHANGED)
```

**Engine swap mechanism (zero game edits):** under `-D replica`, drop the `nape-haxe4` haxelib and
add the shim source — the game's `nape.*` imports bind to the shim instead.

```xml
<!-- project.xml -->
<haxelib name="nape-haxe4" unless="replica" />
<source path="nape-shim" if="replica" />
```
(Verify lime honours `if`/`unless` on these tags in Phase 1.)

---

## STATUS 2026-06-19 — shim built; Phases 1–5 implemented; compiles + builds clean

The full `nape.*` Haxe shim is written (`nape-shim/nape/**`, ~40 files) and the game
**compiles and builds clean under `-Dreplica`**. Verified:
- `haxe` typecheck of the WHOLE game against the shim: clean (0 errors).
- `lime build html5 -Dreplica`: exit 0. Output `SoccerBalls2.js` shrank 7.9MB→4.1MB and
  `grep zpp_nape` = 0 (nape-haxe4 fully removed); `new NapeReplica(` present (shim → engine).
- Template: fixed `::if (replica)::` → **`::if (SET_REPLICA)::`** (lime exposes the `-Dreplica`
  define to templates as `SET_<UPPERCASE>`); `bin/html5/bin/index.html` now loads `nape-replica.js`
  before the game. Bundle copied to `bin/` (126kb). Extern moved to `nape-shim/rnape/`.
- Default build (no define) still uses nape-haxe4 — unchanged, for A/B.

**Not yet runtime-verified in a browser** (the Claude-in-Chrome automation is network-isolated from
the host's localhost; a headless boot test was attempted). → user tests levels 9 & 19 on 8753.
**NOTE: hard-reload (Cmd+Shift+R) on 8753** — `SoccerBalls2.js` keeps its filename, so a cached
nape-haxe4 build can mask the new one.

### Known limitations / watch-outs baked into the shim (revisit if a level needs them)
- **ONGOING contacts not emitted.** The replica buffers BEGIN events only; the shim dispatches
  BEGIN collision/sensor → the four game listeners funnel to `BeginCollide`, but `OngoingCollide`/
  `OngoingSensor` (→ `onHitPersistFunction`) never fire. Affects **wind zones** (`OnHit_Wind`) and
  **weight switches** (`SwitchWeightHitPersist`). Likely absent from 9 & 19. Fixing requires a
  read-only `takeOngoing()` facade on the replica (not done — "don't change the replica").
- **Joint collide-ignore not forwarded.** `collide_joined=false` → nape `ignore=true` (jointed bodies
  don't collide) is not in the replica handle API; jointed bodies collide per their filters. If a
  level-19 pivot pair overlaps and jitters, this is why.
- **Rev motor/limit are dead no-ops** (`MotorJoint`/`AngleJoint` finalize do nothing) — correct per
  data (all 19 rev joints have motor+limit OFF); level 19 rev joints are pure pivots.
- **Conveyor `surfaceVel`** stored but not driven (no replica support) → conveyors won't convey.
- **Up-ray `rayCast`** (grass occlusion, `RemoveHiddenGrass`) returns null (replica only does
  `raycastDown`) → occluded grass stays visible. Cosmetic. Down-rays (character floor-snap) work.
- **CCD/bullet = false** for all bodies (the game never sets `isBullet`; faithful to the unmodified
  game). If the level-9 ball tunnels through the wall, reconsider.
- **Body.rotation** round-trips rad→deg→rad through `setTransform` (replica has no radian setter).

## Current state (Phase 0 — DONE & verified)

- **Bundle**: `src/physics/replica/bundle-entry.ts` (`globalThis.NapeReplica = NapeReplica`) →
  esbuild → `haxe-port/templates/html5/template/nape-replica.js` (124kb). Verified in Node:
  built a ball-on-floor sim through the handle API, ball rests at y=268.20, all methods present.
  Rebuild command:
  ```
  cd ~/Projects/soccerballs2-web && node_modules/.bin/esbuild \
    src/physics/replica/bundle-entry.ts --bundle --format=iife --target=es2017 \
    --legal-comments=none --outfile=haxe-port/templates/html5/template/nape-replica.js
  ```
- **Extern**: `haxe-port/src/rnape/NapeReplicaJS.hx` — full handle API. (Phase 1: consider moving it
  under `nape-shim/` so the default build carries zero replica code.)
- **Loader**: `templates/html5/template/index.html` has a `::if (replica)::<script src="./nape-replica.js">::end::`
  before the game script. (Verify the `replica` define reaches lime template processing.)

---

## The replica handle API (what the shim calls) — `rnape.NapeReplicaJS`

Pixels throughout. Density passed **raw** (replica divides by 1000 internally, like nape). **Handle 0
= the static world body** (joints attach to "the world").

- `new NapeReplica(gravityPxY)`, `setGravity(g)`
- `createBody(isStatic,x,y,rotDeg,linDamp,angDamp) → Int`
- `addCircle(h,posX,posY,radius,density,friction,rolling,elasticity,colCat,colMask,isSensor)`
- `addPolygon(h,vertsFlat:Array<Float>,density,friction,rolling,elasticity,colCat,colMask,isSensor)`
- `finalizeBody(h,bullet)`, `destroyBody(h)`
- `step(dt,velIters,posIters)`
- getters: `getX getY getRot(°) getRotRad getVX getVY getAngVel getMass getInertia isDynamic`
- ops: `setVel setAngVel setTransform setBodyType(0/1/2) setAwake applyImpulse wakeJointPartners`
  `setBodyCollision setBodyCollisionAboveTop`
- queries: `bodyContains bodyArea touchingBodies raycastDown(→NaN if miss)`
- joints (world anchors; handle 0 = world): `jointRev(hA,hB,ax,ay,enableMotor,motorSpeed,maxTorque,enableLimit,loRad,hiRad)`,
  `jointWeld(hA,hB,soft,freq)`, `jointDist(hA,hB,x0,y0,x1,y1,distLimit,soft,freq)`
- events (drain per step): `takeContacts():Array<Int>` = `[hA,hB,sensorFlag,...]`;
  `takeImpacts():Array<Float>` = `[hA,hB,|normalImpulse|,nx,ny,...]`

---

## Integration surface (what the game actually uses — the shim's required members)

Game touches `nape-haxe4` in ~350 sites: GameObj.hx (136), GameObjBase.hx (113), PhysicsBase.hx
(105), Game.hx (21), NapeContacts.hx (15), Grass.hx, GOHelpers.hx.

**Imports to satisfy (each needs `nape/<pkg>/<Name>.hx` in the shim):**
`geom.Vec2`(25 new), `geom.Vec3`, `geom.Vec2List`, `geom.GeomPoly`, `geom.Ray`+`RayResult`,
`phys.Body`(3 new), `phys.BodyType`, `phys.Material`, `phys.BodyList`,
`shape.Circle`(2 new) `shape.Polygon`(3 new) `shape.Shape`, `dynamics.InteractionFilter`(8 new),
`space.Space`(3 new),
`constraint.{Constraint,PivotJoint,WeldJoint,DistanceJoint,AngleJoint,MotorJoint}`,
`callbacks.{InteractionListener(4 new),InteractionCallback,CbType(1 new),CbEvent,InteractionType,PreListener,PreFlag,PreCallback,BodyCallback}`,
`dynamics.{Arbiter,CollisionArbiter,ArbiterList,Contact}`, `util.{Debug,BitmapDebug}`.

**Enums used:** `BodyType.{DYNAMIC,KINEMATIC,STATIC}`, `CbEvent.{BEGIN,ONGOING}`,
`InteractionType.{COLLISION,SENSOR}`.

**Lifecycle the shim must honour (from `PhysicsBase.InitNape`):**
- `new Space(new Vec2(0,gravity), null)` ×3 (space0/1/2; game runs `current_space`, default space0).
- `new CbType()`, then 4 `new InteractionListener(CbEvent.X, InteractionType.Y, cb, cb, handler)`
  added via `space.listeners.add(...)`. Handlers: `NapeContacts.{BeginCollide,OngoingCollide,BeginSensor,OngoingSensor}`.
- step: `space.step(dt,10,10)`.

**Body lifecycle (nape pattern):** `new Body(type,pos)` → `body.shapes.add(shape)` (buffered) →
`body.space = space` (this FINALIZES: replica.createBody + addCircle/addPolygon per buffered shape +
finalizeBody). `body.space = null` destroys.

**Body members the game reads/writes (GameObjBase ~1660-1890):** `position`(.x/.y/.setxy — LIVE
proxy, writes teleport the body), `velocity`(.x/.y/.setxy/.addeq — LIVE proxy → setVel),
`rotation`(get/set), `angularVel`(get/set), `mass`, `type` (== BodyType.X), `applyImpulse(Vec2)`,
`shapes`, `arbiters`, `userData`. Weld wake: `weld.body1/body2`, `.type`, `.applyImpulse`.

**Contacts (NapeContacts.hx):** handlers read `cb.arbiters:ArbiterList`, `arbiter.isCollisionArbiter()`/
`isSensorArbiter()`, `arbiter.collisionArbiter:CollisionArbiter`, `ca.normalImpulse(...)` (Vec3),
`arbiter.shape1/shape2` (→ material id, for the mud/grass probe + crate breaking). `ProbeLog` is
diagnostic only.

**Joints (PhysicsBase.AddJoint_Nape ~567-800):** builds rev/weld/dist. **Level data facts:** weld 74,
rev 19 (ALL `enablemotor=false` AND `enablelimit=false` → pure pivots), dist 5, **0 soft**, no
kinematic, no prismatic. So `jointRev` reduces to pivot; soft/motor/limit paths are dead.

---

## Phased build

### Phase 1 — Scaffold + build swap compiles (no behaviour yet)
- Add `nape-shim/` source + `project.xml` conditional (`unless/if="replica"`). Move/keep the extern.
- Create EVERY imported `nape.*` class as a minimal stub (compiles, methods no-op/throw-TODO) so a
  `lime build html5 -Dreplica` **compiles clean**. (Verify rigorously: output JS timestamp changed +
  grep for a shim-only symbol — lime can silent-fail; "error" isn't in Haxe error lines.)
- Confirm `nape-replica.js` is copied into `bin/html5/bin/` by the template, and the `<script>` loads.
- **Gate:** `-Dreplica` build compiles and boots to the menu (physics may be inert).

### Phase 2 — Core: bodies + step + shapes (the engine visibly runs)
- `Vec2` (value mode + bound/proxy mode for `body.position`/`velocity`), `Vec3`, `Vec2List`.
- `BodyType`, `Material`, `InteractionFilter`, `Shape`/`Circle`/`Polygon`.
- `Body` (defer `createBody` until `space=` set; proxy accessors; impulse; type; userData; shapes).
- `Space` (gravity, `world` handle 0, `bodies`, `listeners`, `step` → `replica.step` + read-back).
- **Gate:** a level loads under `-Dreplica`; terrain is solid, the ball falls/rolls and **renders in
  the right place** (positions read back from the replica). No scoring/contacts yet.

### Phase 3 — Joints
- `Constraint` + the 5 joint types → `jointRev/jointWeld/jointDist` (world↔local anchor mapping per
  the facade; soft/motor/limit are dead per data but keep faithful). `WakeWeldedBodies` →
  `wakeJointPartners`.
- **Gate:** **level 19** rev-joint objects swing/behave correctly.

### Phase 4 — Contacts / sensors (gameplay events)
- `InteractionListener`/`InteractionCallback`/`CbType`/`CbEvent`/`InteractionType`.
- `Arbiter`/`CollisionArbiter`/`ArbiterList`/`Contact` carrying body handles, `normalImpulse` (from
  `takeImpacts`), and `shape1/shape2`→material (map handle→body→shape; bodies are ~single-shape).
- `Space.step` drains `takeContacts`/`takeImpacts` after `replica.step` and dispatches to the
  registered BEGIN/ONGOING × COLLISION/SENSOR listeners with shim callbacks. (Nape fires mid-step;
  game reads contacts in its post-step update, so post-step dispatch is fine — verify ordering.)
- `PreListener`/`PreFlag`/`PreCallback`: the MAX-elasticity PreListener was reverted; if no active
  registration remains, stub. (Check before relying.)
- **Gate:** scoring, coin sensors, goal, breakable crates (via `normalImpulse`) fire → **level 9**
  bank shot completes and reads/feels right.

### Phase 5 — Queries + misc
- `Ray`/`RayResult` → `raycastDown` (floor detection: characters/Grass). `GeomPoly` (ensure convex
  pieces fed to `addPolygon`; replica does NOT decompose). `Debug`/`BitmapDebug` → no-op. lists.
- **Gate:** characters/grass floor-snap; no missing-symbol crashes anywhere in 9 & 19.

### Phase 6 — Verify
- Build `-Dreplica`, rigorous verify, user tests **level 9** + **level 19** on device (the badge can
  show which engine; cf. the TS port's engine badge).
- (Stretch) Ruffle game-state oracle: capture original traces for a fixed input on 9 & 19, diff the
  running game — automated behavioural proof. Needs game determinism (physics ✓; seed audio/particle RNG).

---

## Risks / watch-outs

- **Vec2 proxy mutability** is the trickiest core bit: `body.position.setxy(x,y)` and
  `body.velocity.x = v` must write through to the body. Standalone `new Vec2(x,y)` stays a plain value.
- **3 spaces** (space0/1/2) → 3 replica instances; honour `current_space`.
- **Contact dispatch ordering** vs nape's mid-step firing — game logic reads after step, so OK, but verify.
- **`normalImpulse` / `shape1/shape2`**: replica events give handles + magnitude + normal, not shapes;
  reconstruct shapes/material from the body for the crate-break + friction-probe paths.
- **GeomPoly**: replica expects convex; decompose in the shim (or confirm game feeds convex).
- **Density**: pass raw AS3 density (replica /1000). Confirm parity with what nape-haxe4 received.
- **Lime silent build failure**: ALWAYS verify by (a) output timestamp changed AND (b) grep a NEW
  shim-only symbol. Haxe error lines don't contain the word "error".
- **`setBodyType`** (static↔dynamic) in the replica is implemented but not runtime-tested; eyeball if
  any of 9/19 switch body type live.
- Keep the **default (non-replica) build** working throughout (it still uses nape-haxe4) for A/B.

---

## Quick reference — key files

- Replica (DO NOT EDIT): `~/Projects/soccerballs2-web/src/physics/replica/nape-core.ts`
- Bundle entry: `src/physics/replica/bundle-entry.ts` → `haxe-port/templates/html5/template/nape-replica.js`
- Extern: `haxe-port/src/rnape/NapeReplicaJS.hx`
- Shim (to build): `haxe-port/nape-shim/nape/**`
- Game physics: `haxe-port/src/{PhysicsBase,GameObjBase,GameObj,NapeContacts,Grass,Game}.hx`
- Build: `cd haxe-port && lime build html5 -Dreplica` (default build omits the define → nape-haxe4)
- Original AS3 source (port reference): `~/Projects/SoccerBalls2/src`
- Level data: `~/Projects/SoccerBalls2/bin/SoccerBalls2_Levels_Data.xml`
