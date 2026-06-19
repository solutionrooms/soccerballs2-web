# M7 — Cutover ⏳

**Status:** planned.

## Goal

Make the replica a true drop-in for `nape.js` and remove the Haxe toolchain from
the runtime.

## Scope

- Implement the full `NapeWorld` facade surface on the replica (`createStaticLoop`
  with precomputed convex pieces, the contact/impact drains, all body ops).
- A `ReplicaPhysWorld implements PhysWorld` adapter alongside `NapePhysWorld`,
  selectable from the settings menu (third engine option).
- Run the existing acceptance suites (`nape-sim.test.ts`, `lvl9-bank`,
  `lvl12-switch`, `coin-sensor`) against the replica.
- Keep `nape.js` **only** as the test oracle, not a shipped asset.

## Gate

- Every existing engine acceptance test passes on the replica.
- All 36 levels simulate bit-identically (or within the agreed tolerance for any
  documented, signed-off transcendental edge) to `nape.js`.
- Bundle no longer loads `nape.js` at runtime.

## Risks / open questions

- Any milestone that landed with a *documented* (non-bit) tolerance must be
  re-confirmed acceptable at the whole-game level here.
- Convex-decomposition piece lists must be precomputed and committed so both the
  build and the oracle use identical geometry.
