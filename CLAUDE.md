# SoccerBalls2 — shared context (read by BOTH sessions)

This is the **shared** context file. Session-specific context lives in:
- `claude-haxe-port.md` — the **game + glue** session (Haxe game code + nape shim + testing).
- `claude-nape-replica.md` — the **replica-engine** session (edits the bit-exact physics core).

## What this project is

Porting the Flash/AS3 game **Soccer Balls 2** (700×525 @ 60fps, Nape physics, drag-to-kick puzzler) to the web.

- **AS3 source of truth:** `/Users/jonscott/Projects/SoccerBalls2` (the original shipped game; gameplay/physics truth).
- **The port:** `/Users/jonscott/Projects/soccerballs2-web`.

## ⚠️ Only the Haxe conversion is live

- **LIVE:** `soccerballs2-web/haxe-port/` — Flash→Haxe/OpenFL port of the game. Served on **localhost:8753** (serves `bin/html5/bin/`). This is the real product.
- **DEFUNCT:** the TypeScript/Vite port (`soccerballs2-web/src/**`) — abandoned. **Do not work on it.**
- **EXCEPTION — still live:** `soccerballs2-web/src/physics/replica/**` is the bit-exact **replica physics engine**. It is NOT part of the defunct TS game; it is bundled to JS and loaded by the Haxe game. (`src/physics/nape-world.ts` is the old TS→replica bridge — keep only as a *reference* for correct filter/shape mapping.)

## The current goal

The Haxe game ships with **nape-haxe4 2.0.22**, whose physics *feel* is wrong (newer Nape; diverges from the 2012 original). We are swapping it for the **replica** engine, which reproduces the 2012 Nape bit-for-bit.

**Architecture of the swap (engine + game both UNCHANGED):**
```
game `import nape.*`  ──(build -Dreplica)──▶  nape-shim/nape/**  (Haxe nape-API shim, "the glue")
                                                     │
                                                     ▼
                                          rnape.NapeReplicaJS  (extern, @:native("NapeReplica"))
                                                     │
                                                     ▼
                                          nape-replica.js  (esbuild IIFE bundle of src/physics/replica/, global `NapeReplica`)
```
- Build swap is in `haxe-port/project.xml`: `<haxelib name="nape-haxe4" unless="replica"/>` + `<source path="nape-shim" if="replica"/>`.
- `lime build html5 -Dreplica` → shim build (replica engine). `lime build html5` → default build (nape-haxe4) for A/B.
- Constraints: **the replica ships unchanged**, **the game ships unchanged**; the only new code is the shim glue.

## Verification gates

- **Level 9** — wall bank shot (the feel bug that motivated all this).
- **Level 19** — revolute joints.
(`sb2LoadLevel` is 0-based: level 9 = index 8, level 19 = index 18.)

## Division of labour (two sessions, do not cross streams)

| Owns | Session | Files |
|---|---|---|
| Game code + shim glue + tests | **haxe-port** (`claude-haxe-port.md`) | `haxe-port/src/**`, `haxe-port/nape-shim/**`, debug harness |
| Replica physics core | **nape-replica** (`claude-nape-replica.md`) | `src/physics/replica/**` |

If one session finds a bug that lives in the **other** session's files, it **flags it** rather than editing across the boundary.

## Cross-session coordination — `sb2_developer_messages.md`

The two sessions talk to each other via **`sb2_developer_messages.md`** (repo root). Use it to hand
off findings, flag cross-boundary bugs, and request diagnostics. **Newest message on top**; each
message carries a `⬜ UNREAD` indicator the *recipient* flips to `✅ READ`. Check it at the start of
a session and after finishing a unit of work that affects the other side.
