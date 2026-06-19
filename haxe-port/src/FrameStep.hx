import flash.text.TextField;
import flash.text.TextFieldAutoSize;

// Frame-advance debug mode ("code-debugger" stepping for the sim).
//   ','  toggles pause: the realtime clock is frozen but the screen keeps rendering, so the
//        last simulated frame stays on screen and overlays (grid view / bounce debug) update.
//   '.'  single-steps exactly ONE simulation frame (logic + physics). If not already paused it
//        pauses first, so a single tap of '.' = "freeze here and advance one frame".
// An on-screen banner shows the paused state and how many frames you've stepped since pausing.
// Pairs with the 'G' grid view (which draws per-body velocity arrows) so you can watch a body's
// motion evolve one frame at a time — e.g. to see exactly when/where a character starts drifting.
class FrameStep
{
    public static var paused : Bool = false;
    public static var stepReq : Int = 0;   // sim frames queued to run while paused (consumed by Main.MainLoop)
    public static var frameNo : Int = 0;   // frames advanced since the current pause began
    public static var pauseAtStart : Bool = false; // when armed, every level begins FROZEN at frame 0
    static var tf : TextField = null;

    // Called from Game.StartLevel — freezes a freshly loaded level at frame 0 (its untouched initial
    // state, before any physics) when armed, so you can step forward from the very first frame.
    public static function OnLevelStart() : Void
    {
        if (pauseAtStart) { paused = true; frameNo = 0; stepReq = 0; }
        else { paused = false; stepReq = 0; }
        tripped = false; xformTripped = false; tripLog = ""; // re-arm the NaN tripwires for the freshly loaded level
        UpdateBanner();
    }

    // ---- NaN tripwire (debug) -------------------------------------------------
    // Scans every active GameObject body; the FIRST time (per level) any body has a
    // non-finite pos/vel, traces the STAGE it was caught at and the offending object,
    // then disarms. Called at three points per frame (frame-start / after-pre-update /
    // after-physics-step) so we learn whether the NaN comes from level LOAD, the game's
    // pre-physics update (SetBodyXForm etc.), or the physics solver itself.
    static var tripped : Bool = false;
    public static var tripLog : String = ""; // queryable via sb2TripLog() (trace visibility is unreliable)
    public static var pathInitLog : String = ""; // last path_object's dir/rotation at init (sb2PathInit())
    public static function PathInit(name : String, bodyRot : Float, dir : Float, px : Float, py : Float) : Void
    {
        pathInitLog = "[PATHINIT] go=" + name + " bodyRot=" + bodyRot + " dir=" + dir + " pos=(" + px + "," + py + ")";
    }
    public static function NaNTrip(stage : String) : Void
    {
        if (tripped) return;
        for (go in GameObjects.objs)
        {
            if (go == null || !go.active) continue;
            var nb : Array<Dynamic> = go.nape_bodies;
            if (nb == null) continue;
            for (i in 0...nb.length)
            {
                if (nb[i] == null) continue;
                var b : nape.phys.Body = nb[i];
                var px = b.position.x; var py = b.position.y;
                var vx = b.velocity.x; var vy = b.velocity.y;
                if (!Math.isFinite(px) || !Math.isFinite(py) || !Math.isFinite(vx) || !Math.isFinite(vy))
                {
                    tripped = true;
                    var msg = "[NANTRIP] stage=" + stage + " frame=" + frameNo + " go=" + go.name
                        + " body#" + i + " type=" + b.type
                        + " pos=(" + px + "," + py + ") vel=(" + vx + "," + vy + ")";
                    tripLog += msg + "\n";
                    trace(msg);
                    return;
                }
            }
        }
    }

    // SetBodyXForm input guard — traces the FIRST time the game feeds a non-finite value
    // into a kinematic mover, or calls it on an already-NaN body. Disarms after one hit.
    static var xformTripped : Bool = false;
    public static function XFormCheck(name : String, x : Float, y : Float, rot : Float, curX : Float, curY : Float) : Void
    {
        if (xformTripped) return;
        if (Math.isFinite(x) && Math.isFinite(y) && Math.isFinite(rot) && Math.isFinite(curX) && Math.isFinite(curY)) return;
        xformTripped = true;
        var msg = "[XFORM-NAN] go=" + name + " in=(" + x + "," + y + "," + rot + ") bodyPosBefore=(" + curX + "," + curY + ")";
        tripLog += msg + "\n";
        trace(msg);
    }

    public static function TogglePause() : Void
    {
        paused = !paused;
        stepReq = 0;
        if (paused) frameNo = 0;
        UpdateBanner();
    }

    public static function Step() : Void
    {
        if (!paused) { paused = true; frameNo = 0; }
        stepReq++;
        UpdateBanner();
    }

    // Main calls this each time a queued step actually runs, so the banner counts real sim frames.
    public static function OnStepped() : Void
    {
        frameNo++;
        UpdateBanner();
    }

    public static function UpdateBanner() : Void
    {
        Ensure();
        if (tf == null) return;
        tf.visible = paused || pauseAtStart;
        if (paused) tf.text = "  PAUSED  (+" + frameNo + " frames)    [ , ] resume    [ . ] step    [ G ] grid+vel  ";
        else if (pauseAtStart) tf.text = "  STEP-MODE ARMED — levels start frozen at frame 0    [ M ] off  ";
    }

    static function Ensure() : Void
    {
        if (tf != null) return;
        try
        {
            tf = new TextField();
            tf.selectable = false;
            tf.mouseEnabled = false;          // never intercept clicks (so kicking still works while paused)
            tf.autoSize = TextFieldAutoSize.LEFT;
            tf.background = true;
            tf.backgroundColor = 0x000000;
            tf.textColor = 0xffdd33;
            tf.x = 4;
            tf.y = 4;
            tf.visible = false;
            Main.theStage.addChild(tf);
        }
        catch (e : Dynamic) {}
    }
}
