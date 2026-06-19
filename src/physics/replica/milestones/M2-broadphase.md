# M2 — Broadphase (shape AABB) ✅

**Status:** done — shape world-AABBs match the **real original Nape AS3**
bit-for-bit (`m2-aabb.test.ts`).

## Scope

The broadphase's directly-observable geometric core is the per-shape world AABB
(`Shape.bounds`). M2 verifies that computation:
- **circle** — `worldCOM ± radius` (`ZPP_Shape.as:658`);
- **polygon** — min/max of the world-transformed vertices (`ZPP_Shape.as:682`).

World transform: `g = pos + (axisy·lₓ − axisx·l_y, lₓ·axisx + l_y·axisy)`, with
`axis = (sin rot, cos rot)`. All M2 cases are **unrotated**, so `sin/cos` are the
exact specials `(0, 1)` → bit-exact across AVM2/V8.

The candidate-**pair list** (and its ordering) is *internal* — not exposed by the
public Nape API. Its bit-exactness only matters for multi-contact solver
determinism, so it's verified later, when multi-contact results become observable
(M4), rather than via an internal dump here.

## Replica additions

`shapeAABB(h, i)` in `nape-core.ts` — circle and polygon world AABB.

## Gate (`m2-aabb.test.ts`)

Four shapes, all bit-for-bit vs the original:
- `c0` circle r12 @ (100,50) → `[88, 38, 112, 62]`
- `c1` circle r7.5 @ (−30,200) → `[−37.5, 192.5, −22.5, 207.5]`
- `b0` box ±(20,12) @ (300,80) → `[280, 68, 320, 92]`
- `t0` **off-centre triangle** @ (50,400) → `[37, 385, 63, 410]`

`t0` is off-centre (centroid ≠ origin), so it also exercises `align` with a
non-zero localCOM for the first time — confirming the body-recentre + polygon
centroid path, not just the AABB.

```
 ✓ circle / box / off-centre triangle world AABBs match the original bit-for-bit
```

## Deferred

Rotated AABBs (which go through `sin/cos`) — first relevant when rotated bodies
collide; will be checked in M3 where rotated geometry feeds the manifold.
