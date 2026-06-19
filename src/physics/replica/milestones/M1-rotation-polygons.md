# M1 — Rotation + polygon mass properties ✅

Two gates, **both done** — all bit-for-bit vs the real original Nape AS3
(`m1-rotation.test.ts`, 3 tests). M1a = rotation + central impulse (circles);
M1b = polygon mass/inertia.

> Tested vs the **real original Nape AS3** (harness `tools/nape-oracle/harness-m1.as`
> → FFDec → Ruffle → golden), same as M0. See the
> [version rule](README.md#-the-version-rule-read-first).

## M1a — rotation + central impulse ✅

Extends the contact-free engine with angular dynamics and `applyImpulse`,
verified on circles (no `sin/cos` in the traced values, so still exact).

**Replica additions** (`nape-core.ts`): `setVel`, `setAngVel`, `getInertia`,
and `applyImpulse` (central: `vel += J·imass`, `Body.as:2406`). The angular
integrator (`updateVel` `sinertia` branch) and rotation path (`updatePos`,
`dr = angvel·dt`) were already ported in M0; M1a is the first time they're
exercised.

**Gate** (`m1-rotation.test.ts`, bit-for-bit vs original):
- **SPIN** — a circle given `angularVel = 5.0` under gravity: mass + inertia,
  then 180 steps of `(y, vy, rot, angvel)`. Confirms angular drag decay
  (`5.0 → 4.780`), rotation accumulation, circle inertia (`32.572 = 72·area·density`),
  and that linear free-fall is unaffected by spin.
- **KICK** — a circle given a central `applyImpulse(37, −53)`: `vx = 81.79 = 37/mass`,
  then 60 steps of `(x, y, vx, vy)`.

```
 ✓ SPIN: mass, inertia and 180 steps (y, vy, rot, angvel) match the original
 ✓ KICK: central applyImpulse + 60 steps (x, y, vx, vy) match the original
```

**`sin/cos` note:** `updatePos` calls `Math.sin/cos` for the body axis once a
body rotates, but the *traced* values (`rot` is pure `Σ angvel·dt`) don't depend
on it for a centred body — so M1a is bit-exact across AVM2/V8. The trig only
reaches observable state once a rotation feeds geometry (offset COM, or rotated
vertices in collision) — first relevant in M3.

## M1b — polygon mass/inertia ✅

**Replica additions** (`nape-core.ts`): `addPolygon` + a `validateShapeGeom`
helper porting the polygon `area`/`inertia` (`ZPP_Polygon.as:1198`) and `localCOM`
centroid (`ZPP_Body.as:360`) — the shoelace traversals, in Nape's exact vertex
order (`cur = v1…v_{n-1}, v0`); `align` extended to shift polygon vertices.

**Robustness:** the harness traces the polygon's *actual stored vertices* (post
Nape construction) and the test feeds those exact verts to the replica — so any
winding/normalisation Nape applies can't cause a mismatch. (For the box, Nape
kept the input order.)

**Gate** (`POLY` in `m1-rotation.test.ts`): a 40×24 convex box, `angularVel = 3.0`,
under gravity:
- `mass = 0.96` (= area·density/1000) and `inertia = 174.08` (= m/12·(w²+h²))
  match the original bit-for-bit;
- 120 steps of `(y, vy, rot, angvel)` match.

```
 ✓ POLY: box mass, inertia and 120 steps (y, vy, rot, angvel) match the original
```

Convex decomposition stays out of the bit-exact loop — the harness feeds an
already-convex polygon, as the replica's `addPolygon` expects.

**Deferred:** off-centre `applyImpulse` (angular term) and offset-COM `align`
shift — not needed until later milestones; will be verified when first exercised.
