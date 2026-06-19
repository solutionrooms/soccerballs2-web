# claude-nape-replica.md — context for the nape-replica engine session

> One of three context files (load `claude.md` for shared context first):
> - `claude.md` — shared context (both sessions)
> - **`claude-nape-replica.md`** — *this* session: owns/tests the bit-exact replica engine
> - `claude-haxe-port.md` — the other session: edits the live Haxe game

---

## My role (remit)

I **manage and test the nape-replica physics engine only**. I keep it bit-exact to the
2012 original Nape and keep its contract docs accurate. I do **not** edit game code — I
read it to understand the contract, and **flag** any change I think is needed outside my
remit rather than make it.

**I own (edit freely):**
- `src/physics/replica/` — the engine `nape-core.ts` (`class NapeReplica`), all `*.test.ts`,
  `original-goldens/`, `diff.ts`, `bundle-entry.ts`, and the engine docs
  (`INTERFACE-COMPAT.md`, `FACADE-SPEC.md`, `TESTS.md`, `milestones/`).
- `tools/nape-oracle/` — the AS3 oracle harnesses + capture pipeline.

**Read-only / flag-only (other session's remit):**
- `haxe-port/` — the live Haxe/OpenFL game (served on `localhost:8753`).
- `haxe-port/nape-shim/` — the Haxe glue (`nape/**` API shim + `rnape/NapeReplicaJS.hx`).
  This sits **on the boundary**: the shim *implementation* is the other session's to edit,
  but I keep the **handle-API contract** it depends on correct and documented
  (INTERFACE-COMPAT.md / FACADE-SPEC.md). Contract mismatches → I flag, not edit.

**Reference (read-only):**
- `/Users/jonscott/Projects/SoccerBalls2/` — the **original 2012 AS3 Flash game source**.
  This is a *sibling* repo, not under soccerballs2-web. Source of truth for behaviour.
- `tools/swf-decomp/scripts/zpp_nape/` — decompiled AS3 of the **shipped** 2012 Nape
  (`release_nape.swc`). This — NOT `nape.js`, NOT `nape-haxe4` — is what I port bit-for-bit.

---

## Repo geography (post "TS-is-defunct")

| Path | What | Status |
|------|------|--------|
| `~/Projects/SoccerBalls2/` | Original 2012 AS3 Flash source | Reference, read-only |
| `~/Projects/soccerballs2-web/src/` (game) | TS/Vite/planck web port | **ABANDONED — ignore** |
| `~/Projects/soccerballs2-web/src/physics/replica/` | **My replica engine** | **LIVE** — the deliverable |
| `~/Projects/soccerballs2-web/haxe-port/` | Haxe/OpenFL port (`:8753`) | **LIVE game** — other session |

"TS conversion is defunct" means the TS **game** is dead. The replica **engine** stays
TypeScript on purpose (pure math, no Flash deps, already verified) and ships **verbatim** as
a JS bundle — re-porting it to Haxe would risk the exactness for zero benefit. The fixed
point is `nape-core.ts`: **never edit the engine to accommodate the shim/game** — the game
adapts to the engine, never the reverse.

### Integration path (how the engine reaches the game)
```
nape-core.ts (UNCHANGED)
  → bundle-entry.ts (exposes global NapeReplica)
  → esbuild → haxe-port/.../nape-replica.js
  → rnape.NapeReplicaJS.hx (@:native extern → global NapeReplica)
  → nape-shim/nape/**  (Haxe; re-presents the nape-haxe4 API the game calls)
  → game's `import nape.*` resolve to the shim under `-D replica` (zero game edits)
```
Plan: `haxe-port/docs/replica-integration-plan.md`. Game-level verification is **behavioural**
(levels 9 = wall bank shot, 19 = rev joints), not bit-exact — that's the other session's gate.

---

## What "bit-exact" means here (the core method)

Differential testing vs goldens captured from the **real original Nape AS3 run under Ruffle**,
compared as raw IEEE-754 bits (hex16), not floats:
- `f64hex(x)` → 16 hex chars; tests assert `expect(hex16(got)).toBe(norm(goldenPair))`.
- AVM2 (Flash/Ruffle) and V8 give **identical** `+ − × ÷ √` and the Quake fast-inverse-sqrt,
  so almost everything is reproducible to the bit.
- **The one fundamental gap — the "trig ceiling":** `Math.sin/cos` differ by **≤1 ULP**
  between V8 and AVM2 for *some* accumulated angles. Input-specific: a fast spin can stay
  exact for 180 steps; a pendulum or a corner-tip diverges. This is NOT a logic bug and
  cannot be closed without reimplementing trig. Only bites **continuously rotating** bodies.

### Step pipeline order (load-bearing — `ZPP_Space.step`)
```
stamp++ → validateWorldCOM → narrowphase → doForests → prestep → updateVel
  → warmStart → iterateVel → updatePos → continuousCollisions → iteratePos
  (→ collectEvents, for the facade)
```

---

## Oracle toolchain (capture a new golden)

All paths relative to `soccerballs2-web/`. macOS has **no `timeout`**; java is **JDK 21**.

1. Write `tools/nape-oracle/harness-X.as` — document class `Preloader`, traces
   `[TAG] i <field-bits>...`, dump raw bits via `ByteArray.writeDouble` → two `readUnsignedInt`
   hex words (`hi:lo`).
2. Inject into the real SWF (provides the genuine 2012 `nape.*`):
   ```
   java -jar tools/vendor/ffdec.jar -replace haxe-port/assets/SoccerBalls2.swf \
        tools/nape-oracle/X-oracle.swf Preloader tools/nape-oracle/harness-X.as
   ```
3. Run under Ruffle headless + capture to JSON:
   ```
   node tools/nape-oracle/capture-lines.mjs tools/nape-oracle/X-oracle.swf \
        src/physics/replica/original-goldens/X.json DONE
   ```
4. Add `src/physics/replica/X.test.ts` that reconstructs the same scene on `NapeReplica`
   and asserts `hex16` equality every step/field. Run with vitest.

Golden line format the tests parse: `[TAG] i field1 field2 ...` where each field is `hi:lo`;
`norm(pair)` zero-pads to the 16-char hex. Filter out the `DONE` sentinel line.

---

## Current status (engine — as of 2026-06-19)

**Engine is complete and bit-exact** across E1 (poly-poly + 2-contact block solver), E2
(filtering / sensors / multi-shape), E3 (sleeping / islands / wake). Facade implemented and
wired behind `?physics=replica` / `setReplicaEngine(true)` (default OFF).

### Full bit-exact gates (strict `hex16().toBe(norm())`, every step/field)
m0-freefall · m1-rotation · m2-aabb · m3-circle · m3b-circlepoly · m3c-polypoly ·
m4-solver · m4cd-distance · m4d-discrete · m5a-angle · m5b-pivot-notrig · m5d-distance-notrig ·
m5m-motor · m5w-weld-notrig · p0a-vertex · p0cc-circlecircle · p0cc2-dyndyn · p0pp ·
p0pd · p0fl · p0ms · p0sl · p0wk · **p0kn** (kinematic motion + offset-origin) ·
**p0sw** (runtime collision-mask change → free-fall) · **p0se** (runtime sensorEnabled toggle → free-fall) ·
**p0bn** (restitution on a 2-contact terrain seam, via CCD) ·
**p0rm** (wake-on-body-removal — ball asleep on a block falls when block destroyed) ·
**p0wv** (wake-on-velocity-mutation — `applyImpulse`/`velocity=` on a sleeping ball wakes+launches it) ·
**p0om** (offset-COM body reports the placement origin, no auto-align) ·
**p0og** (ONGOING contact events — fires every awake step a pair persists, stops on sleep; step-for-step vs SWF) ·
**p0kr** (kinematic-vs-resting-dynamic restitution — moving kinematic wall bounces a resting ball ahead, no stick) ·
p0tr-terrain + p0sw-switchmask + p0kn-kinematic + p0rf-runtimefilters + p0wv-setangvel + p0kd-keeperduck (behavioural)

### Wake-on-removal fix (2026-06-19)
`destroyBody` dropped arbiters/constraints referencing the removed body but left the **partner asleep**
→ a dynamic ball sleeping on a destroyed `sand_block` stayed frozen mid-air. Fix: wake the other body
in each dropped arbiter/constraint (`wakeBody`). Verified BIT-EXACT against the **shipped** SoccerBalls2
Nape (`p0rm`, 180 steps) — important because Julian noted Luca had fixed this and worried about Nape
versions: the oracle runs the actual shipped bytecode, so it confirmed the fix is *present in the 2012
build* (matches decompiled `removed_shape`→`body.wake()`, `ZPP_Space.as:2353/2388`). General reassurance:
every gate is captured from the shipped SWF, so a version mismatch can't creep in silently.

### Wake-on-velocity-mutation fix (2026-06-19)
Same *class* of gap as wake-on-removal, found by auditing the facade for "mutates a body but forgets
to wake it." `setVel`/`setAngVel`/`applyImpulse` set velocity but never woke the body → a kick/launch
on a ball that had been at rest >~1s (asleep) was **silently discarded** (the body stayed asleep, skipped
integration). Nape wakes on all three (`Body.velocity`→`vel_invalidate`→`invalidate_wake`, `ZPP_Body.as:291`;
`set angularVel` if-changed, `Body.as:1234`; `applyImpulse` guarded DYNAMIC, `Body.as:2467`). Fix: each calls
`wakeBody(b)` (`setAngVel` keeps Nape's `if(angvel != w)` change-guard). Verified BIT-EXACT vs the shipped
SWF (`p0wv`, 140 steps: two balls sleep at 368.200, kicked at step 90 → wake/launch/re-settle); `setAngVel`
shares the path, covered behaviourally.

### Offset-COM / align-removal fix (2026-06-19)
`finalizeBody` (and `setBodyType`'s dynamic branch) **auto-`align()`ed every dynamic body onto its COM**, so
`getX/getY` returned the COM not the placement origin → broke offset-shape characters (level-7 `opponent_patrol`
turn-around `|marker.y − opp.y| < 20`: real 12 ✓, replica 28 ✗). Root cause: `align()` was copied from the
**defunct Box2D-parity `tools/nape/NapeWorld.hx:201`**; the original 2012 AS3 calls `align()` zero times and
real Nape never auto-aligns — it keeps `position` at the origin and integrates rotation about `worldCOM`. Fix:
dropped both `align()` calls (→ `validateMassProps` only, no posx/posy move) and deleted the dead `align()`
method. **No other math changed** — the replica is already fully origin-referenced (gravity-torque about origin
`updateVel`=`ZPP_Space.as:1344`; contact arms `c.px−b.posx`; inertia about origin), that offset path was just
dormant (`align()` zeroed `localCOM`). Verified BIT-EXACT vs the shipped SWF (`p0om`: feet-origin bar at y=416
reports 416.2778 at step 1, settles 480.06 — never the COM). Centered shapes unaffected (`localCOM==0` ⇒ no-op),
all prior goldens + the 36-level sim + gold-route tests still green.

### ONGOING contact/sensor events (added 2026-06-19)
The engine emitted BEGIN-only (`takeContacts`), so the game's `onHitPersistFunction` never fired →
level-8 `switch_weight` flashed green-then-red (the persist handler resets its timer each step; without
ONGOING the timer expired in 4 frames) and wind (`OnHit_Wind`) was dead. Added `takeOngoing(): number[]`
(`[hA,hB,sensorFlag,…]`, same shape as `takeContacts`; flag 0 solid / 1 sensor) — emits EVERY pair
persisting this step **while awake** (begin step included), gated by "not both bodies asleep" (static =
permanently asleep ⇒ a dynamic-vs-static pair is gated by the dynamic body). Faithful to Nape's dispatch
(`ZPP_Space.as:1903-1919`: ONGOING skipped once all of an interaction's arbiters sleep — which is why the
game's `velocity.y -= 1e-8` nudge keeps a resting block awake so ONGOING keeps firing). Verified vs the
SHIPPED SWF with a real BEGIN+ONGOING `InteractionListener` harness (`p0og`): BEGIN@15, ONGOING 15..76
contiguous, body sleeps @77 → ONGOING stops exactly at 77; replica reproduces it step-for-step
(`p0og.test.ts`). **Restitution heads-up from haxe-port (ball-vs-moving-kinematic) = NOT a bug** — their
repro confirms combine 0.6 rebound + escape; the level-7 "stick" is pinned-contact geometry, not the engine.

### Kinematic-vs-resting-dynamic restitution / CCD dynamicSweep (2026-06-19)
The "ball sticks to the level-7 opponent" bug. A moving KINEMATIC body (e.g. the patrol character, +120)
striking a slow/resting DYNAMIC ball (e=1) → the ball locked to the kinematic's velocity (+120) and was
carried, never bouncing. Shipped Nape bounces it to **+192** (combine 0.6) and it pulls ahead (`p0kr`).
**Root cause was NOT the discrete bounce** (instrumented: the first prestep correctly gives bounce −72 and
the ball reaches 192). It was the **CCD re-solve**: the replica always used `staticSweep`, but Nape routes
**kinematic-involved** sweeps through **`dynamicSweep`** (`continuousEvent`, `ZPP_Space.as:10593-10614`).
With `staticSweep` the obstacle is treated as fixed, so after `updatePos` advanced the wall into the ball's
old cell the bounced ball looked like it was penetrating a static wall (`toi=0`) → re-solve → the 2nd
prestep recomputes the bounce off already-separated velocities (`w=+72→clamped 0`) → bounce clawed back,
ball stuck at +120. Fix: added `dynamicSweep` (rewinds BOTH bodies, approach = relative velocity) and route
kinematic obstacles to it; a separating pair yields `toi<0` and is left alone. Finish loop also restores a
rewound kinematic obstacle to dt. Static CCD (p0ms/p0ppr/p0cc) byte-unchanged. **NB `kinvel` was a red
herring** — a kinematic body's translation is in `velocity` (velx), already in the contact relative
velocity; Nape's separate `kinvel` is a surface/conveyor velocity the game never uses. Bit-exact `p0kr` (90
steps vs SHIPPED SWF).

### CCD restitution / lost-bounce fix (2026-06-19)
A bouncy ball landing on a terrain SEAM (shared vertex of two triangles) lost its bounce. The contact
forms via the CCD/sweep path (ball still a few px above the apex at the contact step). Bug: the CCD
re-solve ran a **global** `prestep`/`iterateVel` per TOI event — the 2nd event (tri2) re-solved the
already-bounced tri1 arbiter whose warm-started impulse got clawed back → vy≈0. Fix: re-solve **only
the swept arbiter** via an `only?` arg on `prestep`/`iterateVel` (Nape inline-solves the single pair,
`ZPP_Space.as:10912`); + don't advance an already-frozen body (`:10748`). Bit-exact `p0bn` (rebound
−207 matches 2012 Nape); M4-CCD/p0ppr/p0ms unregressed. The block solver (`3166-3167`) was never the
problem — a circle on a seam is **two 1-contact arbiters**, not one 2-contact block.

### Runtime filter setters (added 2026-06-19)
Shim hooks "filter field changed → engine setter": `setBodyCollisionMask` (used: level-19 switches),
`setBodyCollisionGroup` (speculative — game only reads group), `setBodySensorMask` (used: flying bird
0↔8), `setBodySensorGroup`, `setBodySensorEnabled`. Collision-filter changes drop now-non-colliding
arbiters + wake the resting body (`dropStaleArbiters`); sensor-filter changes only gate `collectEvents`
overlaps. **KNOWN GAP (flagged):** the facade carries ONE category per shape (collider XOR sensor), so
a solid ball has `senGroup=0` and no sensor can detect it → the **flying-bird** "sensor detects solid"
mechanic needs `addCircle/addPolygon` extended to independent sensor cat/mask. Do it only if a bird
level enters the gate set.

### NOT full bit-exact — and exactly why (both = the trig ceiling, by design)
- **`m5-pivot`** (pendulum) — bit-exact *prefix*, then `<1e-9` relative tolerance.
  Rotates continuously → sin/cos diverge ~step 32.
- **`p0ppr`** (tumbling crate, poly-CCD) — bit-exact **10 steps** with the sweep
  (rewind-to-TOI + freeze) fully engaged, then a settle-sanity bound. A box tipping on its
  corner-tip is a sensitive motion that amplifies the 1-ULP sin/cos diff into a small
  settled-pose offset.

### Kinematic bodies (added 2026-06-19)
`TYPE_KINEMATIC` via `setBodyType(h,2)` — no align (keeps registration origin), no gravity,
infinite mass, integrates position from set velocity, carries riders. Engine was already
kinematic-ready; only `setBodyType` needed wiring. Bit-exact motion/origin (`p0kn`), behavioural
carry (`p0kn-kinematic`). **Known gap:** rider-carry contact-onset timing follows Nape's
component sleep/wake lifecycle (separate `kinematics` list + `component.sleeping`/`waket=stamp+1`
in `ZPP_Space`); replica uses a simpler island model → carry is behavioural not bit-exact (a
freshly-dropped rider's first ~2 frames + carry-onset differ sub-px/a few frames, then converge).
Porting Nape's exact component lifecycle would be its own milestone — only if a level needs
frame-exact platform-rider behaviour.

### Behavioural-by-design (not goldens)
- **`p0fac-facade`** / **`p0fac-e2e`** — facade tests asserting *correctness*
  (one BEGIN event, raycast NaN off-geometry, sensor fires e2e), not bit values.
- **`raycastDown`** and **sensor-overlap begin-detection** are geometry-faithful
  (custom ray / `distanceQuery`), not bit-exact to Nape's own rayCast/listener — they're
  gameplay positioning/trigger queries where exact bits don't matter.
- **Sleeping AABB extent** uses `2·sweepRadius` (exact wherever tested: angular thresholds
  vanish for non-rotating bodies; could differ only for a body rotating *right at* the
  60-stamp sleep gate — already trig territory).

---

## Open items I've flagged to the user (game-side — I do NOT edit these)

1. **`jointRev` `maxTorque` → `maxForce`** — replica's `addMotorJoint` exposes it; the shim
   adapter must pass it through. Only matters if a level uses a finite motor torque.
2. **CCD `bullet` flag** — facade accepts it but the replica auto-sweeps fast bodies
   regardless. If the game relies on `bullet` to *selectively disable* sweeping, that's a
   facade/shim decision.

---

## How I work

- Default to **bit-exact** with a captured golden for any new physics. If a scenario is
  trig-limited, gate it as **exact-prefix + bounded tolerance** and say so explicitly in the
  test header — never pretend a tolerance gate is exact.
- The engine is the fixed point — I never bend `nape-core.ts` to suit the game. Game adapts.
- Keep `INTERFACE-COMPAT.md` (API-surface status) and `FACADE-SPEC.md` (the contract) current
  as the engine grows; they are how the other session knows what the shim can rely on.
- When I spot a needed change in `haxe-port/` (game or shim), I **flag it to the user**
  with the specific file/line — I don't edit across the boundary.
- **Cross-session coordination → `sb2_developer_messages.md`** (repo root). I talk to the
  haxe-port session there: newest message on top, each carries a `⬜ UNREAD` indicator the
  recipient flips to `✅ READ`. I check it at session start and after work that affects the
  shim/game contract, and post findings/diagnostic requests rather than editing across the line.
