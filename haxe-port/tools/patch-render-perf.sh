#!/usr/bin/env bash
# Reproducibly patch the installed `openfl` haxelib for render performance.
#
# WHY: BitmapData.draw()'s HTML5/canvas path, when given a colorTransform, allocates a fresh
# BitmapData + does a full getImageData GPU->CPU readback + a per-pixel colorTransform on EVERY
# call. The game tints sprites with a colorTransform (team kits, shadows, rig parts) so this ran
# for every tinted sprite EVERY FRAME — the dominant per-frame cost (and the source of the
# browser's "willReadFrequently / getImageData" warning).
#
# FIX: for immutable BitmapData sources (the atlas frames), the tinted result depends only on
# (source pixels, colorTransform), so memoize it in a per-source cache keyed by the 8 colorTransform
# components. Each unique (sprite, kit-colour) is then tinted ONCE and reused. Non-BitmapData
# sources (live display objects) keep the original per-call path. Purely an internal optimisation:
# identical pixels out.
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

MARK="PATCH (soccerballs2): per-(source bitmap"

if [ ! -f "$BITMAPDATA" ]; then
  echo "ERROR: $BITMAPDATA not found" >&2
  exit 1
fi

if grep -q "$MARK" "$BITMAPDATA"; then
  echo "openfl BitmapData (tint cache): already patched."
  exit 0
fi

# ---- Patch 1: declare the per-source tint cache just before draw() ------------------------------
perl -0777 -i -pe 's{\tpublic function draw\(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null,}{\t// PATCH (soccerballs2): per-(source bitmap, colorTransform) cache of pre-tinted copies. See draw().\n\t\@:noCompletion private static var __tintCache:haxe.ds.ObjectMap<BitmapData, Map<String, BitmapData>> = new haxe.ds.ObjectMap();\n\n\tpublic function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null,}' "$BITMAPDATA"

# ---- Patch 2: memoize the tinted copy in the colorTransform branch ------------------------------
perl -0777 -i -pe 's{\t\t\t\tvar copy = new BitmapData\(width, height, true, 0\);\n\t\t\t\tcopy\.draw\(source, boundsMatrix\);\n\n\t\t\t\tcopy\.colorTransform\(copy\.rect, colorTransform\);\n}{\t\t\t\t// PATCH (soccerballs2): the stock path allocates a BitmapData + runs a full getImageData\n\t\t\t\t// readback + a per-pixel colorTransform on EVERY draw() with a colorTransform \xe2\x80\x94 i.e. every\n\t\t\t\t// kit-tinted sprite, every frame. For immutable BitmapData sources (atlas frames) the\n\t\t\t\t// tinted result depends only on (pixels, colorTransform), so memoize it. Non-BitmapData\n\t\t\t\t// sources (live display objects) keep the original per-call path.\n\t\t\t\tvar copy:BitmapData = null;\n\t\t\t\tvar __tintSrc:BitmapData = (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (source, BitmapData)) ? cast source : null;\n\t\t\t\tif (__tintSrc != null)\n\t\t\t\t{\n\t\t\t\t\tvar __inner = __tintCache.get(__tintSrc);\n\t\t\t\t\tif (__inner == null)\n\t\t\t\t\t{\n\t\t\t\t\t\t__inner = new Map();\n\t\t\t\t\t\t__tintCache.set(__tintSrc, __inner);\n\t\t\t\t\t}\n\t\t\t\t\tvar __key = colorTransform.redMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.greenMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.blueMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.alphaMultiplier\n\t\t\t\t\t\t+ "|" + colorTransform.redOffset\n\t\t\t\t\t\t+ "|" + colorTransform.greenOffset\n\t\t\t\t\t\t+ "|" + colorTransform.blueOffset\n\t\t\t\t\t\t+ "|" + colorTransform.alphaOffset;\n\t\t\t\t\tcopy = __inner.get(__key);\n\t\t\t\t\tif (copy == null)\n\t\t\t\t\t{\n\t\t\t\t\t\tcopy = new BitmapData(width, height, true, 0);\n\t\t\t\t\t\tcopy.draw(source, boundsMatrix);\n\t\t\t\t\t\tcopy.colorTransform(copy.rect, colorTransform);\n\t\t\t\t\t\t__inner.set(__key, copy);\n\t\t\t\t\t}\n\t\t\t\t}\n\t\t\t\telse\n\t\t\t\t{\n\t\t\t\t\tcopy = new BitmapData(width, height, true, 0);\n\t\t\t\t\tcopy.draw(source, boundsMatrix);\n\t\t\t\t\tcopy.colorTransform(copy.rect, colorTransform);\n\t\t\t\t}\n\n}' "$BITMAPDATA"

if grep -q "$MARK" "$BITMAPDATA"; then
  echo "openfl BitmapData (tint cache): patched at $BITMAPDATA"
else
  echo "ERROR: openfl BitmapData tint-cache patch did not apply (source layout changed?)" >&2
  exit 1
fi
