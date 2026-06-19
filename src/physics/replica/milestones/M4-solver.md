# M4 — Contact solver ✅ (discrete) · ✅ (CCD) — COMPLETE

**This is the load-bearing 80% — where "feel" lives.** Both the discrete contact
solver AND the continuous-collision (TOI) pass are implemented and gated
**bit-for-bit** against the real original Nape AS3. The full 180-step drop
(free-fall → fast impact arrest → settle) matches every field, every step.

## What's done — the discrete solver ✅

`nape-core.ts` now runs the full `Space.step` pipeline (ZPP_Space.as:1579):

```
validateWorldCOM → narrowphase → prestep → updateVel → warmStart
                 → iterateVel → updatePos → iteratePos
```

Implemented faithfully (operation order preserved), wired for circle-vs-static-
polygon face contact (the ball-on-floor case):

- **persistent arbiters** keyed by body pair, so a contact's `jnAcc`/`jtAcc`
  warm-start across steps;
- **narrowphase → arbiter** with the verified INTERNAL order **b1 = circle,
  b2 = polygon** (the only order under which `iteratePos` reduces to the observed
  resting separation; the public `Arbiter.body1/2` is id-sorted and reversed):
  `ptype = 1`, `rev = true`, `nx,ny = −gnorm`, contact point
  `worldCOM − gnorm·(radius + sep·0.5)`, local arm `lr1 = circle.localCOM`;
- **prestep** (ZPP_Space.as:4157): material combine (restitution = clamped mean;
  friction/rolling = geometric mean via `1/fastInvSqrt(a·b)`), warm-scale
  `dt/pre_dt`, per-contact arms `r1/r2`, effective masses `nMass/tMass`,
  restitution `bounce`, friction selection, `biasCoef = 0.6`;
- **warmStart** (ZPP_Space.as:313);
- **iterateVel** (ZPP_Space.as:8222): tangent friction → rolling friction →
  non-penetration normal impulse, accumulated + clamped, `velIters` sweeps;
- **iteratePos** (ZPP_Space.as:8501): split-impulse position correction,
  reconstructing world normal + contact point from the bodies' *current*
  transforms each of `posIters` sweeps, pushing apart by `biasCoef·sep` and
  leaving the 0.2 resting slop.

### Gate — `m4d-discrete.test.ts` ✅

Golden `original-goldens/m4d-discrete.json` (harness-m4d.as): a circle placed
already penetrating a static floor by 2 px, at rest, settling under gravity. Its
per-step velocity-driven motion stays below Nape's continuous-collision
threshold, so this **isolates the discrete pipeline from CCD**.

```
✓ M4 — DISCRETE contact solver (penetrating rest) vs ORIGINAL Nape AS3
    ball state matches the original bit-for-bit at every one of 60 steps
```

All six fields (x, y, rot, vx, vy, angvel), every step, bit-identical — including
the fast-inverse-sqrt friction combine and the position-correction transient that
settles to `y = 268.2` (`4070c333_33333334`).

The large-drop golden (`m4-solver.json`, harness-m4.as) additionally confirms the
free-fall segment (steps 1–34) and the settled rest (steps 39–180) bit-for-bit
(`m4-solver.test.ts`).

## What's left — M4-CCD ⏳ (continuous collision / TOI)

The large-drop golden reaches ~580 px/s before impact; the original arrests the
ball at the **moment of contact** via `ZPP_Space.continuousCollisions` →
`ZPP_SweepDistance.staticSweep` (conservative advancement using a GJK `distance`
query) — a separate ~1200-line subsystem. Without it the replica penetrates
~6.5 px at impact (step 35: replica 274.5 vs original 268.2) then converges to the
**identical** resting fixed point one step later. So CCD changes only the impact
transient (steps 35–38), not the equilibrium.

This is its own milestone because the sweep can't be verified against a single
impact step — it needs sub-goldens. Broken into three:

- **M4-CCD-a — closest-distance query ✅ DONE (bit-exact).** `ZPP_SweepDistance.distance`
  is NOT general GJK — it's specialized: circle-circle (direct, fast-inv-sqrt) and
  circle-polygon (closest-feature, like M3b but returning *signed distance* +
  witness points). Ported as `distanceQuery` / `distanceBetween` in nape-core.ts;
  gated by `m4cd-distance.test.ts` (face/vertex/penetrating/circle-circle, distance
  + all witness points + normal, bit-for-bit). Poly-poly distance deferred (crates
  aren't bullets). Harness calls the public internal `ZPP_SweepDistance.distance`
  directly.
- **M4-CCD-b — staticSweep (TOI) ✅.** Conservative advancement (ZPP_SweepDistance.as:789),
  `staticSweep` in nape-core.ts. Reuses M4-CCD-a's `distanceQuery` (the inlined
  circle-poly distance is byte-identical to `distance()` — the `Math.sqrt` axis is
  only in the poly-poly branch). For the ball (centred circle) `sweepCoef = 0`, so
  the angular term vanishes; the loop rewinds to `pre_pos`, advances to `t·dt`,
  recomputes distance, and steps `t += (d+0.5)/((−approachVel)·dt)` until impact.
  Body fields `sweepRadius`/`sweep_angvel`/`sweepFrozen` set in `updatePos`/`finalizeBody`.
- **M4-CCD-c — continuousCollisions integration ✅.** `continuousCollisions` wired
  into step() between updatePos and iteratePos: build ToiEvents (fast non-frozen
  dynamic circle vs static polygon), advance to the soonest TOI, re-solve
  (narrowphase → prestep → 1 velocity iteration — the existing per-arbiter code),
  freeze the body, then finish the motion of anything still moving.

  **The one subtlety that cost a debug pass:** the re-solve's `presteparb(…, true)`
  does NOT set the arbiter's `continuous` field, so the CCD contact's position
  correction uses **biasCoef 0.6** (non-continuous), not 0.5. With 0.5 the arrest
  settled to penetration 0.20029 vs the golden's 0.20003; with 0.6 it's exact.

**Gate:** `m4-solver.test.ts` — the full 180-step drop, all six fields, every step,
bit-for-bit (free-fall, the CCD impact arrest at step 35, and the settle). No skips.

## Material note

The replica `Shape` carries one `friction` (used for both dynamic & static, which
are equal in the test material) and `rolling`. Distinct static friction is a
later refinement (needed only once an M4c angled-drop/friction golden exercises
the dynamic↔static switch).
