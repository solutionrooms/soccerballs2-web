# M5 — Constraint solver (joints) ✅ ALL FIVE

The game uses Nape joints (PivotJoint/WeldJoint/DistanceJoint/AngleJoint/MotorJoint
appear in `PhysicsBase`/`GameObj` + a level joint editor). M5 ports **all five**
onto the same sequential-impulse framework as the M4 contact solver, each gated
against the real original Nape AS3:

| joint | DOF | solver | gate | bit-exact? |
|-------|-----|--------|------|------------|
| **Pivot** | 2 (point) | 2×2 kMass | `m5b-pivot-notrig` (pivot at COM) | ✅ 90 steps |
| **Weld** | 3 (point+angle) | 3×3 kMass + `jAccz` | `m5w-weld-notrig` (cantilever) | ✅ x/y/vy 90 steps |
| **Distance** | 1 (along rod) | scalar, fast-inv-sqrt dist | `m5d-distance-notrig` (swinging rod) | ✅ 90 dyn steps |
| **Angle** | 1 (relative angle) | scalar, `ratio` | `m5a-angle` (spin into limit) | ✅ 90 dyn steps |
| **Motor** | 1 (angular rate) | scalar, velocity-only | `m5m-motor` (constant-rate spin) | ✅ 90 dyn steps |

Constraints live as a discriminated union (`nape-core.ts`), dispatched at the four
step hooks (preStep in `prestep`; warm-started after contacts; solved before
contacts in each velocity/position sweep). APIs: `addPivotJoint`, `addWeldJoint`,
`addDistanceJoint`, `addAngleJoint`, `addMotorJoint`.

**Key insight for bit-exact gates:** macroscopic *rotation* invokes `sin/cos` and
re-introduces the cross-runtime trig gap. So the gates use scenarios where the
graded quantities never depend on the axis — pivot/weld pinned so the body can't
rotate, and the purely-angular Angle/Motor joints with a *centred* COM (the axis is
computed but inert). That keeps even the spinning Angle/Motor tests fully bit-exact.

## What's done — WeldJoint ✅

A `WeldJoint` is PivotJoint's 2-DOF point constraint **plus** a 1-DOF angular lock
(`b2.rot − b1.rot = phase`) → a 3-DOF constraint with a symmetric **3×3** effective
mass `[a b c; b d e; c e f]`, an extra accumulated angular impulse `jAccz`, and an
angular-error clamp to ±0.25 rad in the position solve (the assignment the
decompiler dropped at ZPP_WeldJoint.as:958-970). Ported verbatim
(`weldPreStep`/`weldApplyImpulseVel`/`weldApplyImpulsePos`); API
`addWeldJoint(hA, hB, a1x, a1y, a2x, a2y, phase=0)`.

### Gate — `m5w-weld-notrig.test.ts`

A box cantilevered off a static anchor by a weld: gravity applies a torque that the
weld's angular DOF (`jAccz`) actively resists, holding the box in place without
rotation (so no `sin/cos`). **x, y, vy are bit-for-bit for all 90 steps** — and
because `jAccz` couples into the linear DOFs through the off-diagonal `kMass` terms,
their bit-exactness proves the whole 3×3 solve. The residual `rot`/`angvel`/`vx` are
numerically zero (≤1e-17/1e-47) — pure FP precision-floor noise of a "held at zero"
quantity, asserted to stay < 1e-14 (a real error would be O(1)) with a ≥40-step
all-fields-exact prefix.

> No bit-exact weld scenario can exhibit *macroscopic* rotation: that requires
> `sin/cos` of a real angle and re-introduces the trig gap. The cantilever is the
> strongest no-trig weld gate — it fully exercises the angular impulse while keeping
> rotation (hence trig) out of the meaningful, bit-exact DOFs.

## What's done — PivotJoint ✅

A `PivotJoint` pins a local anchor on body 1 to a local anchor on body 2 (a 2-DOF
point-to-point constraint). Implemented in `nape-core.ts` exactly as the original
(ZPP_PivotJoint.as), wired into the step pipeline at the constraint hook points:

- **preStep** (ZPP_PivotJoint.as:171): world anchor arms `a1rel/a2rel`, the 2×2
  effective-mass matrix `kMass` (inverted), warm-scale of `jAcc`. `stiff` (default)
  ⇒ no soft bias/gamma; `maxForce = ∞` ⇒ no clamp/break.
- **warmStart** (ZPP_PivotJoint.as:93): re-apply the persisted anchor impulse —
  after contacts, per ZPP_Space.warmStart ordering.
- **applyImpulseVel** (ZPP_PivotJoint.as:637): drive the relative anchor velocity
  to zero through `kMass`; run *before* contacts in each velocity sweep.
- **applyImpulsePos** (ZPP_PivotJoint.as:693): split-impulse position correction
  with the large-error pre-shift and the length clamps (fast-inv-sqrt), *before*
  contacts in each position sweep.

API: `addPivotJoint(hA, hB, a1x, a1y, a2x, a2y)` (mirrors `new PivotJoint`).

### Gates

- **`m5b-pivot-notrig.test.ts` — BIT-EXACT, 90 steps ✅.** Golden harness-m5b.as:
  the pivot anchors at the box's centre of mass, so constraint force and gravity
  both pass through the COM → zero torque → the box never rotates and **no sin/cos
  is ever evaluated**. This grades the constraint solver's full translational path
  bit-for-bit (all 6 fields × 90 steps), with no cross-runtime trig gap. This is
  the authoritative M5 correctness gate.

- **`m5-pivot.test.ts` — rotating pendulum, trig-limited.** Golden harness-m5.as:
  the box is pinned at its left end and swings. The solver is *identical*, but now
  the body rotates. The result is bit-for-bit for the first **31 steps**, after
  which the accumulating ≤1-ULP cross-runtime `sin/cos` difference (the one
  documented unavoidable gap — see the float caveat) first crosses a rounding
  boundary; a pendulum amplifies it to ~116 ULP (~1e-12 relative) by step 90. The
  test asserts (a) a bit-exact prefix ≥ 30 steps, and (b) the full run tracks the
  original to < 1e-9 relative. A real op-order bug would diverge exponentially to
  O(1) and fail (b); the no-trig gate above rules out any solver-math error.

## Why two goldens

The pendulum alone can't distinguish "trig gap" from "solver bug". The no-trig
scenario (pivot at COM) removes rotation entirely and proves the constraint math
is bit-exact; the 31-step exact pendulum prefix additionally exercises the angular
coupling terms (non-zero anchor arm) bit-for-bit. Together they isolate the
residual drift to `Math.sin/cos`, consistent with the M1 SPIN test (180 rotating
steps bit-exact for *its* angle sequence — trig agreement is input-specific).

## Status

All five joint types done and gated bit-for-bit (20 tests green across the replica
suite, 1 documented-skip = M4-CCD). Remaining engine work: M4-CCD (continuous
collision), M6 (raycasts + sleeping), M7 (cutover to replace `nape.js`).
