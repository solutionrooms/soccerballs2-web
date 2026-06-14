#!/usr/bin/env bash
# Reproducible AS3 -> Haxe conversion pipeline for Soccer Balls 2.
#
# Reads the ORIGINAL untouched AS3 source, applies a set of SAFE, auditable
# source transforms (only things that don't change runtime logic/timing), then
# runs as3hx. Every transform exists to get past an as3hx 1.0.6 parser quirk;
# none alters game behaviour.
#
#   ./tools/convert.sh
#
# Output: converted .hx land in $OUT (default ./src).
set -euo pipefail

SRC_ORIG="${SRC_ORIG:-/Users/jonscott/Projects/SoccerBalls2/src}"
WORK="${WORK:-/tmp/sb2src}"
OUT="${OUT:-$(cd "$(dirname "$0")/.." && pwd)/src}"

echo "==> 1. fresh working copy of original AS3"
rm -rf "$WORK"
cp -r "$SRC_ORIG" "$WORK"

echo "==> 2. strip full-line // comments (as3hx ECommented crash; comments are non-functional)"
# A line whose first non-space chars are // is always a comment in AS3 (strings/regex cannot span lines).
find "$WORK" -name '*.as' -exec perl -i -ne 'print unless /^\s*\/\//' {} +

echo "==> 3. resolve PROJECT:: conditional-compilation constants (standard web release build)"
# isFinal=true; mobile / Stage3D / walkthrough / ad-network / external all false (the shipped SoccerBalls2.swf build).
find "$WORK" -name '*.as' -exec perl -i -pe '
  s/PROJECT::isFinal\b/true/g;
  s/PROJECT::(useStage3D|isMobile|isIOS|isGooglePlay|isPlayHaven|isGamePad|isAmazon|isWalkthrough|isAndroid|isExternal)\b/false/g;
' {} +

echo "==> 4. remove dead 'if (false) { import ...; }' blocks (AIR/editor-only imports as3hx can't place)"
# Only matches blocks whose body is purely import statements, so real dead branches are untouched.
find "$WORK" -name '*.as' -exec perl -0777 -i -pe 's/\bif\s*\(false\)\s*\{\s*(?:import\b[^;]*;\s*)+\}//g' {} +

echo "==> 5. Utils.as: give empty-body while loops a block body (as3hx can't parse 'while(c);')"
perl -i -pe 's/while\s*\(\s*arr\[\+\+i\]\s*<\s*v\)\s*;/while ( arr[++i] < v) {}/; s/while\s*\(\s*arr\[--j\]\s*>\s*v\)\s*;/while ( arr[--j] > v) {}/;' "$WORK/Utils.as"

echo "==> 6. GameVars.as: collapse comma-operator typo (a,b) -> b (faithful: AS3 comma operator yields last value)"
# Only the jumpcrouch1 entry has the stray ',( ... , ... )' comma-operator element; anchor on the leading comma
# so the legitimate 'new Array(new Point(0,3),new Point(2,0))' on the crouch1 line above is left untouched.
perl -i -pe 's/,\(new Point\(0,3\),new Point\(2,0\)\)/,new Point(2,0)/' "$WORK/GameVars.as"

echo "==> 7. Preparing.as: new Array(<140+ items>) -> [ ... ] literal (as3hx arg-count parser limit; equivalent for multi-arg)"
perl -0777 -i -pe 's/new Array\(((?:[^()]|\([^()]*\))*)\)/[$1]/g' "$WORK/Preparing.as"

echo "==> 8. run as3hx"
rm -rf "$OUT.staging"
haxelib run as3hx "$WORK" "$OUT.staging" > /tmp/as3hx-run.log 2>&1 || true

echo "==> 9. normalize class-name underscores (as3hx renames class DEFS 'Foo_Bar'->'FooBar' but leaves REFERENCES stale)"
# Every original class whose name has an underscore was renamed by as3hx; make all references match.
# Member/const names (e.g. Type_Circle) are untouched because we only replace the exact class-name token.
SUBS=""
for n in $(find "$SRC_ORIG" -name '*_*.as' | xargs -n1 basename | sed 's/\.as$//'); do
  new=$(printf '%s' "$n" | tr -d '_')
  SUBS="$SUBS s/\\b${n}\\b/${new}/g;"
done
find "$OUT.staging" -name '*.hx' -exec perl -i -pe "$SUBS" {} +
echo "    normalized $(printf '%s\n' $SUBS | grep -c 's/') class names"

echo "==> conversion errors (if any):"
grep -E '^In .* : ' /tmp/as3hx-run.log || echo "  (none)"
echo "==> converted $(find "$OUT.staging" -name '*.hx' | wc -l | tr -d ' ') .hx files into $OUT.staging"
