/**
 * HD experiment — the single switch all HD-only rendering keys off.
 *
 * Built with `-Dhd` (see `npm run hd:build`, which outputs to haxe-port/site/hd/ → served at /hd/).
 * The normal / live build has NO `-Dhd`, so:
 *   HD.ON    = false
 *   HD.SCALE = 1.0
 * Both are `inline`, so when HD code is gated on them the compiler folds it away — the live build
 * compiles exactly as it does today (this module is referenced only inside `#if hd` blocks).
 *
 * As the HD render work begins, multiply the render-side resolutions by HD.SCALE: the texture
 * rasterization scale (DisplayObj `scl`), the software layers (screenBD / backBD / terrain), the
 * Tilemap size, and the global render scale — game logic stays in the native 700x525 space untouched.
 */
class HD {
    public static inline var ON : Bool = #if hd true #else false #end;
    public static inline var SCALE : Float = #if hd 2.0 #else 1.0 #end;
}
