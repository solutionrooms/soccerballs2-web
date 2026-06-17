# Physics friction divergence — investigation log

**Status:** OPEN root cause. A behavioral fix is deployed (`tools/patch-nape-friction.sh`), but the
true mechanism is **not yet pinned**. This doc captures everything tried, found, and ruled out so we
can resume cold.

Last updated: 2026-06-17.

---

## 1. Symptom

In the original Flash game (2012 Nape SWC, runs in Ruffle / matches the 20k-view YouTube walkthrough),
a fast ball bouncing off a wall **keeps its tangential speed and does not spin** — it climbs to the
receiving player. In our port (Haxe → JS, nape-haxe4 2.0.22) the **same** bounce loses ~half its
tangential speed and gains spin — the ball falls short.

**User is certain (critical constraints — do not re-litigate):**
- It affects **many levels**, not just level 9. It is a **systematic** difference.
- It is **"completely different" old vs new**, prior to the fix.
- The ball **arrives at the wall identically** in both (NOT a trajectory/arrival difference — user 100% sure).
- It is **location-independent** — doesn't matter where on the wall you hit.
- User's working hypothesis was Flash-AVM2-vs-JS **floating point** (now investigated — see §6.2).

## 2. Empirical data (the trajectory A/B)

Frame-stepped logs of the level-9 wall bounce (physics `angularVel`, not render):

| | pre-bounce vel | post-bounce vel | spin | reading |
|---|---|---|---|---|
| **ORIGINAL** (Flash 2012) | (302, −561) | (−151, **−544**) | **0** | y preserved (just gravity), NO friction |
| **PORT** (JS 2.0.22)      | (312, −573) | (−156, **−283**) | **18.08** | y ~halved, friction applied |

Restitution (x-reversal ≈ −0.5) is **identical**; only the tangential (y) + spin differ → it is purely
a **friction** difference. Same material μ in both (probe shows combined friction 3.16 = √(0.1·100) for
mud, 0.22 = √(0.1·0.5) for grass — Nape uses geometric-mean friction combine).

Measurement method: FFDec-patched the original SWF to `trace("[ORIG] vel/spin/pos")` per frame in
`Game.UpdateGameplay` (run in Ruffle, `tools/swf-patched/` + `serve-ruffle.py` :8754); matching
`[PORT]` log in `Main.hx` gated on `NapeContacts.probeEnabled`.

## 3. Current fix (deployed, behavioral — NOT the root cause)

`tools/patch-nape-friction.sh` — idempotent in-place patch of the installed nape-haxe4
`zpp_nape/dynamics/Arbiter.hx`, appends to the friction solver (lines ~2207 & ~2225):
```
jMax = c1.friction * c1.jnAcc;  if(c1.bounce != 0) jMax = 0;   // (+ c2 equivalent)
```
→ gates friction OFF on any contact carrying a restitution bounce (fast impacts), KEEPS it on
resting/rolling contacts (`bounce == 0`). Reproduces the original feel; validated headless in
`tools/nape-ab/Test2.hx`. Wired into `haxe-port/README.md` build steps. **This is a compensating
patch — the 2012 solver has no such gate, so it is not the real mechanism.**

---

## 4. PROVEN IDENTICAL (engine parity, 2012 SWC decompile ↔ nape-haxe4 2.0.22)

Decompiled `release_nape.swc` (Oct 2012) with FFDec → `tools/nape-ref/as3/scripts/`. Diffed against
the installed `~/haxelib/nape-haxe4/2,0,22/`.

- **Velocity solver loop (`iterateVel`)** — byte-identical structure:
  - 2012: `ZPP_Space.as:8248–8525`  ·  2.0.22: `Space.hx:5688–5744` + `Arbiter.hx:2197–2338`
  - Same outer loop (`times` iters), same pass order (fluid-drag → constraints → collisions
    `c_arbiters_false` then `c_arbiters_true`), same per-arbiter order (**tangent friction → rolling
    friction → normal solve**).
  - Friction clamp reads **live** `c1.jnAcc` in both (2012 `:8368` ≡ 2.0.22 `:2207`).
- **Prestep** (`Arbiter.hx:1955–1981`): bounce setup `vdot*elasticity`, zeroed if `> -elasticThreshold(20)`
  (`:1969–1973`); static/dynamic friction select `vdot² > staticFrictionThreshold²(=4)` (`:1974–1981`);
  `tMass`/`nMass`. Identical.
- **Friction combine** = `√(f1·f2)` geometric mean (`Arbiter.hx:1663–1669`). Identical.
- **Config thresholds**: `staticFrictionThreshold=2`, `elasticThreshold=20`, drag `0.015`. Identical.
- **Iteration counts + timestep**: both `step(1/60, 10, 10)` — port `PhysicsBase.hx:139` ≡ original
  decompile `PhysicsBase.as:134`. `nape_timeStep=1/60`, `nape_Gravity=300` default + `SetGravity`
  from VarsData, identical (`PhysicsBase.hx:48,52` ≡ `PhysicsBase.as:54,62`).
- **Game Nape listeners**: identical set — BEGIN/ONGOING × COLLISION/SENSOR, **no PreListener**
  (port `PhysicsBase.hx:120–131` ≡ original `PhysicsBase.as:121–128`). `NapeContacts.BeginPre` is a
  `Utils.print("HERE")` no-op in both and is never registered.
- **warmStart**: standard cached jnAcc/jtAcc application, =0 for fresh contacts (2012 `ZPP_Space.as:279`,
  2.0.22 `Arbiter.hx:2127`). Looks identical (not exhaustively line-diffed — see §7).
- **Ball is not a bullet** (`GameObj_Base.as:567 colFlag_isBullet=false`) → discrete path, not CCD.

## 5. Headless reconstruction (`tools/nape-ab/Test3.hx`)

Built the **real** level-9 colliders (the actual XML polylines) via `GeomPoly.triangularDecomposition`
exactly like `PhysicsBase.InitLines` (`PhysicsBase.hx:179–315`), fired the football.

- Level-9 wall = **two separate filled static bodies**: `poly_collide_grass` → `poly_average`
  (friction 0.5) and `poly_collide_mud` → `poly_mud` (friction 100). Grass terrain **encloses** the mud
  hill; grass vertical face ≈ x214, mud face ≈ x229 (behind). Geometry: `SoccerBalls2_Levels_Data.xml:1169–1195`;
  materials: `SoccerBalls2_Objects_Data.xml:913–914`.
- **A ball approaching from outside ALWAYS hits grass first** (combF 0.22); mud (combF 3.16, normal
  (−1,0)) only engages if the ball is already INSIDE the grass/mud interface (~x220–229). Even a
  tunneling-fast ball hits grass and bounces.
- **Unpatched** nape-haxe4 hitting **grass** still spins the ball (~12) and cuts y — i.e. it applies
  bounce friction the ORIGINAL doesn't (original spin 0). So the divergence is **NOT grass-vs-mud**;
  it happens on plain grass too.
- ⇒ The reconstruction (real geometry + real engine) **reproduces the PORT** (friction on bounce),
  not the original.

Run: `haxe -cp tools/nape-ab -lib nape-haxe4 -main Test3 -neko /tmp/t3.n && neko /tmp/t3.n`

---

## 6. RULED OUT

### 6.1 Solve-order / iteration structure — RULED OUT
Both `iterateVel` loops read end-to-end and are byte-identical (§4). The thing the patch "hacks
around" is not a solve-order difference.

### 6.2 Floating point (Flash-AVM2 vs JS) — RULED OUT (tested empirically)
The **only** AVM2-vs-JS *arithmetic* difference in all of nape is the friction-combine / normalization
`sqrt`:
- `zpp_nape/util/Math.hx:178–208`: `#if flash10` uses the **Quake `0x5f3759df` fast inverse sqrt**
  (float32 seed via `flash.Memory`, 1 Newton iter); `#else` (JS/neko) uses exact `Math.sqrt`.
- 2012 inlined the same Quake frsqrt (`ZPP_Space.as:4160–4176`).
- **Experiment:** forced the portable Quake frsqrt (`haxe.io.FPHelper.floatToI32` bit-hack) into the
  JS/neko `#else` path, rebuilt `Test3` → **bit-identical bounce** (A: spin 11.9, B: spin 12.14,
  unchanged). The ~0.17% μ error is inert because friction at a hard bounce is **not clamp-limited**
  (μ·jnAcc ≫ needed), so μ's exact value doesn't change the applied friction.
- All **other** `#if flash10` blocks are `flash.Vector`-vs-`Array` allocation only (Const, FastHash,
  MatMN, GeomPoly, Array2) — same sizes/values, no math impact. Debug files (ShapeDebug/BitmapDebug)
  are rendering-only.
- IEEE-754 `+ − × ÷` and `sqrt` are correctly-rounded and identical on AVM2 and JS (both 64-bit).
- ⇒ **FP does not explain the divergence.**

### 6.3 Grass-vs-mud overlapping-collider order — RULED OUT
§5: friction divergence happens even on a pure-grass bounce. Mud is enclosed by grass and only engages
from inside the interface.

### 6.4 Game-level friction manipulation (PreListener / arbiter edits) — RULED OUT
Identical listener registration, no PreListener, `BeginPre` is a no-op in both (§4).

### 6.5 Timestep / gravity / iteration counts — RULED OUT
Identical (§4).

### 6.6 Ball trajectory / arrival — RULED OUT by user
User is 100% sure the ball arrives identically; divergence is location-independent.

### 6.7 CCD / bullet — RULED OUT
Ball is not a bullet; `Test2`/`Test3` `isBullet=true` changes nothing.

---

## 7. THE PARADOX (unresolved) + what's NOT yet checked

**Paradox:** identical solver + identical prestep + identical config + FP ruled out + (per user)
identical arrival — yet PORT applies bounce friction (spin) and ORIGINAL applies none (spin 0). With
identical code and identical inputs the outputs should match. They don't. Something is still different.

The friction mechanism worth understanding: friction is solved **friction-first** each velocity
iteration using the **previous** iteration's `jnAcc`. On a fresh contact, iter 1 sees `jnAcc=0`
(no friction); iters 2–10 use the built-up `jnAcc` (friction applied). For the original to apply
**zero** friction, the contact would have to be solved with `jnAcc≈0` throughout (effectively ~1
iteration). That points at the **contact lifecycle**, not the per-iteration math.

**NOT yet diffed / open threads (resume here):**
1. **Narrowphase** `contactCollide` (`zpp_nape/geom/Collide.hx:356`) — large; generates the contact
   (normal, contact point, **persistence/feature IDs**, penetration). A 2012-vs-2.0.22 difference here
   would change the contact that feeds friction without touching the solver. **Highest-priority unchecked.**
2. **Contact persistence / `acting()` gate** — `if(arb.acting())` is checked each velocity iteration.
   Does the original's bouncing contact stop "acting" after ~1 iteration (→ friction never builds)?
   Check `acting()` + the `fresh`/`posOnly`/`first` flags and contact-matching across both versions.
3. **`warmStart`** fine line-diff (started; looks standard).
4. **Definitive empirical 2012 oracle** — the real arbiter. See §9.

---

## 8. Tools & artifacts (how to resume)

- **Decompiled 2012 Nape**: `tools/nape-ref/as3/scripts/` (gitignored — regenerate with FFDec
  `tools/vendor/ffdec.jar` on `~/Projects/SoccerBalls2/Nape/release_nape.swc`). Key file
  `zpp_nape/space/ZPP_Space.as` (inlined solver).
- **Decompiled game SWF**: `tools/swf-decomp/scripts/` (gitignored). `PhysicsBase.as`, `NapeContacts.as`,
  `GameObj_Base.as`.
- **Headless harnesses** (`tools/nape-ab/`, committed): `Test2.hx` (wall bounce + slow roll, validates
  the patch), `Test3.hx` (real level-9 geometry reconstruction + contact probe).
  Run: `haxe -cp tools/nape-ab -lib nape-haxe4 -main Test3 -neko /tmp/t3.n && neko /tmp/t3.n`
- **The patch**: `tools/patch-nape-friction.sh` (idempotent; backup at `Arbiter.hx.bak`).
- **Original SWF instrumented** (`tools/swf-patched/`, gitignored): unlock-all + `[ORIG]` trajectory +
  `[ORIG-PROBE]` contact logs. Served by `tools/serve-ruffle.py` :8754.
- **Port probe**: `NapeContacts.hx` `probeEnabled` (currently FALSE for deploy) + `[PORT]` log in `Main.hx`.
- **FP experiment** (to repeat): patch `~/haxelib/nape-haxe4/2,0,22/zpp_nape/util/Math.hx` `#else`
  paths of `sqrt`/`invsqrt` to the FPHelper Quake frsqrt (see §6.2). Restore from backup after.
- nape-haxe4 install: `~/haxelib/nape-haxe4/2,0,22/`. nape 2.0.20 will NOT compile on Haxe 4.

## 9. Next steps (prioritized)

1. **Diff the narrowphase** `contactCollide` (Collide.hx:356) 2012 ↔ 2.0.22 — contact normal, contact
   point, and especially **contact persistence / feature-ID matching** (warm-start eligibility).
2. **Build the 2012 oracle** (task #45) — the definitive arbiter. Options:
   - Install **Ruffle desktop** (Rust binary, traces to stdout) + compile a scenario SWF. Need an AS3
     compiler (Flex SDK `mxmlc`/`asc`) to build from `tools/nape-ref/as3`, OR compile `Test3` via
     Haxe's **flash target** (`-swf`) using nape-haxe4's flash10 path (tests Flash-runtime-vs-JS on the
     SAME codebase — but note §6.2 predicts this matches JS, which would implicate the 2012-SWC code,
     i.e. the narrowphase, not the runtime).
   - OR instrument the original SWF's contact path via FFDec to log per-contact friction (hard: solver
     is inlined in ZPP_Space).
   No headless SWF/AS3 runner is currently installed (`ruffle`, `redtamarin`, `asc`, `mxmlc`, `adl` all absent).
3. **Get in-game ground truth**: re-enable the port probe (`NapeContacts.probeEnabled=true`) enhanced to
   log, at the bounce frame, ALL ball contacts (surface, normal, contact point, penetration) + ball
   pos — one Ruffle (original) + one port run, compare. Confirms whether the contact GEOMETRY (normal/
   point/persistence) differs, which is the leading remaining hypothesis.

## 10. Related memory notes
`nape-engine-faithful-verified`, `ball-friction-divergence-fix`, `converted-source-is-real-game`,
`soccerballs2-nape-engine`.
