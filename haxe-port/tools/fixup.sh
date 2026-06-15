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
STRIP='^import (flash\.(text\.TextRun|display\.ActionScriptVersion)|com\.adobe\.net\.proxies\.RFC2817Socket|org\.flashdevelop\.utils\.TraceLevel);'
find "$DIR" -name '*.hx' -exec perl -i -ne "print unless /$STRIP/" {} +

echo "==> fixup: E4X access of Haxe-keyword-named attrs/nodes (x.att.default -> x.att.resolve(\"default\"))"
KW='default|var|function|in|cast|switch|class|override|public|private|static|if|else|for|while|return|true|false|null|new|untyped|inline|using|macro|extern|abstract|typedef|enum|interface|extends|implements|package|import|do|try|catch|throw|continue|break'
find "$DIR" -name '*.hx' -exec perl -i -pe "s/\\.(att|node|nodes|has|hasNode)\\.($KW)\\b/.\$1.resolve(\"\$2\")/g" {} +

echo "==> fixup: widen more AS3 internal/default fields accessed cross-class"
perl -i -pe 's/private var (name|type|valueString) : String;/public var $1 : String;/' "$DIR/Var.hx" 2>/dev/null || true

echo "==> fixup: AS3 new Array(...) -> Haxe array literal (Haxe Array ctor takes no args)"
# count-sized arrays (AS3 new Array(n)) -> empty (they are repopulated by push); must run before the general rule
perl -i -pe 's/new Array<[^>]*>\(numobjs\)/new Array<Dynamic>()/' "$DIR/GameObjects.hx" 2>/dev/null || true
perl -i -pe 's/new Array<[^>]*>\(newW \* newH\)/new Array<Dynamic>()/' "$DIR/EditorPackage/EditModeMap.hx" 2>/dev/null || true
# general: new Array<T>(a,b,...) / new Array<T>(x) -> [a,b,...] / [x] ; new Array<T>() -> []
find "$DIR" -name '*.hx' -exec perl -0777 -i -pe '1 while s/new Array<[^>]*>(\((?:[^()]++|(?1))*\))/"[" . substr($1,1,-1) . "]"/ge' {} +

echo "==> fixup: faithful E4X hand-ports as3hx mis-converted (child-chains, appendChild, attributes())"
# ExternalData.GetConstants: xml.constants.constant[.length()/[i]] -> node/nodes form
perl -i -pe '
  s/xml\.node\.constants\.innerData\.node\.constant\.innerData\.length\(\)/xml.node.constants.nodes.constant.length()/g;
  s/xml\.nodes\.constants\.node\.constant\.innerData\[i\]/xml.node.constants.nodes.constant.get(i)/g;
  s/xml\.node\.gameconstants\.innerData\.node\.constant\.innerData\.length\(\)/xml.node.gameconstants.nodes.constant.length()/g;
  s/xml\.nodes\.gameconstants\.node\.constant\.innerData\[i\]/xml.node.gameconstants.nodes.constant.get(i)/g;
  s/levelsXml\.node\.appendChild\.innerData\(xl\)/levelsXml.appendChild(xl.x)/g;
' "$DIR/ExternalData.hx" 2>/dev/null || true
# TextString.FromXML: x.attributes() loop -> iterate language labels against the Xml attributes directly
perl -0777 -i -pe 's/var attrs : FastXMLList = x\.node\.attributes\.innerData\(\);.*?dictionary\[label\] = s;\s*\}\s*\}\s*\}/for (label in TextStrings.languageLabels)\n        {\n            var lbl : String = Std.string(label);\n            if (x.x.exists(lbl))\n            {\n                var s : String = StringTools.replace(x.x.get(lbl), "\xc3\x9f", "ss");\n                dictionary[lbl] = s;\n            }\n        }/s' "$DIR/textPackage/TextString.hx" 2>/dev/null || true

echo "==> fixup: AS3 dynamic-MovieClip property access (OpenFL MovieClip is sealed; works at JS runtime)"
# Wrap accesses to game-attached custom props in 'untyped' so the typechecker allows them; the
# Dynamic then propagates down the chain. (?<![.\\w]) ensures we only wrap a real base variable,
# never a mid-chain field name. List grows as the compiler surfaces more dynamic props.
DPROPS='buttonAnimation|ButtonContinue|buttonName|ButtonRestart|canClick|clickCallback|helpText|hoverCallback|mainArea|reorderWhenOver|textTitle|useTick|tickState|buttonText|languageID|helpString|toggleIcon|screenA|screenB|debugArea|buttonVisible|buttonSelected|buttonLocked|_overCB|_outCB|_clickCB|editorLayer|displayText|achievement|adBox|awayTeam|btn_back|btn_continue|btn_feature1|btn_feature2|btn_feature3|btn_feature4|btn_head|btn_modify|btn_moregames|btn_musicMute|btn_next|btn_no|btn_pattern|btn_pick0|btn_pick1|btn_playgame|btn_PlayWithHighcores|btn_prequel|btn_sfxMute|btn_shirt|btn_shirtHoops|btn_shirtPlain|btn_shirtStripes|btn_shorts|btn_socks|btn_submit|btn_walkthrough|btn_yes|buttonBack|buttonFastForward|buttonLevelSelect|buttonPlayWithHighcores|ButtonQuit|buttonSkipCPMStarAd|canPress|coinBox|coinpercent|coins|coinsCollected|color|colorIndex|cup|gold|greystar|head|headIndex|highlight|highscore|homeTeam|hoops|info1|info2|info3|info4|inner|itemIndex|kit|levelComplete|levelID|levelName|levelNameText|levelNumber|levelrating|link_longAnimals|link_robotJam|loaderBar|logo_soccerballs|mainLogo|nextPage|numberText|palette|palette0|palette1|palette2|palette3|popup|prevPage|progressBar|scoreText1|scoreText2|screenIndex|selected|shirt|shorts|socks|stripes|teamIndex|textComputer|textDescription|textInfo|textLevelCreator|textLevelName|textName|textNumGold|textPlayer|textQuestion|textScore|textTeamName|textTeamName0|textTeamName1|textTick|tick|title|trophies|turboBtn|anglePointer|btn_clearSaveGame|btn_credits|btn_download|btn_facebook|btn_language|btn_localMusic|btn_y8|button1|button2|button3|button4|buttonCancel|buttonElipsis|buttonFalse|buttonMinus|buttonNext|buttonPlus|buttonPrevious|buttonTrue|close|closed_function|displayBox|editorItem|extract|helpClip|inputText|linkName|listData|listIndex|nameHolder|nameText|outCallback|overlay|prompt|row|SetParameters|textLives|text1|text2|text3|theText'
find "$DIR" -name '*.hx' -exec perl -i -pe "s/(?<![.\\w])([A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*)\\.($DPROPS)\\b/(untyped \$1).\$2/g" {} +

echo "==> fixup: widen ALL private -> public (AS3 internal/default became Haxe private; visibility is"
echo "        runtime-neutral, and AS3's package-visibility has no Haxe equivalent, so widen uniformly)"
find "$DIR" -name '*.hx' -exec perl -i -pe 's/\bprivate /public /g' {} +

echo "==> fixup: AS3 String.replace on .text chains -> StringTools.replace"
find "$DIR" -name '*.hx' -exec perl -i -pe 's/(\b\w+(?:\.\w+)*\.text)\.replace\(/StringTools.replace($1, /g' {} +

echo "==> fixup: untyped uninitialised vars (AS3 'var x;') -> ': Dynamic'"
find "$DIR" -name '*.hx' -exec perl -i -pe 's/^(\s*(?:public |private |static )*var [A-Za-z_]\w*) ;\s*$/$1 : Dynamic;\n/; s/^(\s*(?:public |private |static )*var [A-Za-z_]\w*);\s*$/$1 : Dynamic;\n/' {} +

echo "==> fixup: Levels.LoadLevel missing local 'level' decl; PhysicsBase flash.Boot no-op + nape debug type"
perl -i -pe 's/^(\s*)level = list\[l\];/$1var level : Level = list[l];/' "$DIR/Levels.hx" 2>/dev/null || true
perl -i -ne 'print unless /^\s*var a = new flash\.Boot\(\);/ or /^import flash\.Boot;/' "$DIR/PhysicsBase.hx" 2>/dev/null || true
perl -i -pe 's/: BitmapDebug;/: Dynamic;/; ' "$DIR/PhysicsBase.hx" 2>/dev/null || true
perl -i -ne 'print unless /^import nape\.util\.BitmapDebug;/' "$DIR/PhysicsBase.hx" 2>/dev/null || true

echo "==> fixup: AS3 dynamic method dispatch obj[\"fn\"]() -> Reflect; dynamic class instantiation"
perl -i -pe '
  s/\bgo\[graphic\.goInitFuntion\]\(\)/Reflect.callMethod(go, Reflect.field(go, graphic.goInitFuntion), [])/g;
  s/\bgo\[physobj\.initFunctionName\]\(\)/Reflect.callMethod(go, Reflect.field(go, physobj.initFunctionName), [])/g;
  s/\bthis\[physobj\.wakeFunctionName\]/Reflect.field(this, physobj.wakeFunctionName)/g;
' "$DIR/Game.hx" "$DIR/GameObjBase.hx" "$DIR/PhysicsBase.hx" 2>/dev/null || true
# new someVar.TheClass() -> Type.createInstance(someVar.TheClass, [])  (instantiate a stored Class ref)
find "$DIR" -name '*.hx' -exec perl -i -pe 's/new (\w+)\.TheClass\(\)/Type.createInstance($1.theClass, [])/g' {} +

echo "==> fixup: hoist AS3 function-scoped vars as3hx scoped to a block (jb0/jb1/go0.. used after their if-block)"
perl -0777 -i -pe '
  # strip the inner block-scoped decls to assignments FIRST (before inserting the hoisted decls,
  # so the generic go-strip below does not also strip the var off our inserted declarations)
  s/var (go0|go0a|go1|go1a) : GameObj = /$1 = /g;
  s/var jb0 : Body = PhysicsBase\.GetNapeSpace\(\)\.world;/jb0 = PhysicsBase.GetNapeSpace().world;/;
  s/var jb1 : Body = PhysicsBase\.GetNapeSpace\(\)\.world;/jb1 = PhysicsBase.GetNapeSpace().world;/;
  # then declare them all at function scope
  s/(function AddJoint_Nape\(joint : EdJoint\) : Array<Constraint>\s*\{)/$1\n        var jb0 : Body = null; var jb1 : Body = null;\n        var go0 : GameObj = null; var go0a : GameObj = null; var go1 : GameObj = null; var go1a : GameObj = null;/;
' "$DIR/PhysicsBase.hx" 2>/dev/null || true

echo "==> fixup: strip unused nape-internal import (api differs in nape-haxe4; only the public method is used)"
find "$DIR" -name '*.hx' -exec perl -i -ne 'print unless /^import zpp_nape\.dynamics\.ZPPSensorArbiter;/' {} +

echo "==> fixup: remaining E4X child-chains, button default param, font-size Int, dead s3d.SetVisible"
# Levels: x.joints.joint child-chain -> node/nodes form (same as3hx mis-conversion as ExternalData)
perl -i -pe '
  s/x\.node\.joints\.innerData\.node\.joint\.innerData\.length\(\)/x.node.joints.nodes.joint.length()/g;
  s/x\.nodes\.joints\.node\.joint\.innerData\[i\]/x.node.joints.nodes.joint.get(i)/g;
' "$DIR/Levels.hx" 2>/dev/null || true
# UI button fns: trailing untyped '_hoverCallback)' lost its '= null' default (as3hx) -> restore.
# Only on declaration lines (contain 'function'); call sites pass _hoverCallback as a bare arg.
find "$DIR" -name '*.hx' -exec perl -i -pe 's/, _hoverCallback\)/, _hoverCallback : Dynamic = null)/g if /\bfunction\b/' {} +
# OpenFL TextFormat.size is Null<Int> (AS3 Number); truncate on assign (AS3-faithful)
perl -i -pe 's/tFormat\.size = size;/tFormat.size = Std.int(size);/' "$DIR/textPackage/TextStrings.hx" 2>/dev/null || true
# s3d.InitOnce(cb) is the BOOT TRIGGER, not dead code: its callback chains into InitGame()/StartTitleScreen().
# Rewrite it to call the callback directly (GPU init is dead with useStage3D=false, so run synchronously).
# Must rewrite rather than keep the s3d.* call: lowercase `s3d` resolves as a package path, not the stub type.
find "$DIR" -name '*.hx' -exec perl -i -pe 's/\bs3d\.InitOnce\(\s*(\w+)\s*\)/$1()/g' {} +
# s3d.SetVisible: Stage3D layer toggle, genuinely dead with useStage3D=false -> drop the line.
find "$DIR" -name '*.hx' -exec perl -i -ne 'print unless /^\s*s3d\.SetVisible\(/' {} +

echo "==> fixup: AS3 Number->int coercions where Haxe wants Int (Std.int = AS3 ToInt32 truncation, faithful)"
perl -i -pe '
  s/\.play\(0, 9999999999, st\)/.play(0, Std.int(9999999999), st)/;
  s/BLOCK_SIZE : read \/ _rate;/BLOCK_SIZE : Std.int(read \/ _rate);/;
' "$DIR/audioPackage/Audio.hx" "$DIR/audioPackage/PitchControl.hx" 2>/dev/null || true
perl -i -pe '
  s/^(\s*)x0 = rect\.left;/$1x0 = Std.int(rect.left);/;
  s/^(\s*)y0 = rect\.top;/$1y0 = Std.int(rect.top);/;
  s/new BitmapData\(\(rect\.width\), \(rect\.height\), true, 0\)/new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0)/;
  s/new BitmapData\(\(rect\.width \* scl\), \(rect\.height \* scl\), true, 0\)/new BitmapData(Std.int(rect.width * scl), Std.int(rect.height * scl), true, 0)/;
' "$DIR/DisplayObj.hx" 2>/dev/null || true
perl -i -pe 's/Utils\.RandSetSeed\(123456789101112\)/Utils.RandSetSeed(Std.int(123456789101112))/; s/g\.beginBitmapFill\(dobj\.GetBitmapData\(frame\)/g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame))/; s/var xx : Int = p\.x;/var xx : Int = Std.int(p.x);/; s/var yy : Int = p\.y;/var yy : Int = Std.int(p.y);/' "$DIR/GameObjBase.hx" 2>/dev/null || true
perl -i -pe 's/Levels\.GetLevel\(levelID - 1\)/Levels.GetLevel(Std.int(levelID - 1))/' "$DIR/Game.hx" 2>/dev/null || true
perl -i -pe 's/ballTimerMax : Int = Defs\.fps \* 6;/ballTimerMax : Int = Std.int(Defs.fps * 6);/' "$DIR/GameVars.hx" 2>/dev/null || true
# editor: cursor coords (Float) into Int params/locals -> Std.int (editor is dev-only; truncation matches AS3)
perl -i -pe 's/^(\s*)(mx|my) = e\.(stageX|stageY);/$1$2 = Std.int(e.$3);/; s/var (mx|my) : Int = MouseControl\.(x|y);/var $1 : Int = Std.int(MouseControl.$2);/; s/AddInfoText\((.*?), x, y,/AddInfoText($1, Std.int(x), Std.int(y),/g; s/currentModeObject\.RenderHud\(x, y\)/currentModeObject.RenderHud(Std.int(x), Std.int(y))/; s/y \+= AddInfoText\("a", x, y, s\)/y += AddInfoText("a", Std.int(x), Std.int(y), s)/' "$DIR/editorPackage/EditModeBase.hx" "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true

echo "==> fixup: AS3 String.match (regex) -> EReg; iterate over PhysObjBody.shapes; field-init this-access"
perl -i -pe 's/l\.name\.match\("Boss"\)/new EReg("Boss", "").match(l.name)/' "$DIR/Game.hx" 2>/dev/null || true
perl -i -pe 's/ in body\.shapes\)/ in (body.shapes : Array<Dynamic>))/' "$DIR/PhysicsBase.hx" 2>/dev/null || true
# EditModeLibrary: field initializer cannot reference sibling field boxNumW/H -> inline their constant values
perl -i -pe 's#Defs\.displayarea_w / boxNumW;#Defs.displayarea_w / 5;#; s#Defs\.displayarea_h / boxNumH;#Defs.displayarea_h / 4;#' "$DIR/editorPackage/EditModeLibrary.hx" 2>/dev/null || true

echo "==> fixup: restore var declarations as3hx dropped (AS3 function-scoping / first-assignment) + dead Stage3D residue"
perl -i -pe 's/^(\s*)go = HitTestPhysObjGraphics\(mx, my\);/$1var go : GameObj = HitTestPhysObjGraphics(mx, my);/' "$DIR/Game.hx" 2>/dev/null || true
perl -i -pe 's/^(\s*)gl = layers\[i\];/$1var gl : GameLayer = layers[i];/' "$DIR/editorPackage/GameLayers.hx" 2>/dev/null || true
perl -i -pe 's/^(\s*)numPerLine = 600;/$1var numPerLine : Int = 600;/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
perl -i -pe 's/^(\s*)tfIndex = 0;/$1var tfIndex : Int = 0;/' "$DIR/TexturePages.hx" 2>/dev/null || true
# dead Stage3D (useStage3D=false): s3d.context3D is unreachable; lowercase s3d won't resolve -> typed null
perl -i -pe 's/s3d\.context3D/(null : openfl.display3D.Context3D)/g' "$DIR/TexturePage.hx" "$DIR/TexturePages.hx" 2>/dev/null || true
# dead Stage3D upload after the (real, blitting) loop, referencing the now-out-of-scope loop var
find "$DIR" -name '*.hx' -exec perl -i -ne 'print unless /^\s*dof\.s3dTexture\.uploadFromBitmapData\(bd\);/' {} +
# PhysObj joints loop reuses the (AS3 function-scoped) typename -> give it a local declaration
perl -i -pe 's/^(\s*)typename = jx\.att\.type;/$1var typename : String = jx.att.type;/' "$DIR/PhysObj.hx" 2>/dev/null || true
# Grass.PreRenderLines: AS3 hoists x1; it is read in boundingRect one line before its 'var x1' (so =0 on the
# first pass, carrying the previous segment's value after) -> hoist to fn scope =0, keep it faithful
perl -i -pe 's/^(\s*)(var x0 : Int = as3hx\.Compat\.parseInt\(minX\);)/$1var x1 : Int = 0;\n$1$2/; s/^(\s*)var x1 : Int = x0 \+ segWidth;/$1x1 = x0 + segWidth;/' "$DIR/Grass.hx" 2>/dev/null || true

echo "==> fixup: AS3 Array.sortOn / String.concat / Mouse cursor / iterate-on-Dynamic"
# Array.sortOn("field", NUMERIC|DESCENDING) -> faithful numeric-descending z-order sort
find "$DIR" -name '*.hx' -exec perl -i -pe 's/(\w+)\.sortOn\("(\w+)", Array\.NUMERIC \| Array\.DESCENDING\)/Sort.numericDesc($1, "$2")/g' {} +
# AS3 String.concat(x) -> Haxe string '+'
find "$DIR" -name '*.hx' -exec perl -i -pe 's/(\w+|"[^"]*")\.concat(\((?:[^()]++|(?2))*\))/"(" . $1 . " + " . substr($2,1,-1) . ")"/ge' {} +
# custom hardware cursor (cosmetic) — drop the registerCursor calls; MouseCursorData stays a stub
find "$DIR" -name '*.hx' -exec perl -i -ne 'print unless /^\s*Mouse\.registerCursor\(/' {} +
# iterate over Dynamic-typed array fields -> annotate the collection type
perl -i -pe 's/ in line\.points\)/ in (line.points : Array<Dynamic>))/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
perl -i -pe 's/ in o\.TrophiesCollected\)/ in (o.TrophiesCollected : Array<Dynamic>))/; s/ in o\.coinsTable\)/ in (o.coinsTable : Array<Dynamic>))/' "$DIR/GameVars.hx" 2>/dev/null || true
perl -i -pe 's/ in o\.completes\)/ in (o.completes : Array<Dynamic>))/' "$DIR/achievementPackage/Achievements.hx" 2>/dev/null || true
perl -i -pe 's/ in go1\.switchContactList\)/ in (go1.switchContactList : Array<Dynamic>))/' "$DIR/Collision.hx" 2>/dev/null || true

echo "==> fixup: remaining individual as3hx artefacts (E4X grandchild chains, while(1), loop-break, etc.)"
# E4X grandchild chains a.X.Y -> node/nodes (general; same mis-conversion seen in ExternalData/Levels)
find "$DIR" -name '*.hx' -exec perl -i -pe '
  s/\.node\.(\w+)\.innerData\.node\.(\w+)\.innerData\.length\(\)/.node.$1.nodes.$2.length()/g;
  s/\.nodes\.(\w+)\.node\.(\w+)\.innerData\[i\]/.node.$1.nodes.$2.get(i)/g;
  # Untyped-wrapped E4X-accessor botch: when an XML node/attribute name (gold, achievement, color,
  # title, coins, head, selected, ...) also appears in the DPROPS dynamic-MovieClip-property list, the
  # DPROPS untyped-wrap fires and produces e.g. (untyped x.nodes).achievement or
  # (untyped x.node.soccerballs.att).gold. The `untyped` makes `.name` a raw field read on the Xml
  # value instead of invoking FastXML.NodeAccess/NodeListAccess/AttribAccess @:op(a.b), so it returns
  # undefined. Unwrap whenever the wrapped base ends in an E4X accessor (.node/.nodes/.att).
  s/\(untyped ([\w.]+?)\.innerData\.att\)\.(\w+)/$1.att.$2/g;
  s/\(untyped ([\w.]+\.(?:node|nodes|att))\)\.(\w+)/$1.$2/g;
  s/\.node\.(\w+)\.innerData\.att\./.node.$1.att./g;
' {} +
# AS3 while(1) -> while(true). The ((1)); form is a do-while terminator (keep ;, no braces).
find "$DIR" -name '*.hx' -exec perl -i -pe 's/\bwhile \(\(1\)\);/while (true);/g; s/\bwhile \(1\)\b/while (true)/g' {} +
# AS3 'i = 99999' loop-exit on an immutable Haxe for-loop var -> break
perl -i -pe 's/^(\s*)i = 99999;/$1break;/' "$DIR/Game.hx" 2>/dev/null || true
# as3hx doubled comparison 'x != null = null' -> 'x != null'
perl -i -pe 's/if \(bitmapData != null = null\)/if (bitmapData != null)/' "$DIR/DisplayObjFrame.hx" 2>/dev/null || true
# DisplayObjFrame: original reads a non-existent "point" attribute (data uses pointX/pointY, all 0) -> point stays (0,0)
perl -i -pe 's/point\.x = x\.att\.point\.x;/point.x = 0;/; s/point\.y = x\.att\.point\.y;/point.y = 0;/' "$DIR/DisplayObjFrame.hx" 2>/dev/null || true
# Main.NewInit4: the original SWF set LicDef.stg from the Preloader (its [Frame(factoryClass=...)]
# document factory). OpenFL runs Main directly and ignores that, so LicDef.stg stays null and the
# UI's pervasive LicDef.GetStage().stage access crashes. Wire the on-stage root here (theRoot=this).
perl -i -pe 's/^(\s*)theRoot = this;/$1theRoot = this;\n$1licPackage.LicDef.stg = this;/' "$DIR/Main.hx" 2>/dev/null || true

# --- Dictionary array-access consistency ------------------------------------------------------
# flash.utils.Dictionary resolves to openfl.utils.Dictionary (Map-backed). as3hx converted some
# `dict[key]` to array access and others to Reflect.field/setField; on a Map these don't interoperate,
# so a dict written via array access and read via Reflect.field (or vice-versa) silently misses every
# entry (lost localised text; "Graphic Objects - can't find obj"; null game-layer z-order). Normalise
# the mixed-access dicts to array access (the intended Dictionary API).
perl -i -pe 's/Reflect\.field\(dict, ([^,()]+)\)/dict[$1]/g; s/Reflect\.setField\(dict, ([^,()]+), ([^()]+?)\);/dict[$1] = $2;/g;' "$DIR/GraphicObjects.hx" 2>/dev/null || true
perl -i -pe 's/Reflect\.field\(dict, str\)/dict[str.toLowerCase()]/g;' "$DIR/textPackage/TextStrings.hx" 2>/dev/null || true
perl -i -pe 's/Reflect\.field\(nameDictionary, ([^,()]+)\)/nameDictionary[$1]/g;' "$DIR/editorPackage/GameLayers.hx" 2>/dev/null || true
# TextString: English text is in the `name` attr (en="" in data); make the fallback array-access +
# null-safe, and guarantee GetLocalisedText() never returns null (else TextField.text=null -> #2007).
perl -0777 -i -pe 's/if \(Reflect\.field\(dictionary, "en"\) == ""\)\s*\{\s*Reflect\.setField\(dictionary, "en", name\);\s*\}/if (dictionary["en"] == "" || dictionary["en"] == null)\n        {\n            dictionary["en"] = name;\n        }/s' "$DIR/textPackage/TextString.hx" 2>/dev/null || true
perl -0777 -i -pe 's/return dictionary\[TextStrings\.languageLabels\[TextStrings\.currentLanguage\]\];/var s : String = dictionary[TextStrings.languageLabels[TextStrings.currentLanguage]];\n        if (s == null) s = dictionary["en"];\n        if (s == null) s = name;\n        return s;/s' "$DIR/textPackage/TextString.hx" 2>/dev/null || true
# GraphicObjects/GameObjects symbol lookup: original `Type.getClass(Type.resolveClass(name))` always
# returns null (getClass wants an instance). Resolve the class directly, and fall back to the
# first-letter-capitalised name openfl-swf gives generated symbol classes (woodenCrate1 -> WoodenCrate1).
perl -0777 -i -pe 's/classRef = Type\.getClass\(Type\.resolveClass\(mcName\)\);/classRef = Type.resolveClass(mcName);\n            if (classRef == null \&\& mcName.length > 0) classRef = Type.resolveClass(mcName.charAt(0).toUpperCase() + mcName.substr(1));/g' "$DIR/GraphicObjects.hx" 2>/dev/null || true
# UpdateGeneric: AS3 implicit int->String text coercion lost under untyped (#2007 on null).
perl -i -pe 's/\.textScore\.text = Game\.currentScore;/.textScore.text = Std.string(Game.currentScore);/' "$DIR/uIPackage/UI.hx" 2>/dev/null || true
# AS3 String.search(literal) -> indexOf
perl -i -pe 's/type\.search\("pickup_trophy_"\)/type.indexOf("pickup_trophy_")/' "$DIR/Levels.hx" 2>/dev/null || true
# LoadLevel: AS3 hoists a later bare `var level:Level;` to the top, so it is the SAME var already
# assigned `list[l]` and does not reset. as3hx re-declared it + null-init fixup added `= null`,
# clobbering the loaded level (-> null.Calculate()). Drop the shadowing re-declaration.
perl -0777 -i -pe 's/\n\s*var level : Level = null;[ \t]*\n(\s*\n)?(\s*level\.Calculate\(\);)/\n\n$2/s' "$DIR/Levels.hx" 2>/dev/null || true
# EdConsole: as3hx double-indexed the splice; splice at the already-computed index
perl -i -pe 's/activeList\.splice\(Lambda\.indexOf\(activeList, index\), 1\)/activeList.splice(index, 1)/' "$DIR/editorPackage/EdConsole.hx" 2>/dev/null || true
# LicDef: AS3 truthiness coercions of a URL param / Number
perl -i -pe 's/kongregateEmbedFlag = stg\.stage\.loaderInfo\.parameters\.kongregate;/kongregateEmbedFlag = stg.stage.loaderInfo.parameters.kongregate != null;/' "$DIR/licPackage/LicDef.hx" 2>/dev/null || true
# TexturePages: AS3 Array.sort returns the array & comparator may return Number; Haxe sort is void / needs Int
perl -i -pe 's/function SortArea\(x : DisplayObjFrame, y : DisplayObjFrame\) : Float/function SortArea(x : DisplayObjFrame, y : DisplayObjFrame) : Int/; s/dobjFrames = dobjFrames\.sort\(SortArea\);/dobjFrames.sort(SortArea);/' "$DIR/TexturePages.hx" 2>/dev/null || true
# AS3 Array.push(a,b,c,...) (rest args) -> Haxe single-arg: append via concat
find "$DIR" -name '*.hx' -exec perl -0777 -i -pe '1 while s/(\w+)\.push\(((?:[^()]++|(\([^()]*\)))*,(?:[^()]++|(\([^()]*\)))*)\)/$1 = $1.concat([$2])/g' {} +

echo "==> fixup: more individual as3hx artefacts (inherited static const, array concat, fn-ref, etc.)"
# AS3 lets a subclass name a base static const unqualified; Haxe needs the qualifier (all HIGHLIGHT_*)
find "$DIR" -name '*.hx' -exec perl -i -pe 's/(?<![.\w])(HIGHLIGHT_\w+)\b/EditableObjectBase.$1/g unless /var HIGHLIGHT_/' {} +
# iterate over Dynamic-typed PhysObjBody array fields
find "$DIR" -name '*.hx' -exec perl -i -pe 's/ in body\.(shapes|graphics)\)/ in (body.$1 : Array<Dynamic>))/g' {} +
# AS3 obj[strKey] dynamic child/dispatch -> Reflect (property reads, and calls with/without args)
find "$DIR" -name '*.hx' -exec perl -i -pe '
  s/\bmc\[(o|ro)\.button\]/Reflect.field(mc, $1.button)/g;
  s/\btestFunctions\[ach\.completeFunction\]\(\)/Reflect.callMethod(testFunctions, Reflect.field(testFunctions, ach.completeFunction), [])/g;
  s/\brenderer\[po\.editorRenderFunctionName\]\(po, this\)/Reflect.callMethod(renderer, Reflect.field(renderer, po.editorRenderFunctionName), [po, this])/g;
' {} +
# AS3 array '+' -> concat
perl -i -pe 's/\ba = \(a \+ a2\);/a = a.concat(a2);/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
# stored Function callback into addEventListener -> cast to the listener type
find "$DIR" -name '*.hx' -exec perl -i -pe 's/addEventListener\((MouseEvent\.\w+), clickCallback\b/addEventListener($1, cast clickCallback/g' {} +
# AS3 casts Type(x) for fl stubs / Object -> Haxe cast
find "$DIR" -name '*.hx' -exec perl -i -pe 's/\bList\(event\.target\)/cast(event.target, List)/g; s/\bComboBox\(event\.target\)/cast(event.target, ComboBox)/g; s/\bDynamic\(([^()]*)\)/($1 : Dynamic)/g' {} +
# function return types as3hx mis-inferred
perl -i -pe 's/function CreateSeparates\((.*)xflip : Bool = false\)/function CreateSeparates($1xflip : Bool = false) : Array<Dynamic>/' "$DIR/AnimHierarchy.hx" 2>/dev/null || true
perl -i -pe 's/function UpdatePhysObj_Path_New\(\)/function UpdatePhysObj_Path_New() : Void/; s/^(\s*)return new Point\(0, 0\);/$1return;/' "$DIR/GameObjBase.hx" 2>/dev/null || true
# switch-hit handlers: AS3 bare 'return;' in a Bool-returning fn -> 'return false;' (undefined coerces false).
# Line-by-line state (a function flag) — avoids resetting capture vars with an inner s/// in an /e replacement.
perl -i -pe 'if(/function InitGameObjLine_Switch_Hit\(/){$in=1} elsif($in && /^\s*(?:public |private )?function /){$in=0} s/\breturn;/return false;/ if $in;' "$DIR/GameObj.hx" 2>/dev/null || true
perl -i -pe 'if(/function Switch\w*Hit\w*\(goHitter : GameObj\)/){$in=1} elsif($in && /^\s*(?:public |private )?function /){$in=0} s/\breturn;/return false;/ if $in;' "$DIR/GameObjBase.hx" 2>/dev/null || true
# hoist AS3 function-scoped vars used after their block
perl -i -pe 's/^(\s*)xp = parentObj\.xpos/$1var xp : Float = parentObj.xpos/; s/^(\s*)yp = parentObj\.ypos/$1var yp : Float = parentObj.ypos/' "$DIR/GameObj.hx" 2>/dev/null || true
perl -i -pe 's/^(\s*)i = 0;\n(\s*while \(i <= 2\))/$1var i : Int = 0;\n$2/' "$DIR/editorPackage/EdLine.hx" 2>/dev/null || true
perl -0777 -i -pe 's/(var unique : Bool = false;\s*\n\s*do\s*\{)/var s : String = "";\n        $1/; s/(do\s*\{\s*\n\s*)var s : String = "uid_";/$1s = "uid_";/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
# RenderAt: dobj declared in the graphics loop but read after -> hoist to fn scope
perl -0777 -i -pe 's/(function RenderAt\(physObj : PhysObj[^\n]*\)\s*\{)/$1\n        var dobj : DisplayObj = null;/; s/var dobj : DisplayObj = GraphicObjects\.GetDisplayObjByName/dobj = GraphicObjects.GetDisplayObjByName/' "$DIR/PhysObj.hx" 2>/dev/null || true
# TrophiesCollected multi-arg push (10 falses, spans lines) -> push each
perl -0777 -i -pe 's/TrophiesCollected\.push\(\s*(?:false,?\s*)+\)/for (_v in [false,false,false,false,false,false,false,false,false,false]) TrophiesCollected.push(_v)/s' "$DIR/GameVars.hx" 2>/dev/null || true
# AS3 'array + array' (as3hx artefact) -> concat
perl -i -pe 's/var a : Array<Dynamic> = \(a0 \+ a1\);/var a : Array<Dynamic> = a0.concat(a1);/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
# openfl TextField.opaqueBackground is a colour (Null<Int>), not Bool
find "$DIR" -name '*.hx' -exec perl -i -pe 's/\.opaqueBackground = true;/.opaqueBackground = 0xFFFFFF;/g' {} +
# as3hx dropped 'var' on these cast-assignments (poi/line used right after)
perl -i -pe 's/^(\s*)poi = try cast\(base, EdObj\)/$1var poi : EdObj = try cast(base, EdObj)/; s/^(\s*)line = try cast\(base, EdLine\)/$1var line : EdLine = try cast(base, EdLine)/' "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true
# RemoveObject takes a function reference; as3hx called it instead
find "$DIR" -name '*.hx' -exec perl -i -pe 's/RemoveObject\(RemovePhysObj\(\)\)/RemoveObject(RemovePhysObj)/g' {} +
# openfl SoundChannel isn't directly constructible; init to null (set later from sound.play())
find "$DIR" -name '*.hx' -exec perl -i -pe 's/= new SoundChannel\(\);/= null;/g' {} +

echo "==> fixup: decouple out-of-scope editor MODE subclasses from gameplay-reachable PhysEditor"
# Each EditMode* subclass carries many as3hx artefacts and is dev-only. PhysEditor only ever calls
# EditModeBase methods on currentModeObject, and edit modes never run in play mode, so type the mode
# fields/instantiations as the (clean) base -> the subclasses become unreachable and stop being compiled.
MODES='EditModeLibrary|EditModePlacement|EditModeAdjust|EditModeLines|EditModeMap|EditModeJoints|EditModeObjCol|EditModePickPieceForLink|EditModePickLineForLink|EditModeMulti'
# fields are Dynamic (gameplay accesses subclass-specific fields on them); instantiate the clean base
perl -i -pe "s/: ($MODES);/: Dynamic;/g; s/new ($MODES)\(\)/new EditModeBase()/g" "$DIR/editorPackage/PhysEditor.hx" 2>/dev/null || true

echo "==> fixup: last individual cases (more iterate casts, bare returns in typed fns, EdLine i)"
find "$DIR" -name '*.hx' -exec perl -i -pe 's/ in shape\.poly_points\)/ in (shape.poly_points : Array<Dynamic>))/g; s/ in editModeObj_Library\.libraryFilters\)/ in (editModeObj_Library.libraryFilters : Array<Dynamic>))/g' {} +
# bare 'return;' in a non-Void-typed fn -> return the typed empty/null value
perl -i -pe 'if(/function CreateSeparates\(/){$in=1} elsif($in && /^\s*(?:public |private )?function /){$in=0} s/\breturn;/return goList;/ if $in;' "$DIR/AnimHierarchy.hx" 2>/dev/null || true
perl -i -pe 'if(/function UpdateLine\(/){$in=1} elsif($in && /^\s*(?:public |private )?function /){$in=0} s/\breturn;/return null;/ if $in;' "$DIR/GameObjBase.hx" 2>/dev/null || true
# EdLine: dropped 'var' on a loop counter
perl -i -pe 's/^(\s*)i = 0;\s*$/$1var i : Int = 0;\n/' "$DIR/editorPackage/EdLine.hx" 2>/dev/null || true
# SwitchWeightHitPersist does side effects then falls through; now Bool-typed -> add the AS3 undefined(=false) return
perl -0777 -i -pe 's/(timer = 4;\n)(\s*\}\n\s*public function SwitchWeightHit\b)/$1        return false;\n$2/' "$DIR/GameObjBase.hx" 2>/dev/null || true

# Haxe requires definite assignment; AS3 object locals default to null. Initialise uninitialised
# object-typed (uppercase / generic) local declarations to null. Value types (Int/Float/Bool/UInt)
# are excluded (they cannot be null without Null<>); those were already handled as conversions.
find "$DIR" -name '*.hx' -exec perl -i -pe 's/^(\s*var \w+ : )(?!(?:Int|Float|Bool|UInt);)([\w.]+(?:<[^>\n]*>)?);\s*$/$1$2 = null;/' {} +
# value-type locals -> AS3 defaults (Number=NaN, int/uint=0, Boolean=false)
find "$DIR" -name '*.hx' -exec perl -i -pe 's/^(\s*var \w+ : Float);\s*$/$1 = Math.NaN;/; s/^(\s*var \w+ : (?:Int|UInt));\s*$/$1 = 0;/; s/^(\s*var \w+ : Bool);\s*$/$1 = false;/' {} +

echo "==> fixup: point embedded-asset class fields at the real data (release SWF embedded these via [Embed])"
perl -i -pe 's/(static var class_Data : Class<Dynamic>);/$1 = EmbedObjectsData;/; s/(static var class_Levels : Class<Dynamic>);/$1 = EmbedLevelsData;/; s/(static var class_Levels1 : Class<Dynamic>);/$1 = EmbedLevelsJulian;/; s/(static var class_Levels2 : Class<Dynamic>);/$1 = EmbedLevelsRob;/; s/(static var class_Levels3 : Class<Dynamic>);/$1 = EmbedLevelsTestbed;/' "$DIR/ExternalData.hx" 2>/dev/null || true
perl -i -pe 's/(static var class_vars : Class<Dynamic>);/$1 = EmbedGraphicObjects;/' "$DIR/GraphicObjects.hx" 2>/dev/null || true
perl -i -pe 's/(static var class_embedded_XML : Class<Dynamic>);/$1 = EmbedTextStrings;/' "$DIR/textPackage/TextStrings.hx" 2>/dev/null || true
perl -i -pe 's/(static var class_embedded_XML : Class<Dynamic>);/$1 = EmbedAchievements;/' "$DIR/achievementPackage/Achievements.hx" 2>/dev/null || true

echo "==> fixup done in $DIR"
