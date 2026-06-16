#!/usr/bin/env bash
# Reproducibly patch the installed `swf` haxelib (openfl-swf library exporter) for this port.
#
# The shipped openfl-swf builds SWF library symbols LAZILY (named child instances only appear on
# the first render frame) and only assigns parent.childName fields under -D openfljs. The original
# AS3 game relies on Flash semantics: `new SomeSymbol()` immediately has its named children, reachable
# as properties, recursively. These two edits restore that. They are applied IN PLACE to the haxelib
# (there is no project-level hook for it), so this script re-applies them after any `haxelib` reinstall
# or version change. It is idempotent — running it twice is a no-op.
#
# Run:  tools/patch-swf-haxelib.sh
set -euo pipefail

SWF_DIR="$(haxelib libpath swf 2>/dev/null | tr -d '\r')"
if [ -z "$SWF_DIR" ] || [ ! -d "$SWF_DIR" ]; then
  echo "ERROR: could not locate the 'swf' haxelib (haxelib libpath swf). Is it installed?" >&2
  exit 1
fi
SPRITE="$SWF_DIR/src/swf/exporters/animate/AnimateSpriteSymbol.hx"
TIMELINE="$SWF_DIR/src/swf/exporters/animate/AnimateTimeline.hx"
MARK="PATCH (soccerballs2)"

# ---- Patch 1: AnimateSpriteSymbol.__constructor — eager frame-1 construction ------------------
# attachTimeline only sets __scope and defers child construction to the first render. Call init()
# right after so `new Symbol()` already has its named children (Flash semantics), recursively.
if grep -q "$MARK" "$SPRITE"; then
  echo "AnimateSpriteSymbol: already patched."
else
  perl -0777 -i -pe 's/(\t+movieClip\.attachTimeline\(timeline\);\n)/$1\t\t\t\t\/\/ PATCH (soccerballs2): construct frame 1 eagerly so named child instances exist right\n\t\t\t\t\/\/ after `new Symbol()` (Flash semantics). attachTimeline only sets __scope and defers\n\t\t\t\t\/\/ construction to the first render frame; init() builds frame 1 and assigns named fields\n\t\t\t\t\/\/ while keeping timeline state intact for subsequent playback.\n\t\t\t\t\@:privateAccess timeline.init(movieClip);\n\t\t\t\t\/\/ PATCH (soccerballs2): stop at frame 1 — openfl-swf does not run AS3 frame scripts (the\n\t\t\t\t\/\/ frame-1 stop() that kept Flash clips static), so clips would auto-play on loop. This game\n\t\t\t\t\/\/ drives all animation explicitly (gotoAndStop\/gotoAndPlay), so default to stopped.\n\t\t\t\tmovieClip.stop();\n/' "$SPRITE"
  grep -q "$MARK" "$SPRITE" && echo "AnimateSpriteSymbol: patched." || { echo "ERROR: AnimateSpriteSymbol patch did not apply" >&2; exit 1; }
fi

# ---- Patch 2: AnimateTimeline.__updateDisplayObject — always assign named children -------------
# The stock library only did `Reflect.setField(__sprite, child.name, child)` under #if openfljs,
# so on normal HTML5 nested instances (e.g. mainArea.btn_quit) were never assigned. Make it
# unconditional so named library instances are reachable as parent.instanceName, recursively.
if grep -q "$MARK" "$TIMELINE"; then
  echo "AnimateTimeline: already patched."
else
  perl -0777 -i -pe 's/\t\t#if openfljs\n\t\tReflect\.setField\(__sprite, displayObject\.name, displayObject\);\n\t\t#end\n/\t\t\/\/ PATCH (soccerballs2): assign every named child as a property of its parent (Flash semantics:\n\t\t\/\/ named library instances are reachable as parent.instanceName, recursively). The stock library\n\t\t\/\/ only did this under #if openfljs, so on normal HTML5 nested instances like mainArea.btn_quit\n\t\t\/\/ were never assigned and read back as undefined.\n\t\tif (displayObject.name != null)\n\t\t{\n\t\t\tReflect.setField(__sprite, displayObject.name, displayObject);\n\t\t}\n/' "$TIMELINE"
  grep -q "$MARK" "$TIMELINE" && echo "AnimateTimeline: patched." || { echo "ERROR: AnimateTimeline patch did not apply" >&2; exit 1; }
fi

echo "swf haxelib patched at: $SWF_DIR"
