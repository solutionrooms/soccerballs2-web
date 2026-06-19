# Nape replica — test suite summary

The replica (`nape-core.ts`) is a hand-written, **bit-exact** TypeScript port of the
*original* game's Nape engine. Every test grades the replica against a golden
captured from the **real original Nape AS3** — not a transpile, not `nape.js`.

Run them all:

```bash
npx vitest run src/physics/replica
```

**Current status: 22 tests across 15 files — all green, 0 skips.** `tsc --noEmit` clean.

---

## How the tests work (methodology)

1. **Oracle = the original engine itself.** A small "calling-AS3" harness
   (`tools/nape-oracle/harness-*.as`) drives the genuine Nape bytecode already inside
   the shipped `SoccerBalls2.swf` and `trace()`s each value as **raw IEEE-754 bits**
   (via `ByteArray.writeDouble`), so there is no decimal round-off.
2. **FFDec injects** the harness as the SWF's document class:
   `java -jar tools/vendor/ffdec.jar -replace haxe-port/assets/SoccerBalls2.swf out.swf Preloader harness.as`.
3. **Ruffle runs it headless** under Puppeteer (`tools/nape-oracle/capture-lines.mjs`);
   `trace()` → console → committed golden `original-goldens/*.json`.
4. **vitest gate** reconstructs each double from its bits and asserts the replica
   reproduces it with `===` on the 16-hex representation (`diff.ts`).

**Bit-exactness scope.** `+ − × ÷ √` and the Quake fast-inverse-sqrt are identical
across AVM2 (Flash) and V8, so most results are bit-for-bit. The **one** unavoidable
gap is `Math.sin`/`Math.cos`, which can differ ≤1 ULP between runtimes for some
inputs. Tests are therefore designed so the graded quantities never depend on a
freshly-rotated `sin/cos` (see the "no-trig" scenarios); the lone exception (the
rotating pendulum) is graded with an exact-prefix + tight-tolerance assertion and is
documented as such.

---

## Test inventory

| File | Milestone | Scenario | Asserts | Steps | Result |
|------|-----------|----------|---------|-------|--------|
| `m0-freefall.test.ts` | M0 | single dynamic circle under gravity | circle mass; then x, y, vx, vy, rot, angvel | 600 | bit-exact |
| `m1-rotation.test.ts` | M1 | **SPIN** freely-rotating body | mass, inertia; y, vy, rot, angvel | 180 | bit-exact |
| | M1 | **KICK** central `applyImpulse` | x, y, vx, vy | 60 | bit-exact |
| | M1 | **POLY** box mass + spin | box mass, inertia; y, vy, rot, angvel | 120 | bit-exact |
| `m2-aabb.test.ts` | M2 | circle / box / off-centre triangle | world AABB (broadphase bounds) | — | bit-exact |
| `m3-circle.test.ts` | M3a | two overlapping circles | manifold normal + penetration (incl. fast-inv-sqrt) | — | bit-exact |
| `m3b-circlepoly.test.ts` | M3b | circle on a polygon **edge** | face-contact normal + penetration | — | bit-exact |
| | M3b | circle off a polygon **corner** | vertex-contact normal + penetration (fast-inv-sqrt) | — | bit-exact |
| `m3c-polypoly.test.ts` | M3c | two overlapping boxes | normal + both clipped contacts (penetration + position) | — | bit-exact |
| `m4d-discrete.test.ts` | M4 | circle resting/penetrating a static floor (no CCD) | full state — the **discrete** solver in isolation | 60 | bit-exact |
| `m4-solver.test.ts` | M4 | large drop, free-fall + settled rest segments | x, y, rot, vx, vy, angvel | 180 | bit-exact |
| | M4 + CCD | **same drop, full trajectory incl. fast-impact arrest** | every field, every step | 180 | bit-exact |
| `m4cd-distance.test.ts` | M4-CCD-a | closest-distance query, 4 configs (face / vertex / penetrating / circle-circle) | signed distance + both witness points + normal | — | bit-exact |
| `m5b-pivot-notrig.test.ts` | M5 Pivot | box pinned at its COM (no rotation) | full state — the 2-DOF point solver | 90 | bit-exact |
| `m5-pivot.test.ts` | M5 Pivot | swinging pendulum (rotates → trig) | bit-exact prefix ≥30 steps; then <1e-9 relative | 90 | bit-exact prefix + trig-limited |
| `m5w-weld-notrig.test.ts` | M5 Weld | box cantilevered off a static anchor | x, y, vy bit-exact; angular residual ≤1e-14 (FP floor) | 90 | bit-exact (held DOFs) |
| `m5d-distance-notrig.test.ts` | M5 Distance | rigid rod, COM-anchored, swinging | full state — 1-DOF rod solver, fully dynamic | 90 | bit-exact |
| `m5a-angle.test.ts` | M5 Angle | spinning box driven into its ±0.5 rad limit | full state — purely-angular 1-DOF + limit | 90 | bit-exact |
| `m5m-motor.test.ts` | M5 Motor | box driven to a constant spin rate | full state — angular velocity drive | 90 | bit-exact |

---

## Coverage by subsystem

- **Kinematics** (gravity, force-based drag, rotation integration) — M0, M1.
- **Broadphase** (shape AABBs) — M2.
- **Narrowphase MANIFOLDS** (all three pairings, geometry only) — M3a/b/c.
- **Discrete contact solver** — M4d, M4 (segments).
- **Continuous collision** — M4-CCD-a, M4 (full trajectory).
- **Constraint solver — all five joints** (Pivot, Weld, Distance, Angle, Motor) — M5*.

> **⚠️ Important scope caveat.** The M3 tests verify the narrowphase *manifolds*
> (the geometry) for all three pairings, but only **circle-vs-polygon-face** is
> wired into the *contact solver* and exercised end-to-end. Circle-vertex contact
> currently **throws**, and circle-circle / polygon-polygon are not yet wired into
> the solver. So the end-to-end, game-usable physics today is **a circle on a
> polygon face** (+ CCD), not "full collision." See the solver-coverage table and
> "Remaining solver work" in [`INTERFACE-COMPAT.md`](./INTERFACE-COMPAT.md).

See `milestones/M0..M7.md` for the per-milestone deep dives.
