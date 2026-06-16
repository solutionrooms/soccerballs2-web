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

echo "==> 0. pin as3hx config (guessCasts OFF: this codebase uses PascalCase methods, so"
echo "        guessCasts wrongly turns hundreds of method calls like Render(x) into cast(x,Render))"
CFG="$HOME/.as3hx_config.xml"
[ -f "$CFG" ] && [ ! -f "$CFG.sb2bak" ] && cp "$CFG" "$CFG.sb2bak"
cat > "$CFG" <<'EOF'
<as3hx>
    <errorContinue value="true" />
    <indentChars value="    " />
    <newlineChars value="\n" />
    <bracesOnNewline value="true" />
    <spacesOnTypeColon value="true" />
    <uintToInt value="true" />
    <vectorToArray value="true" />
    <guessCasts value="false" />
    <functionToDynamic value="false" />
    <getterMethods value="get_%I" />
    <setterMethods value="set_%I" />
    <forcePrivateSetter value="true" />
    <forcePrivateGetter value="true" />
    <getterSetterStyle value="haxe" />
    <testCase value="false" />
    <excludeList />
    <conditionalCompilationList />
    <dictionaryToHash value="false" />
    <verifyGeneratedFiles value="false" />
    <useFastXML value="true" />
    <useCompat value="true" />
    <postProcessor value="" />
    <importPaths></importPaths>
</as3hx>
EOF

echo "==> 1. fresh working copy of original AS3"
rm -rf "$WORK"
cp -r "$SRC_ORIG" "$WORK"

echo "==> 2. strip // line comments (string-aware), defusing as3hx comment bugs (ECommented crash,"
echo "        and brace miscounting when a comment contains '{' e.g. 'if(false) //code){')"
# Remove trailing+full-line // comments while respecting "..." and '...' literals so URLs like
# "http://x" inside strings are never touched. Comments are non-functional, so this is safe.
find "$WORK" -name '*.as' -exec perl -i -pe '
  my $in=$_; my $o=""; my $q=""; my $i=0; my $n=length($in);
  while ($i<$n) {
    my $c=substr($in,$i,1);
    if ($q ne "") { $o.=$c; if ($c eq "\\") { $o.=substr($in,$i+1,1); $i+=2; next; } $q="" if $c eq $q; $i++; }
    elsif ($c eq "\x22" || $c eq "\x27") { $q=$c; $o.=$c; $i++; }
    elsif ($c eq "/" && substr($in,$i+1,1) eq "/") { last; }
    else { $o.=$c; $i++; }
  }
  $o =~ s/\s+$//;
  $_ = $o . "\n";
' {} +

echo "==> 2.5 remove Stage3D code blocks (useStage3D=false: the GPU path was never in the shipped SWF)"
# Remove 'if (PROJECT::useStage3D) { ... }' and bare 'PROJECT::useStage3D { ... }' blocks (balanced braces,
# recursive (?1)). Anchored so 'PROJECT::useStage3D == false' (the live path) is never matched. This deletes
# the Stage3D method defs AND their calls together, so no dead code references the (unported) s3d classes.
find "$WORK" -name '*.as' -exec perl -0777 -i -pe '
  # if (useStage3D) {A} else  -> drop the if+block+else so the else body runs unconditionally (faithful)
  1 while s/if\s*\(\s*PROJECT::useStage3D\s*\)\s*(\{(?:[^{}]++|(?1))*\})\s*else\b/ /g;
  # if (useStage3D) {A}  (no else)  -> drop entirely
  1 while s/if\s*\(\s*PROJECT::useStage3D\s*\)\s*(\{(?:[^{}]++|(?1))*\})//g;
  # bare block-form  PROJECT::useStage3D {A}  -> drop entirely (method-level conditional compile)
  1 while s/\bPROJECT::useStage3D\s*(\{(?:[^{}]++|(?1))*\})//g;
' {} +

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

echo "==> 10. output-level fixups (type-conversion calls etc.)"
"$(dirname "$0")/fixup.sh" "$OUT.staging"

echo "==> 11. overlay hand-written overrides (stubs for ads/portal layers, manual fixes)"
OVR="$(cd "$(dirname "$0")/.." && pwd)/overrides"
if [ -d "$OVR" ]; then
  ( cd "$OVR" && find . -name '*.hx' -print0 | while IFS= read -r -d '' f; do
      mkdir -p "$OUT.staging/$(dirname "$f")"; cp "$f" "$OUT.staging/$f";
    done )
  echo "    applied $(find "$OVR" -name '*.hx' | wc -l | tr -d ' ') override files"
fi

echo "==> conversion errors (if any):"
grep -E '^In .* : ' /tmp/as3hx-run.log || echo "  (none)"
echo "==> converted $(find "$OUT.staging" -name '*.hx' | wc -l | tr -d ' ') .hx files into $OUT.staging"
