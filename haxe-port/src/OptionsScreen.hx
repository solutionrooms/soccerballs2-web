/**
 * Settings overlay — REMOVED for release.
 *
 * The web port briefly had a hidden settings overlay (a secret bottom-left hotspot that opened a
 * panel with control-scheme / sensitivity / dev toggles). Per product decision it is gone: the
 * control scheme is now chosen by a per-platform first-run default (desktop → A, touch → C+medium;
 * see [[Settings]].Load), with no player-facing settings UI.
 *
 * This inert stub remains ONLY so the input handlers' `if (OptionsScreen.open) return` guards still
 * compile. `open` is always false (nothing ever shows a panel), so those guards are no-ops. The full
 * implementation is recoverable from git history if a settings screen is ever wanted again.
 */
class OptionsScreen
{
    // Always false — there is no overlay to open. Kept so existing `OptionsScreen.open` guards compile.
    public static var open : Bool = false;
}
