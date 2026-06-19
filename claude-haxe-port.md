# claude-haxe-port.md — context for the Haxe game + shim-glue session

> One of three context files (load `claude.md` for shared context first):
> - `claude.md` — shared context (both sessions)
> - `claude-nape-replica.md` — the other session: owns/tests the bit-exact replica engine
> - **`claude-haxe-port.md`** — *this* session: the live Haxe game + the nape shim "glue" + testing

*(Note: the user asked for `claude-hexe-port.md`; named `claude-haxe-port.md` to match the
replica session's existing cross-reference. Same intent.)*

---

## My role (remit)

I **manage and test the live Haxe game and the "glue"** — game code + the nape-API shim + the
test harness. I keep the integration working and verify gameplay/feel.

**I own (edit freely):**
- `haxe-port/src/**` — the Haxe/OpenFL game (converted from the 2012 AS3). Served on
  **localhost:8753** (`bin/html5/bin/`). Constraint: the game ships ~**unchanged** vs the
  nape-haxe4 build — I don't rewrite gameplay; the swap must be transparent to game code.
- `haxe-port/nape-shim/**` — **the glue**: `nape/**` (Haxe re-presentation of the nape-haxe4
  API the game calls) + `rnape/NapeReplicaJS.hx` (extern to the replica's handle API). This is
  the layer I build and debug.
- `haxe-port/project.xml`, lime templates, and the debug/test harness (`@:expose sb2*` globals,
  the headless-CDP probe scripts).

**Read-only / flag-only (the replica session's remit):**
- `src/physics/replica/**` — the bit-exact engine. I may **read** it to understand the contract,
  but I do **not** edit it. If a fix belongs there, I **flag it to the user** (see [[session-remit-glue-only]]).
- `src/physics/nape-world.ts` — the old TS→replica bridge. **Reference only** (it's the proven-
  correct filter/shape mapping I mirror in the shim). The rest of `src/**` (TS game) is DEFUNCT.

**Reference (read-only):** `~/Projects/SoccerBalls2/` — original 2012 AS3 source (behaviour truth).

---

## Build & swap

**Use the npm scripts (repo root) — do NOT re-derive the esbuild/lime commands by hand:**
- `npm run replica:bundle` — re-bundle `nape-replica.js` from `src/physics/replica/` (esbuild → template) **and copy it into `bin/html5/bin/`**. Run this after the **engine session** changes the replica; the game/shim don't need rebuilding for an engine-only change.
- `npm run replica:build` — `replica:bundle` + full `lime build html5 -Dreplica` (when the game/shim changed too).
- `npm run replica:serve` — no-cache static server on `:8753` (`scripts/serve-replica.cjs`) serving `bin/html5/bin/`.

Underlying (for reference only):
- **Replica build:** `cd haxe-port && haxelib run lime build html5 -Dreplica` → uses `nape-shim/**` + loads `nape-replica.js`. (`zpp_nape` absent from output JS; `new NapeReplica(` present.)
- **Default build (A/B baseline):** `haxelib run lime build html5` → uses `nape-haxe4 2.0.22`.
- **Bundle staleness gotcha:** the bundle lives in the template *and* `bin/`. The engine session editing `nape-core.ts` does NOT update either — you must `npm run replica:bundle`. (This bit twice before the script existed.)
- Swap is in `project.xml`: `<haxelib name="nape-haxe4" unless="replica"/>` + `<source path="nape-shim" if="replica"/>`.
- **Template gotcha:** `-Dreplica` reaches lime templates as **`SET_REPLICA`** (uppercase, `SET_`
  prefix), NOT `replica`. `index.html` uses `::if (SET_REPLICA):: … nape-replica.js ::end::`.
- Fast typecheck loop: `haxe /tmp/build-replica.hxml` (debug.hxml variant with `-cp nape-shim -D replica --no-output`).
- The `:8753` server serves `bin/html5/bin/`. After building, that dir holds whichever build I last ran — keep it on the **replica** build for the user to feel-test (hard-reload Cmd+Shift+R to clear cached JS).

## Test harness (how I verify headless)

- **Gotcha:** Claude-in-Chrome is network-isolated from host `localhost` (ERR_CONNECTION_REFUSED on
  localhost *and* 127.0.0.1, while `curl` gets 200). **Workaround:** drive the cached
  Chrome-for-Testing binary via CDP using the `ws` npm package:
  - `CHROME="$HOME/Library/Caches/ms-playwright/chromium-1208/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"`
  - `NODE_PATH="/Users/jonscott/Projects/soccerballs2-web/node_modules"`
  - probe scripts: `/tmp/sb2-ab.cjs`, `/tmp/sb2-probe.cjs` (spawn headless Chrome, `--remote-debugging-port`, `Runtime.evaluate` the `sb2*` globals).
- **`@:expose` debug globals** (in `haxe-port/src/Main.hx` unless noted):
  `sb2LoadLevel(i)` (**0-based**: level 9 = idx 8, level 19 = idx 18) · `sb2BallInfo()` · `sb2BallY()` ·
  `sb2GroundInfo()` · `sb2GroundShape()` (first static body's first shape) · `sb2DynShapes()` ·
  `sb2RealKick(mouseX,mouseY)` · `sb2TestKick(speed,angleDeg)` · `sb2LoopCount()` · `sb2BBox()` ·
  `sb2MakeBallSolid()` · `sb2ForceFail()` · `sb2DumpHud()` (HudController).

## Verification gates
Level **9** (wall bank shot) and level **19** (rev joints) — feel-tested by the user on `:8753`.

---

## ✅ RESOLVED BUG — ball passed through all terrain under `-Dreplica` (fixed 2026-06-19)

**Root cause (shim glue):** `nape-shim/nape/geom/GeomPoly.hx` and `nape/shape/Polygon.hx` ingested
verts from an `Array<Dynamic>` and read `p.x`/`p.y` off the **Dynamic** element. The shim `Vec2`
stores coords in `_vx`/`_vy` behind a property getter, so a raw Dynamic `p.x` read hits a
non-existent JS field → `undefined` → Haxe's `== null` default → **0**. Every vertex collapsed to
(0,0): line terrain triangulated to **0** triangles (degenerate point), object polys got zero-area
verts. The replica's narrowphase was always correct — nothing real to collide with.

**Fix:** both sites now route `Vec2` elements through the getter (`Std.isOfType(p,Vec2)` → typed
`cast`), keeping the direct field read for plain `{x,y}`. **Verified** under `-Dreplica` level 9:
static terrain shapes 41→158, isolation test `tris=2` with real verts, kicked ball rolls on terrain
and settles (matches nape-haxe4). Diagnostics left in place: `sb2TerrainDump()`, `sb2GeomPolyTest()`.

**Lesson (watch for recurrence):** anywhere the shim reads `.x/.y` (or any property) off a
`Dynamic`-typed shim object, it silently bypasses the getter. The shim `Vec2` is the main offender.

---

## Earlier symptom log (kept for reference)

**Symptom (user-reported):** "the balls have no collision with walls or floors they just go straight through." Gravity works (ball falls), but no collision with any terrain.

**Established:**
- ✅ Default (nape-haxe4) build collides fine: ball rests/rolls on terrain (y≈446, state 1→2→2→1).
- ❌ **Filters RULED OUT.** Collidable terrain polymats (`poly_collide_grass/mud`, `poly_death`)
  are `col="1,15"` (cat 1, mask 15). The ball (`football`) is `col="8,15"`. nape's rule
  `shouldCollide = (8&15)&&(1&15) = true` → they DO collide. The shim maps filters identically to
  the proven `nape-world.ts` (same split `cat!=0 && mask!=0`, same `addPolygon(...,cat,mask,sensor)` order).
  My earlier "ground cG=2 cM=11" reading was a *different* static body (`sb2GroundShape` returns
  whichever static body is first; ordering differs between builds) — a red herring.
- ✅ **Winding RULED OUT.** Shim `GeomPoly` forces positive signed area, matching the replica's
  working unit-test floor.

**Leading hypothesis (MY remit — shim glue):** the shim's `nape/geom/GeomPoly.triangularDecomposition()`
ear-clipper **degenerates on real concave Catmull-Rom terrain**. Terrain build (game code,
`PhysicsBase.hx:266-280`) does `new GeomPoly(points).triangularDecomposition()` then adds each
triangle as a `Polygon` to one static `Body`. The replica's working test floor is a trivial 4-vert
rectangle; real terrain is a many-vert concave loop. If the ear-clipper returns 0 / degenerate
triangles, the static body has no usable shapes → ball falls through.

**Next step:** instrument the level-9 terrain build (`sb2TerrainDump()` @:expose — per static body:
polyShape count + first triangles' local verts + signed area) — if empty/degenerate/inverted, fix `GeomPoly.hx`.

**⚠️ CONTRACT CORRECTION (from nape-replica session, 2026-06-19):** the replica's `addPolygon` does
**NOT** convex-decompose internally — `nape-core.ts:581` stores verts as-is ("feed already-convex
pieces"). My earlier note (from nape-world.ts) was WRONG. So the shim's `GeomPoly` ear-clipper **must**
emit valid **convex** triangles with **positive shoelace** winding; the replica won't rescue a
concave/degenerate/zero-triangle/inverted result — it silently misses contacts → the fall-through.
The replica session proved many-triangle static terrain collides correctly (`p0tr-terrain.test.ts`),
so the replica is exonerated; the bug is in what the shim feeds it: (a) 0/degenerate tris, (b) body
not static+finalized+live, or (c) inverted winding.

---

## ✅ RESOLVED with the replica session (both verify gates pass)
- **Level 9 referee floating** — engine added real `TYPE_KINEMATIC` (no align/gravity, velocity-
  driven, carries riders). Verified `sb2RefInfo` → `pos=(388,128)`.
- **Level 19 switchable blocks** — runtime collision-filter change wasn't propagated.
  `UpdateSwitchable_Disappear` → `SetBodyCollisionMask(0,0)` sets `shape.filter.collisionMask=0`.
  Shim fix: `InteractionFilter.collisionMask` is a live property → `Body.runtimeSetCollisionMask` →
  `engine.setBodyCollisionMask(handle, mask)` (guarded). Engine added `setBodyCollisionMask(h,mask)`
  (drops already-touching pairs + wakes the resting ball). Verified via `sb2Switch19Dump` +
  `sb2FireAllSwitches`: blocks colMask→0 and the 3 resting balls fall. **Watch for other runtime
  filter mutators** beyond `collisionMask` (e.g. `sensorEnabled` toggles, `collisionGroup` changes) —
  only `collisionMask` is wired so far.
- **KINEMATIC bodies treated as DYNAMIC + auto-aligned → referee floats ~40px (level 9).** The game
  uses kinematic via `SetBodyXForm`/`SetBodyXForm_Immediate` (`GameObjBase.hx:1780/1772`) for refs +
  moving platforms (velocity-driven, not teleport). Replica `setBodyType` (`nape-core.ts:1397`) maps
  kinematic(2)→DYNAMIC and runs `align()` (recenter origin→COM), shifting the ref's offset box up by
  its COM offset; `body.position` (the render pos) becomes the COM, not the feet. Needs real
  TYPE_KINEMATIC: no align, no gravity, position from velocity, carries riders. Verify with
  `sb2RefInfo()` — expected after fix `static=false dyn=false pos=(388,128)`. (Flagged in
  `sb2_developer_messages.md` 2026-06-19. Collision/terrain itself is fine.)

## Items the replica session flagged to me (shim-side TODOs)
1. **`jointRev` motor `maxTorque` → `maxForce`** — replica exposes it; the shim must pass it
   through. Only matters if a level uses finite motor torque (current data: all rev motors OFF).
2. **CCD `bullet` flag** — replica auto-sweeps fast bodies; the game never sets `isBullet`, so the
   shim finalizes with `bullet=false`. Watch for level-9 tunnelling.

## Known shim limitations (in `docs/replica-integration-plan.md`)
ONGOING contacts not emitted (BEGIN-only → wind/weight-switch persist fns silent) · joint
collide-ignore not forwarded · rev motor/limit no-ops (dead per data) · conveyor surfaceVel
stored-not-driven · up-ray rayCast→null · rotation round-trips through degrees.
