# M6 — Raycast + sleeping / islands ⏳

**Status:** planned.

## Goal

Cover the remaining engine subsystems the game touches: downward raycast, the
sleep/island machinery, and the kinematic-mover wake hack.

## Scope

- **Raycast** — straight-down `Ray` + `RayResult` (`raycastFloorY`), with the
  interaction filter.
- **Sleeping / islands** — body sleep thresholds, island construction, and the
  order islands/bodies are processed (affects solver determinism).
- **`wakeJointPartners`** — the zero-impulse wake trick for sleeping welded
  riders of a kinematic mover (`NapeWorld.hx:369`).
- `touchingDynamicBodies` (arbiter scan), `bodyContains`, `bodyArea`.

## Gate

- Raycast hit distance/point matches the reference bit-for-bit across configs.
- A scene that settles and **sleeps** matches the reference step-for-step,
  including *when* each body sleeps and the post-sleep stillness.
- The **coin-sensor** and switch-persist scenarios stay bit-identical.

## Risks / open questions

- Sleep timing is threshold-sensitive; a one-frame-early sleep diverges the
  whole scene. The multi-step gate localizes it.
