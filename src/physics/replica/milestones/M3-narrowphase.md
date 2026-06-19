# M3 — Narrowphase (contact manifolds) ✅

All three shape pairings done, bit-for-bit vs the real original Nape AS3:
**M3a circle-circle ✅ · M3b circle-polygon ✅ · M3c polygon-polygon ✅.**

The game uses all three (a ball is a circle; terrain and crates are polygons; the
crate is a *dynamic* polygon, so poly-poly is real).

> Tested vs the real original Nape AS3. The manifold is observed via the public
> arbiter API after one `space.step` (`CollisionArbiter.normal`,
> `Contact.penetration`) — no solver needed, since narrowphase runs pre-solve.

## Scope finding

Nape's narrowphase is **one ~1100-line function**, `contactCollide`
(`ZPP_Collide.as:176`), covering all three shape pairings:
- **circle-circle** (lines 1088–1300) — self-contained, **done**;
- **circle-polygon** (~950–1080) — closest-feature;
- **polygon-polygon** (219–~950) — SAT over edge normals + clipping. The bulk.

**Key discovery:** Nape normalizes with a **Quake fast-inverse-sqrt** (float32
bit-hack `1597463007 - (i>>1)` + one Newton step), *not* `Math.sqrt`. So normals
are **not unit length** (e.g. 0.99977) and distances carry the approximation
error. The replica reproduces this bit-for-bit via a `Float32Array`/`Int32Array`
round-trip (`fastInvSqrt` in `nape-core.ts`). This matters everywhere Nape
normalizes — including poly-poly — so it's a prerequisite the rest of M3 builds on.

## M3a — circle-circle ✅

**Replica:** `circleCircleManifold(ha, hb)` — radii sum, centre delta, fast-inv-sqrt
normal, penetration. Bodies passed in the original's `(body1, body2)` order (the
normal sign depends on it; the harness traces that order).

**Gate** (`m3-circle.test.ts`): two overlapping circles (r20, centres 30 apart):
- `normal = (−0.99977, −0)` — bit-for-bit, fast-inv-sqrt and all;
- `penetration = 9.99320` — bit-for-bit.

```
 ✓ manifold normal + penetration match the original bit-for-bit (incl. fast-inv-sqrt)
```

## M3b — circle-polygon ✅

`circlePolyManifold` (`nape-core.ts`): deepest-edge loop (`sep = gnorm·c − gproj − r`),
then a region test → edge-face contact (exact) or vertex contact (fast-inv-sqrt).
Edge normals computed Nape's way (edge dir rotated 90°, normalized with
`Math.sqrt` — bit-exact across AVM2/V8). Gate (`m3b-circlepoly.test.ts`):
EDGE `(0,−1)` pen 2.0; VERTEX `(−0.35870,−0.93263)` pen 1.06092 — both bit-for-bit.

## M3c — polygon-polygon ✅

`polyPolyManifold` (`nape-core.ts`): SAT over both polys' edge normals → pick
reference/incident edge → clip the incident edge to the reference side bounds →
up to 2 contacts (point + penetration). Gate (`m3c-polypoly.test.ts`): two
overlapping boxes → normal `(0,1)`, two contacts pen 8.0 at `(180,192)`/`(220,192)`,
bit-for-bit (contact set matched order-independently; ordering/ids handled in M4).

## Deferred to M4

Contact **ids** (`hash`) and ordering for warm-starting; contact `position`
getter nuances; how `param4`/`rev` are derived from arbiter shape order (the
manifold tests pin param1=body1 directly).
