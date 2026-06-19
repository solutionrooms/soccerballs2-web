import flash.text.TextField;
import flash.text.TextFieldAutoSize;

// Bounce / kick capture-and-replay debugger.
//
// Purpose: a "lost bounce" that depends on exactly where the ball lands is impossible to fix from a
// verbal description but trivial once it can be replayed deterministically. This records the last
// kick (ball position + launch velocity) and every ball impact (incoming vs outgoing velocity +
// landing spot), shows them in an on-screen overlay, and logs a copy-pasteable `sb2ReplayKick(...)`
// repro string. Toggle with the 'B' key (or add ?bounce to the URL). Coordinates are physics/world
// pixels; +y is DOWN, so a descending ball has vy>0 and a real bounce flips vy negative (upward).
class BounceDebug
{
    public static var on : Bool = false;

    // last kick
    public static var hasKick : Bool = false;
    public static var kickX : Float = 0;
    public static var kickY : Float = 0;
    public static var kickVX : Float = 0;
    public static var kickVY : Float = 0;

    // last impact
    public static var hasLand : Bool = false;
    public static var landN : Int = 0;
    public static var landX : Float = 0;
    public static var landY : Float = 0;
    public static var vxIn : Float = 0;
    public static var vyIn : Float = 0;
    public static var vxOut : Float = 0;
    public static var vyOut : Float = 0;
    public static var bounced : Bool = false;

    static var prevVx : Float = 0;
    static var prevVy : Float = 0;
    static var hadBall : Bool = false;
    static var tf : TextField = null;

    // rolling capture of the current shot, dumped by sb2BouncePath(): full trajectory + each impact
    // with the terrain it hit, so a bad bounce can be reconstructed as a minimal replica test.
    static var recFrames : Int = 0;
    static var recPath : Array<Float> = [];   // flat [x,y,vy, x,y,vy, ...]
    static var recImpacts : Array<String> = [];

    public static function RecordKick(x : Float, y : Float, vx : Float, vy : Float) : Void
    {
        kickX = x; kickY = y; kickVX = vx; kickVY = vy; hasKick = true;
        // reset impact tracking for the new shot
        prevVx = vx; prevVy = vy; hadBall = true;
        hasLand = false;
        recFrames = 300; recPath = []; recImpacts = []; // record ~5s of the shot for sb2BouncePath()
        if (on) Log("KICK @(" + R(x) + "," + R(y) + ") v=(" + R(vx) + "," + R(vy) + ")  ->  " + ReproStr());
        UpdateOverlay();
    }

    // Called once per physics step (after the step + write-back). Detects ball impacts by watching the
    // body velocity: a fast descent whose downward speed suddenly collapses/reverses is an impact.
    public static function Tick() : Void
    {
        var go : Dynamic = GameVars.footballGO;
        if (go == null) { hadBall = false; UpdateOverlay(); return; }
        var nb : Array<Dynamic> = go.nape_bodies;
        if (nb == null || nb.length == 0 || nb[0] == null) { hadBall = false; UpdateOverlay(); return; }
        var b : nape.phys.Body = nb[0];
        var vx : Float = b.velocity.x;
        var vy : Float = b.velocity.y;
        if (recFrames > 0)
        {
            recPath.push(b.position.x); recPath.push(b.position.y); recPath.push(vy);
            recFrames--;
        }
        if (hadBall)
        {
            if (prevVy > 80 && vy < prevVy * 0.5) // was descending fast, downward speed just collapsed
            {
                hasLand = true; landN++;
                landX = b.position.x; landY = b.position.y;
                vxIn = prevVx; vyIn = prevVy; vxOut = vx; vyOut = vy;
                bounced = (vy < -20); // now moving upward = a real bounce
                if (recImpacts.length < 12)
                    recImpacts.push("@(" + R(landX) + "," + R(landY) + ") vy " + R(vyIn) + "->" + R(vyOut)
                        + (bounced ? " BOUNCED" : " NO-BOUNCE") + "  " + TerrainNear(landX, landY));
                if (on) Log("LAND #" + landN + " @(" + R(landX) + "," + R(landY) + ") vy " + R(vyIn) + "->" + R(vyOut)
                    + (bounced ? "  BOUNCED" : "  *** NO BOUNCE ***") + "  | " + ReproStr());
            }
        }
        prevVx = vx; prevVy = vy; hadBall = true;
        UpdateOverlay();
    }

    // Terrain triangles (world verts + elasticity) near a point — captured at each impact.
    static function TerrainNear(px : Float, py : Float) : String
    {
        var out = "tris:";
        var space = PhysicsBase.GetNapeSpace();
        var n = 0;
        for (sb in space.bodies)
        {
            if (!sb.isStatic()) continue;
            for (sh in sb.shapes)
            {
                if (!sh.isPolygon()) continue;
                var p : nape.shape.Polygon = cast sh;
                var lv = p.worldVerts;
                var near = false;
                for (i in 0...lv.length) { var v = lv.at(i); if (Math.abs(v.x - px) < 32 && Math.abs(v.y - py) < 32) { near = true; break; } }
                if (near)
                {
                    out += " [e=" + sh.material.elasticity;
                    for (i in 0...lv.length) out += "(" + R(lv.at(i).x) + "," + R(lv.at(i).y) + ")";
                    out += "]"; n++;
                    if (n >= 5) return out;
                }
            }
        }
        return out;
    }

    public static function PathStr() : String
    {
        var out = "KICK " + ReproStr() + "\nimpacts(" + recImpacts.length + "):";
        for (s in recImpacts) out += "\n  " + s;
        out += "\npath(" + Std.int(recPath.length / 3) + " pts x,y,vy):";
        var i = 0;
        while (i < recPath.length) { out += " (" + R(recPath[i]) + "," + R(recPath[i + 1]) + "," + R(recPath[i + 2]) + ")"; i += 3; }
        return out;
    }

    public static function ReproStr() : String
    {
        return "sb2ReplayKick(" + R(kickX) + "," + R(kickY) + "," + R(kickVX) + "," + R(kickVY) + ")";
    }

    public static function Toggle() : Void
    {
        on = !on;
        EnsureTF();
        if (tf != null) tf.visible = on;
        UpdateOverlay();
    }

    public static function SetOn(v : Bool) : Void
    {
        on = v;
        EnsureTF();
        if (tf != null) tf.visible = on;
        UpdateOverlay();
    }

    static var copiedFrames : Int = 0;
    static var lastPick : String = "";
    static var pickWired : Bool = false;

    // Shift+click anywhere on the game (while bounce debug is on) → report the clicked world point +
    // the terrain there, WITHOUT kicking. Avoids needing exact coords for sb2TerrainAt.
    static function WirePicker() : Void
    {
        if (pickWired || Main.theStage == null) return;
        pickWired = true;
        try {
            // high priority + stopImmediatePropagation so we pre-empt the game's stage kick handler
            Main.theStage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(e : flash.events.MouseEvent) : Void {
                if (on && e.shiftKey) { e.stopImmediatePropagation(); Pick(e.stageX, e.stageY); }
            }, false, 100);
            Main.theStage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function(e : flash.events.MouseEvent) : Void {
                if (on && e.shiftKey) e.stopImmediatePropagation();
            }, false, 100);
        } catch (e : Dynamic) {}
    }

    static function Pick(sx : Float, sy : Float) : Void
    {
        var wx = sx + Game.camera.x; // screen -> world (the renderer draws world at screen = world - camera)
        var wy = sy + Game.camera.y;
        lastPick = "PICK world(" + R(wx) + "," + R(wy) + ")";
        Log(lastPick + " " + TerrainNear(wx, wy));
        UpdateOverlay();
    }

    static function EnsureTF() : Void
    {
        if (tf != null || Main.theStage == null) return;
        try
        {
            tf = new TextField();
            tf.selectable = false;       // canvas text-selection is unreliable; we copy on click instead
            tf.mouseEnabled = true;      // clickable, so the box can copy the repro to the clipboard
            tf.autoSize = TextFieldAutoSize.LEFT;
            tf.background = true;
            tf.backgroundColor = 0x000000;
            tf.textColor = 0x33ff88;
            tf.x = 4;
            tf.y = 392;
            tf.visible = on;
            // Consume mouse events on the box so clicking it copies WITHOUT also kicking the ball: the
            // game's kick is a stage MOUSE_DOWN/UP handler, and stopImmediatePropagation stops the event
            // bubbling up to it. Copy on MOUSE_DOWN (fires before the game would react).
            tf.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(e : flash.events.MouseEvent) : Void { e.stopImmediatePropagation(); CopyToClipboard(); });
            tf.addEventListener(flash.events.MouseEvent.MOUSE_UP, function(e : flash.events.MouseEvent) : Void { e.stopImmediatePropagation(); });
            tf.addEventListener(flash.events.MouseEvent.CLICK, function(e : flash.events.MouseEvent) : Void { e.stopImmediatePropagation(); });
            Main.theStage.addChild(tf);
            WirePicker(); // Shift+click on the game = pick a point (coords + terrain), no kick
        }
        catch (e : Dynamic) {}
    }

    // Click the overlay → copy the repro string (+ landing context) to the system clipboard, so it can
    // be pasted straight to chat. Runs in a click handler (a user gesture) on localhost = clipboard OK.
    static function CopyToClipboard() : Void
    {
        var s : String = ReproStr();
        if (hasLand) s += "  | land@(" + R(landX) + "," + R(landY) + ") vy " + R(vyIn) + "->" + R(vyOut)
            + (bounced ? " BOUNCED" : " NO-BOUNCE");
        #if (js && html5)
        try {
            var nav : Dynamic = js.Browser.navigator;
            if (nav != null && (untyped nav.clipboard) != null) {
                (untyped nav.clipboard).writeText(s);
            } else {
                // fallback: hidden textarea + execCommand
                var d : Dynamic = js.Browser.document;
                var ta : Dynamic = d.createElement("textarea");
                ta.value = s; d.body.appendChild(ta); ta.select();
                (untyped d).execCommand("copy"); d.body.removeChild(ta);
            }
            Log("copied: " + s);
        } catch (e : Dynamic) {}
        #end
        copiedFrames = 120; // ~2s "COPIED" flash in the overlay
        UpdateOverlay();
    }

    static function UpdateOverlay() : Void
    {
        if (!on || tf == null) return;
        var s : String = "BOUNCE DEBUG  (B toggle - click box to copy)\n";
        s += hasKick ? ("KICK  @(" + R(kickX) + "," + R(kickY) + ")  v=(" + R(kickVX) + "," + R(kickVY) + ")\n") : "(no kick yet)\n";
        if (hasLand)
            s += "LAND #" + landN + " @(" + R(landX) + "," + R(landY) + ")   vy " + R(vyIn) + " -> " + R(vyOut)
                + (bounced ? "   BOUNCED" : "   *** NO BOUNCE ***") + "\n";
        s += "repro: " + ReproStr();
        if (copiedFrames > 0) { s += "      [COPIED]"; copiedFrames--; }
        if (lastPick != "") s += "\n" + lastPick + " (full terrain in console)";
        tf.text = s;
    }

    static inline function R(v : Float) : Int return Math.round(v);

    static function Log(m : String) : Void
    {
        #if (js && html5)
        try { js.Browser.console.log("[bounce] " + m); } catch (e : Dynamic) {}
        #end
    }
}
