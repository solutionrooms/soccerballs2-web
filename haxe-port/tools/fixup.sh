#!/usr/bin/env bash
# Output-level fixups applied to the CONVERTED .hx (not the AS3 source). These
# correct mechanical as3hx artefacts that are wrong but bounded and unambiguous.
# Safe to run repeatedly (idempotent). convert.sh calls this on its staging dir.
#
#   ./tools/fixup.sh [target_dir]   (default: ./src)
set -euo pipefail
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)/src}"

echo "==> fixup: AS3 type-conversion calls (guessCasts=off leaves Number(x)->Float(x) etc. uncompilable)"
# Float(x)/Int(x)/String(x) are AS3 Number()/int()/String() conversions; map to as3hx's faithful helpers.
# Recursive (?1) matches balanced parens so nested args are handled. These type names never name methods,
# and \b before the name avoids touching parseInt(/toString(/UInt(.
find "$DIR" -name '*.hx' -exec perl -0777 -i -pe '
  s/\bFloat(\((?:[^()]++|(?1))*\))/as3hx.Compat.parseFloat$1/g;
  s/\bInt(\((?:[^()]++|(?1))*\))/as3hx.Compat.parseInt$1/g;
  s/\bString(\((?:[^()]++|(?1))*\))/Std.string$1/g;
  s/\bBool\(false\)/false/g;
  s/\bBool\(true\)/true/g;
' {} +

echo "==> fixup: UI.AddAnimatedMCTickButton dropped param (as3hx loses the untyped '_hoverCallback = null,')"
perl -i -pe 's/_hoverCallback _initialTickState : Bool = false/_hoverCallback : Dynamic = null, _initialTickState : Bool = false/' "$DIR/uIPackage/UI.hx" 2>/dev/null || true

echo "==> fixup: hoist conditional static-init blocks as3hx mangled into ClassName_static_initializer"
# UI: 'static var useFullTransition' was conditional on isMobile (=false) -> plain field, value true.
perl -0777 -i -pe 's/private static var UI_static_initializer = (\{(?:[^{}]++|(?1))*\})/private static var useFullTransition : Bool = true;/' "$DIR/uIPackage/UI.hx" 2>/dev/null || true
# Vars: drop the mangled [Embed] VarsData block; the ClassVars stub + asset loading provide the data.
perl -0777 -i -pe 's/private static var Vars_static_initializer = (\{(?:[^{}]++|(?1))*\})//' "$DIR/Vars.hx" 2>/dev/null || true

echo "==> fixup: AS3 untyped Dictionary -> openfl.utils.Dictionary<Dynamic,Dynamic>"
find "$DIR" -name '*.hx' -exec perl -i -pe '
  s/new Dictionary\(/new Dictionary<Dynamic, Dynamic>(/g;
  s/: Dictionary\b(?!<)/: Dictionary<Dynamic, Dynamic>/g;
' {} +

echo "==> fixup: restore untyped-param signatures as3hx mangled (dropped commas between untyped params)"
perl -i -pe 's/function GetDirBetween\(x0 y0 x1 y1\)/function GetDirBetween(x0 : Float, y0 : Float, x1 : Float, y1 : Float)/' "$DIR/GameObjBase.hx" 2>/dev/null || true
perl -i -pe 's/function SetAnimRangeSingle\(name reset : Bool/function SetAnimRangeSingle(name : Dynamic, reset : Bool/' "$DIR/GameObjBase.hx" 2>/dev/null || true

echo "==> fixup: widen AS3 internal/default fields wrongly made private but accessed cross-class"
perl -i -pe 's/private var active : Bool;/public var active : Bool;/' "$DIR/Particle.hx" 2>/dev/null || true

echo "==> fixup: strip imports of flash/adobe types absent from OpenFL (unused in gameplay)"
# grows as the compiler surfaces them; all confirmed unused at their import sites.
STRIP='^import (flash\.(text\.TextRun|display\.ActionScriptVersion)|com\.adobe\.net\.proxies\.RFC2817Socket);'
find "$DIR" -name '*.hx' -exec perl -i -ne "print unless /$STRIP/" {} +

echo "==> fixup: E4X access of Haxe-keyword-named attrs/nodes (x.att.default -> x.att.resolve(\"default\"))"
KW='default|var|function|in|cast|switch|class|override|public|private|static|if|else|for|while|return|true|false|null|new|untyped|inline|using|macro|extern|abstract|typedef|enum|interface|extends|implements|package|import|do|try|catch|throw|continue|break'
find "$DIR" -name '*.hx' -exec perl -i -pe "s/\\.(att|node|nodes|has|hasNode)\\.($KW)\\b/.\$1.resolve(\"\$2\")/g" {} +

echo "==> fixup done in $DIR"
