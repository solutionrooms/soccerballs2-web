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

    // Mobile control scheme: 0 = A (drag/aim with pointer), 1 = B (virtual joystick + tap-near-ball),
    // 2 = C ("Aim Pad": relative drag-aim + tap-fire). The first-run default is platform-dependent —
    // desktop → A, touch (mobile/tablet) → C — and is assigned in Load() (overridden by any saved value).
    public static var mobileControlScheme : Int = 0;

    // Aim-pad (scheme C) joystick sensitivity: 0 = Low, 1 = Med, 2 = High. Lower = the stick needs more
    // travel for the same aim change (finer control). Default Med.
    public static var aimSensitivity : Int = 1;

    // Diagnostic: force all sprites onto one shared GPU texture (~1 draw call). Renders the WRONG image
    // (garbled), but isolates draw-call cost from per-sprite cost when measuring perf across devices.
    public static var gpuBatchTest : Bool = false;

    // PERF FIX (iOS): cache each static terrain object's vector rasterization to a GPU texture ONCE (at
    // first render) and just re-position the tile each frame, instead of re-rasterizing a full-screen
    // bitmap and re-uploading it (texImage2D) every frame. The per-frame re-upload of N terrain bitmaps
    // was the iOS GPU stall (scaled with on-screen terrain → the frame-time variance). CONFIRMED on
    // device: 15–25fps → solid 60. On by default; the Options toggle stays so it can be turned off to
    // compare or to rule it out if a level's terrain ever looks wrong.
    public static var cachedTerrain : Bool = true;

    // Diagnostic: neutralise poly_mud's very high friction (100 -> grass-like) when building terrain.
    // Tests whether sticky-mud walls are what make shots like level 9 fail in the port. Applied at
    // level load, so toggle then restart the level. Does NOT change the original game data.
    public static var noMudFriction : Bool = false;
    public static var debugKeys : Bool = false; // dev debug keys (B/G/,/./M/1-6) only work when ON

    public static inline var SCHEME_A : Int = 0;
    public static inline var SCHEME_B : Int = 1;
    public static inline var SCHEME_C : Int = 2; // "Aim Pad": relative drag-aim + tap-fire + 2-finger fine
    public static inline var SCHEME_D : Int = 3; // "Aim Pad + Arrows": scheme C + on-screen arrow fine-tune buttons

    static inline var SID : String = "soccerballs2_settings";

    // Touch device (phone/tablet) vs desktop — used ONLY to pick the first-run control-scheme default.
    // "(hover: none) and (pointer: coarse)" is true for finger-primary devices (phones/tablets) and
    // false for desktops, including touch-screen laptops (which still have a fine pointer / hover).
    // Falls back to a user-agent sniff for older browsers without matchMedia.
    public static function IsTouchDevice() : Bool
    {
        #if (js && html5)
        try
        {
            var w : Dynamic = js.Browser.window;
            if (w != null && (untyped w.matchMedia) != null)
            {
                var mq : Dynamic = w.matchMedia("(hover: none) and (pointer: coarse)");
                if (mq != null && mq.matches == true) return true;
                // If matchMedia is present and clearly reports a desktop pointer, trust it (no UA sniff).
                var mqFine : Dynamic = w.matchMedia("(pointer: fine)");
                if (mqFine != null && mqFine.matches == true) return false;
            }
            var nav : Dynamic = js.Browser.navigator;
            var ua : String = (nav != null && nav.userAgent != null) ? Std.string(nav.userAgent) : "";
            var re = ~/Android|iPhone|iPad|iPod|Mobile|Tablet|Silk|Kindle|BlackBerry|Opera Mini|IEMobile/i;
            if (re.match(ua)) return true;
        }
        catch (e : Dynamic) {}
        #end
        return false;
    }

    public static function Load() : Void
    {
        // Platform-appropriate first-run default (overridden below by any saved value):
        //   desktop               → scheme A (pointer drag-aim)
        //   touch (mobile/tablet) → scheme C ("Aim Pad") + medium sensitivity
        if (IsTouchDevice()) { mobileControlScheme = SCHEME_C; aimSensitivity = 1; }
        else                 { mobileControlScheme = SCHEME_A; }

        try
        {
            var so : SharedObject = SharedObject.getLocal(SID);
            if (so != null && so.data != null)
            {
                if (so.data.mobileControlScheme != null) mobileControlScheme = Std.int(so.data.mobileControlScheme);
                if (so.data.aimSensitivity != null) aimSensitivity = Std.int(so.data.aimSensitivity);
                if (so.data.cachedTerrain != null) cachedTerrain = so.data.cachedTerrain;
                #if !release
                // Dev-only flags: never honoured in the public release build, so a developer's stale
                // local prefs (e.g. perfHud / openAllLevels left ON) can't leak into a release test.
                if (so.data.perfHud != null) perfHud = so.data.perfHud;
                if (so.data.openAllLevels != null) openAllLevels = so.data.openAllLevels;
                if (so.data.gpuBatchTest != null) gpuBatchTest = so.data.gpuBatchTest;
                if (so.data.noMudFriction != null) noMudFriction = so.data.noMudFriction;
                if (so.data.debugKeys != null) debugKeys = so.data.debugKeys;
                #end
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
            so.data.aimSensitivity = aimSensitivity;
            so.data.gpuBatchTest = gpuBatchTest;
            so.data.cachedTerrain = cachedTerrain;
            so.data.noMudFriction = noMudFriction;
            so.data.debugKeys = debugKeys;
            so.flush();
            (untyped so).close();
        }
        catch (e : Dynamic) {}
    }
}
