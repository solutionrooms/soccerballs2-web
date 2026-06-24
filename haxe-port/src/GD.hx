import audioPackage.Audio;

/**
 * GameDistribution ad bridge (web port only — not part of the original AS3 game).
 *
 * The GD HTML5 SDK is loaded ONCE in index.html, in the RELEASE build only (see the
 * `::if (SET_RELEASE)::` block in templates/html5/template/index.html). That snippet's
 * `GD_OPTIONS.onEvent` calls `window.sb2GdPause` / `window.sb2GdResume` (exposed below) when a
 * video ad starts / finishes, so we FREEZE gameplay + MUTE all audio while the ad plays and restore
 * on resume (GD requires the game to pause and mute during ads).
 *
 * Ads are requested with `ShowAd()` from button CLICK handlers only (GD rule: ads must fire from a
 * user gesture, outside gameplay): a pre-roll when the player first starts a level, and mid-rolls on
 * the level-complete / level-failed buttons. The SDK throttles how often a real ad actually shows, so
 * it's safe to call ShowAd() on every such button.
 */
class GD
{
    // True while a GD video ad is playing. Main.MainLoop skips SimFrame so the simulation is frozen.
    public static var adPaused : Bool = false;

    // GD_OPTIONS.onEvent("SDK_GAME_PAUSE"): freeze gameplay + mute everything for the ad.
    @:expose("sb2GdPause")
    public static function Pause() : Void
    {
        adPaused = true;
        try { Audio.MuteAll(false); Audio.MuteAll(true); } catch (e : Dynamic) {}
    }

    // GD_OPTIONS.onEvent("SDK_GAME_START"): resume gameplay + restore audio to the player's own mute
    // preference (don't un-mute a channel the player had deliberately muted).
    @:expose("sb2GdResume")
    public static function Resume() : Void
    {
        adPaused = false;
        try {
            if (!Audio.muteSFX) Audio.UnMuteAll(false);
            if (!Audio.muteMusic) Audio.UnMuteAll(true);
        } catch (e : Dynamic) {}
    }

    // Request a video ad. MUST be called from inside a user click/tap handler. No-op in dev builds
    // (the SDK is only loaded in the release build); the SDK itself rate-limits real ad frequency.
    public static function ShowAd() : Void
    {
        #if release
        try {
            js.Syntax.code("if (typeof window.gdsdk !== 'undefined' && window.gdsdk && typeof window.gdsdk.showAd === 'function') { window.gdsdk.showAd(); }");
        } catch (e : Dynamic) {}
        #end
    }
}
