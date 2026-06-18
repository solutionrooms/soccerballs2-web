import flash.net.SharedObject;

/**
 * Device-local user preferences for the web port (not part of the original AS3 game).
 *
 * Stored in a dedicated SharedObject ("soccerballs2_settings") separate from the game-progress
 * save, so prefs persist independently of game progress and can be flushed immediately on toggle
 * (the main SaveData.Load early-returns when there is no progress save yet).
 */
class Settings
{
    // Show the performance HUD (fps/raf/frame-time overlay).
    public static var perfHud : Bool = false;

    // Dev convenience: make every level selectable in level-select regardless of unlock progress.
    // Non-destructive — does not alter saved scores/stars.
    public static var openAllLevels : Bool = false;

    // Mobile control scheme: 0 = A (current: drag/aim with pointer), 1 = B (virtual joystick + tap-near-ball).
    public static var mobileControlScheme : Int = 0;

    // Diagnostic: force all sprites onto one shared GPU texture (~1 draw call). Renders the WRONG image
    // (garbled), but isolates draw-call cost from per-sprite cost when measuring perf across devices.
    public static var gpuBatchTest : Bool = false;

    // Diagnostic: neutralise poly_mud's very high friction (100 -> grass-like) when building terrain.
    // Tests whether sticky-mud walls are what make shots like level 9 fail in the port. Applied at
    // level load, so toggle then restart the level. Does NOT change the original game data.
    public static var noMudFriction : Bool = false;

    public static inline var SCHEME_A : Int = 0;
    public static inline var SCHEME_B : Int = 1;

    static inline var SID : String = "soccerballs2_settings";

    public static function Load() : Void
    {
        try
        {
            var so : SharedObject = SharedObject.getLocal(SID);
            if (so != null && so.data != null)
            {
                if (so.data.perfHud != null) perfHud = so.data.perfHud;
                if (so.data.openAllLevels != null) openAllLevels = so.data.openAllLevels;
                if (so.data.mobileControlScheme != null) mobileControlScheme = Std.int(so.data.mobileControlScheme);
                if (so.data.gpuBatchTest != null) gpuBatchTest = so.data.gpuBatchTest;
                if (so.data.noMudFriction != null) noMudFriction = so.data.noMudFriction;
                (untyped so).close();
            }
        }
        catch (e : Dynamic) {}
    }

    public static function Save() : Void
    {
        try
        {
            var so : SharedObject = SharedObject.getLocal(SID);
            so.data.perfHud = perfHud;
            so.data.openAllLevels = openAllLevels;
            so.data.mobileControlScheme = mobileControlScheme;
            so.data.gpuBatchTest = gpuBatchTest;
            so.data.noMudFriction = noMudFriction;
            so.flush();
            (untyped so).close();
        }
        catch (e : Dynamic) {}
    }
}
