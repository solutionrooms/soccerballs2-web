# Soccer Balls 2 — faithful Haxe/OpenFL port (AS3 → Haxe → JS)

Goal: a **logic- and timing-faithful** web port of the original Flash game, produced by
mechanically converting the original AS3 source (`/Users/jonscott/Projects/SoccerBalls2/src`)
to Haxe and compiling with **OpenFL** to HTML5/JS, using **nape-haxe4** for physics (same Nape
lineage as the original). This preserves the original's highly-tuned logic exactly; only minor
floating-point physics drift is accepted (per project direction).

This is NOT the hand-reimplemented TS port (that lives on branch `feature/walkthrough-routes`).

## Toolchain (installed)
- Haxe 4.3.7, lime 8.3.2, openfl 9.5.2, nape-haxe4 2.0.22
- `as3hx` 1.0.6 (converter). Its runtime support (`as3hx.Compat`, `FastXML`, `FastXMLList`) is
  **vendored + patched for Haxe 4** under `vendor/` (the stock `FastXML` uses `implements Dynamic`,
  which Haxe 4 forbids; `vendor/FastXML.hx` rewrites the accessors as `@:op(a.b)` abstracts).

## Build
```
./tools/patch-swf-haxelib.sh      # in-place haxelib patches (SWF symbols, no-loop timelines)
./tools/patch-render-perf.sh      # in-place openfl patch: cache tinted BitmapData.draw (render perf)
haxelib run lime build html5      # -> bin/html5/bin/SoccerBalls2.js
./tools/check.sh                  # fast typecheck (no JS output)
```
The two `patch-*.sh` scripts edit the installed `swf`/`openfl` haxelibs in place (there is no
project-level hook for it). Both are idempotent — re-run after any `haxelib` reinstall/upgrade,
then rebuild. To deploy: re-copy `bin/html5/bin` -> `site/` and push `main` (GitHub Pages).

## Conversion pipeline (reproducible)
```
./tools/convert.sh   # original AS3 -> src.staging (.hx)
./tools/promote.sh   # src.staging -> src
```
`convert.sh` applies only SAFE, auditable transforms (none change runtime logic/timing):
1. string-aware `//` comment strip (defuses as3hx comment bugs)
2. remove Stage3D (`useStage3D`) blocks — the GPU path was never in the shipped SWF
3. resolve `PROJECT::*` conditional-compilation constants for the standard web release build
4. drop dead `if(false){import…}` AIR blocks
5. targeted source fixes (Utils while(); , GameVars comma-operator, Preparing huge `new Array`)
6. run as3hx (guessCasts OFF — this codebase uses PascalCase methods)
7. normalize class-name underscores (as3hx renames defs but not refs)
8. `tools/fixup.sh` — output-level fixes (Number()/int() conversions, Dictionary type params,
   untyped-param signatures, conditional static-init hoists, keyword E4X access, import strips)
9. overlay `overrides/` — hand-written stubs for non-gameplay subsystems

## What's stubbed (non-gameplay — does not affect physics/levels/timing)
`overrides/`: `Lic` (ads/portal/social glue), `FlashConnect`, `MobileSpecific`, `s3d` (Stage3D),
`ClassVars`/`SfxClick` (asset placeholders — real assets wired later), `fl.controls`/`fl.events`
(editor UI components). `LicDef` (licensor constants + GetStage) is KEPT as converted.

## Status (see also the project's task list)
- ✅ Toolchain proven end-to-end (OpenFL + nape-haxe4 → JS).
- ✅ Full conversion reproducible; ~210 .hx compile-clean through the parse phase.
- ⏳ Type-check: a small number of errors remain — mainly the **E4X data layer**
  (`Vars`/`Levels`/`ExternalData`/`TextStrings` use FastXML; a few as3hx E4X mis-conversions need
  faithful hand-porting), plus a few more out-of-scope stubs and field-visibility widenings.
- ⬜ Asset wiring: `bin/*.xml` (levels/objects/vars), `TexturePage_*.png`, audio.
- ⬜ First-render + side-by-side faithfulness check vs the original SWF.
