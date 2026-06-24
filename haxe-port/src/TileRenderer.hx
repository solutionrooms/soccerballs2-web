import openfl.display.Tile;
import openfl.display.Tileset;
import openfl.display.Tilemap;
import openfl.display.BlendMode;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.geom.ColorTransform;

/**
 * GPU sprite batcher for the gameplay layer (web port only).
 *
 * Replaces the per-frame software compositing (hundreds of screenBD.draw / copyPixels CPU blits)
 * with an OpenFL Tilemap: each visible sprite becomes a Tile (matrix + colorTransform + blendMode +
 * alpha), and OpenFL renders the whole layer in a few GPU batches. The render LAYER calls Push();
 * the game logic is untouched — Push receives exactly the (bitmap, transform, tint, blend) the old
 * blits received.
 *
 * Each frame's standalone BitmapData becomes a one-rect Tileset (cached by identity). Tints (kit
 * colours, shadow silhouettes) and ADD/LAYER/OVERLAY blend modes ride per-tile on the GPU, so the
 * old per-blit getImageData/colorTransform readbacks disappear entirely.
 */
class TileRenderer
{
    public static var tilemap : Tilemap;

    static var pool : Array<Tile> = [];
    static var count : Int = 0;
    static var tilesetCache : haxe.ds.ObjectMap<BitmapData, Tileset> = new haxe.ds.ObjectMap();
    static var scratch : Matrix = new Matrix();

    // DEBUG (batching validation, ?batch1): force every sprite onto one shared texture so the whole
    // layer collapses to ~1 GPU draw call. Renders the WRONG image, but the mobile RAF then tells us
    // whether texture batching is the fix (before building the real atlas packer). Off by default.
    public static var DEBUG_SHARE_TILESET : Bool = false;
    static var sharedTileset : Tileset = null;

    // Benchmark knob: push every sprite N times so the render cost scales N×. On a fast CPU (RAF
    // pinned at the display cap) crank this until RAF drops off the cap to reveal the real per-render
    // cost and headroom. count = GPU tiles emitted this frame (shown in the perf HUD).
    public static var stress : Int = 1;
    public static var lastCount : Int = 0;

    // DIAGNOSTIC (?nounderlay): don't display the software underlay bitmap (screenB), so its dynamic
    // 700x525 texture is never re-uploaded to the GPU each frame. Isolates the iOS texImage2D-from-
    // canvas stall from the tilemap vertex-buffer stall. Renders sprites on a blank background.
    public static var noUnderlay : Bool = false;

    // DIAGNOSTIC (?notiles): emit zero tiles (empty tilemap), to split the cost of the sprite tiles
    // from the rest of the WebGL stage (underlay texture upload + vector UI tessellation).
    public static var noTiles : Bool = false;

    public static function Init(w : Int, h : Int) : Tilemap
    {
        DEBUG_SHARE_TILESET = Settings.gpuBatchTest; // persisted options toggle
        #if !release // dev render-diagnostic URL knobs (?batch1/?nounderlay/?notiles) — stripped from the public build
        try {
            var q : String = js.Browser.window.location.search;
            if (q != null && q.indexOf("batch1") >= 0) DEBUG_SHARE_TILESET = true; // URL override still works
            if (q != null && q.indexOf("nounderlay") >= 0) noUnderlay = true;
            if (q != null && q.indexOf("notiles") >= 0) noTiles = true;
        } catch (e : Dynamic) {}
        #end
        tilemap = new Tilemap(w, h, null, true /* smoothing */);
        tilemap.tileAlphaEnabled = true;
        tilemap.tileColorTransformEnabled = true;
        tilemap.tileBlendModeEnabled = true;
        #if !release // iOS stall diagnostics: ?noblend disables per-tile blend modes (LAYER/OVERLAY need a
        // destination-framebuffer read = an iOS stall); ?noct disables per-tile colorTransform.
        try {
            var q2 : String = js.Browser.window.location.search;
            if (q2 != null && q2.indexOf("noblend") >= 0) tilemap.tileBlendModeEnabled = false;
            if (q2 != null && q2.indexOf("noct") >= 0) tilemap.tileColorTransformEnabled = false;
        } catch (e : Dynamic) {}
        #end
        return tilemap;
    }

    static inline function tilesetFor(bd : BitmapData) : Tileset
    {
        var ts = tilesetCache.get(bd);
        if (ts == null)
        {
            ts = new Tileset(bd, [new Rectangle(0, 0, bd.width, bd.height)]);
            tilesetCache.set(bd, ts);
        }
        return ts;
    }

    // Start a fresh frame: clears tiles but keeps the pool (Tile objects are reused, no GC churn).
    public static function Begin() : Void
    {
        if (tilemap != null) tilemap.removeTiles();
        lastCount = count;
        count = 0;
    }

    // Push one sprite. mat is the same transform the old screenBD.draw used; ct/blend may be null.
    public static function Push(bd : BitmapData, mat : Matrix, ct : ColorTransform = null, blend : BlendMode = null) : Void
    {
        if (bd == null || tilemap == null || noTiles) return;
        var ts = tilesetFor(bd);
        if (DEBUG_SHARE_TILESET)
        {
            if (sharedTileset == null) sharedTileset = ts;
            ts = sharedTileset; // all sprites -> one texture -> ~1 draw call (batching test)
        }
        var reps = stress < 1 ? 1 : stress;
        for (r in 0...reps)
        {
            var t : Tile;
            if (count < pool.length) t = pool[count];
            else { t = new Tile(0); pool.push(t); }
            t.tileset = ts;
            t.id = 0;
            // Tile stores the Matrix by reference, so each tile needs its own copy.
            t.matrix = mat.clone();
            t.colorTransform = ct;   // null clears any tint from a previous reuse of this pooled tile
            t.blendMode = blend;     // null = normal
            t.alpha = 1.0;
            tilemap.addTile(t);
            count++;
        }
    }

    // Simple unrotated blit at (x,y) — the copyPixels case.
    public static function PushAt(bd : BitmapData, x : Float, y : Float) : Void
    {
        scratch.identity();
        scratch.tx = x;
        scratch.ty = y;
        Push(bd, scratch);
    }
}
