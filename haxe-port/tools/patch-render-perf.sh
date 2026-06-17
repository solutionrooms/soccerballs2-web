#!/usr/bin/env bash
# Reproducibly patch the installed `openfl` haxelib for render performance + diagnostics.
#
# PATCH A — tint cache (perf):
# BitmapData.draw()'s HTML5/canvas path, when given a colorTransform, allocates a fresh BitmapData
# + does a full getImageData GPU->CPU readback + a per-pixel JS recolor on EVERY call. The game
# tints sprites with a colorTransform (team kits, shadows, rig parts) so this ran for every tinted
# sprite EVERY FRAME — the dominant per-frame cost (and the source of the "willReadFrequently"
# warning). For immutable BitmapData sources (atlas frames) the tinted result depends only on
# (source pixels, colorTransform), so memoize it per source, keyed by the 8 colorTransform
# components. Each unique (sprite, kit-colour) is tinted ONCE and reused. Identical pixels out.
#
# PATCH B — composite counter (diagnostics):
# A static BitmapData.__drawCalls incremented in draw()/copyPixels(), so the perf HUD can show the
# number of BitmapData composites per frame (hardware-independent). The game loop resets it each
# frame. No behavioural effect.
#
# Applied IN PLACE to the haxelib (no project hook exists for it), so re-run after any `haxelib`
# reinstall or version change. Idempotent — running twice is a no-op.
#
# Run:  tools/patch-render-perf.sh   [optional: path to BitmapData.hx for testing]
set -euo pipefail

if [ "${1:-}" != "" ]; then
  BITMAPDATA="$1"
else
  OPENFL_DIR="$(haxelib libpath openfl 2>/dev/null | tr -d '\r')"
  if [ -z "$OPENFL_DIR" ] || [ ! -d "$OPENFL_DIR" ]; then
    echo "ERROR: could not locate the 'openfl' haxelib (haxelib libpath openfl). Is it installed?" >&2
    exit 1
  fi
  BITMAPDATA="$OPENFL_DIR/src/openfl/display/BitmapData.hx"
fi

if [ ! -f "$BITMAPDATA" ]; then
  echo "ERROR: $BITMAPDATA not found" >&2
  exit 1
fi

# ---- Patch A1: declare the per-source tint cache + composite counter just before draw() ---------
if grep -q "PATCH (soccerballs2): per-(source bitmap" "$BITMAPDATA"; then
  echo "openfl BitmapData (tint cache field): already patched."
else
  perl -0777 -i -pe 's{\tpublic function draw\(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null,}{\t// PATCH (soccerballs2): per-(source bitmap, colorTransform) cache of pre-tinted copies. See draw().\n\t\@:noCompletion private static var __tintCache:haxe.ds.ObjectMap<BitmapData, Map<String, BitmapData>> = new haxe.ds.ObjectMap();\n\n\t// PATCH (soccerballs2): per-frame composite counter for the perf HUD (reset each frame by the game loop).\n\tpublic static var __drawCalls:Int = 0;\n\n\tpublic function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null,}' "$BITMAPDATA"
  echo "openfl BitmapData (tint cache field): patched."
fi

# ---- Patch A2: memoize the tinted copy in the colorTransform branch -----------------------------
if grep -q "PATCH (soccerballs2): the stock path allocates" "$BITMAPDATA"; then
  echo "openfl BitmapData (tint cache body): already patched."
else
  perl -0777 -i -pe 's{\t\t\t\tvar copy = new BitmapData\(width, height, true, 0\);\n\t\t\t\tcopy\.draw\(source, boundsMatrix\);\n\n\t\t\t\tcopy\.colorTransform\(copy\.rect, colorTransform\);\n}{\t\t\t\t// PATCH (soccerballs2): the stock path allocates a BitmapData + runs a full getImageData\n\t\t\t\t// readback + a per-pixel colorTransform on EVERY draw() with a colorTransform \xe2\x80\x94 i.e. every\n\t\t\t\t// kit-tinted sprite, every frame. For immutable BitmapData sources (atlas frames) the\n\t\t\t\t// tinted result depends only on (pixels, colorTransform), so memoize it. Non-BitmapData\n\t\t\t\t// sources (live display objects) keep the original per-call path.\n\t\t\t\tvar copy:BitmapData = null;\n\t\t\t\tvar __tintSrc:BitmapData = (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (source, BitmapData)) ? cast source : null;\n\t\t\t\tif (__tintSrc != null)\n\t\t\t\t{\n\t\t\t\t\tvar __inner = __tintCache.get(__tintSrc);\n\t\t\t\t\tif (__inner == null)\n\t\t\t\t\t{\n\t\t\t\t\t\t__inner = new Map();\n\t\t\t\t\t\t__tintCache.set(__tintSrc, __inner);\n\t\t\t\t\t}\n\t\t\t\t\tvar __key = colorTransform.redMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.greenMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.blueMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.alphaMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.redOffset\n\t\t\t\t\t\t+ "|" + colorTransform.greenOffset\n\t\t\t\t\t\t+ "|" + colorTransform.blueOffset\n\t\t\t\t\t\t+ "|" + colorTransform.alphaOffset;\n\t\t\t\t\tcopy = __inner.get(__key);\n\t\t\t\t\tif (copy == null)\n\t\t\t\t\t{\n\t\t\t\t\t\tcopy = new BitmapData(width, height, true, 0);\n\t\t\t\t\t\tcopy.draw(source, boundsMatrix);\n\t\t\t\t\t\tcopy.colorTransform(copy.rect, colorTransform);\n\t\t\t\t\t\t__inner.set(__key, copy);\n\t\t\t\t\t}\n\t\t\t\t}\n\t\t\t\telse\n\t\t\t\t{\n\t\t\t\t\tcopy = new BitmapData(width, height, true, 0);\n\t\t\t\t\tcopy.draw(source, boundsMatrix);\n\t\t\t\t\tcopy.colorTransform(copy.rect, colorTransform);\n\t\t\t\t}\n\n}' "$BITMAPDATA"
  echo "openfl BitmapData (tint cache body): patched."
fi

# ---- Patch B: increment the composite counter in draw() and copyPixels() ------------------------
if grep -q "count BitmapData composites for this displayed frame" "$BITMAPDATA"; then
  echo "openfl BitmapData (draw counter): already patched."
else
  # draw(): right after the null guard
  perl -0777 -i -pe 's{(\tpublic function draw\(source:IBitmapDrawable[^\n]*\n[^\n]*smoothing:Bool = false\):Void\n\t\{\n\t\tif \(source == null\) return;\n)}{$1\t\t__drawCalls++; // PATCH (soccerballs2): count BitmapData composites for this displayed frame\n}' "$BITMAPDATA"
  # copyPixels(): right after its guard
  perl -0777 -i -pe 's{(\tpublic function copyPixels\(sourceBitmapData:BitmapData[^\n]*\n[^\n]*mergeAlpha:Bool = false\):Void\n\t\{\n\t\tif \(!readable \|\| sourceBitmapData == null\) return;\n)}{$1\t\t__drawCalls++; // PATCH (soccerballs2): count composites for the perf HUD\n}' "$BITMAPDATA"
  echo "openfl BitmapData (draw counter): patched."
fi

# ---- verify everything landed -------------------------------------------------------------------
if grep -q "PATCH (soccerballs2): per-(source bitmap" "$BITMAPDATA" \
   && grep -q "PATCH (soccerballs2): the stock path allocates" "$BITMAPDATA" \
   && grep -q "count BitmapData composites for this displayed frame" "$BITMAPDATA"; then
  echo "openfl BitmapData: all render-perf patches present at $BITMAPDATA"
else
  echo "ERROR: one or more openfl BitmapData render-perf patches did not apply (source layout changed?)" >&2
  exit 1
fi
