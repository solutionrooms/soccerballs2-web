import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.text.TextField;
import flash.text.TextFormat;

// Debug map overview ('S' key, gated by Settings.debugKeys). Zooms the whole level into the screen as a
// schematic — terrain mass, the camera viewport, and a marker on every collectible (stars = the coin
// pickups, trophies = the cup pickups) — so you can eyeball that every star is reachable. Drawn onto
// the foreground layer each frame (same hook as DebugDraw); the backdrop replaces the live view.
class MapView
{
    public static var on : Bool = false;
    static var dmc : MovieClip = null;
    static var tf : TextField = null;

    public static function Toggle() : Void { on = !on; }

    static function tmpl(go : Dynamic) : String { return try (cast go.physobj : Dynamic).name catch (e : Dynamic) null; }

    static function star(g : Dynamic, cx : Float, cy : Float, r : Float, col : Int, a : Float) : Void
    {
        g.lineStyle();
        g.beginFill(col, a);
        for (i in 0...10)
        {
            var rad = (i % 2 == 0) ? r : r * 0.45;
            var ang = -Math.PI / 2 + i * Math.PI / 5;
            var x = cx + Math.cos(ang) * rad;
            var y = cy + Math.sin(ang) * rad;
            if (i == 0) g.moveTo(x, y); else g.lineTo(x, y);
        }
        g.endFill();
    }

    public static function Draw(target : BitmapData) : Void
    {
        if (!on || target == null || Game.boundingRectangle == null || GameObjects.objs == null) return;
        if (dmc == null) dmc = new MovieClip();
        var g = dmc.graphics;
        g.clear();

        // --- fit: union the camera bounds with every pickup so no star falls off the map ---
        var br = Game.boundingRectangle;
        var minX = br.x, minY = br.y, maxX = br.right, maxY = br.bottom;
        for (go in GameObjects.objs)
        {
            if (go == null || !go.active) continue;
            var tn = tmpl(go);
            if (tn == null || tn.substr(0, 6) != "pickup") continue;
            if (go.xpos < minX) minX = go.xpos;
            if (go.xpos > maxX) maxX = go.xpos;
            if (go.ypos < minY) minY = go.ypos;
            if (go.ypos > maxY) maxY = go.ypos;
        }
        var bw = maxX - minX, bh = maxY - minY;
        if (bw <= 0 || bh <= 0) return;
        var margin = 28.0;
        var sw = Defs.displayarea_w - margin * 2, sh = Defs.displayarea_h - margin * 2;
        var scale = Math.min(sw / bw, sh / bh);
        var ox = margin + (sw - bw * scale) / 2;
        var oy = margin + (sh - bh * scale) / 2;
        var mx = function(wx : Float) : Float return ox + (wx - minX) * scale;
        var my = function(wy : Float) : Float return oy + (wy - minY) * scale;

        // --- backdrop + frame (near-opaque so the camera-scale live art doesn't fight the map-scale
        //     schematic; everything below is drawn at map scale so markers align with the terrain) ---
        g.lineStyle();
        g.beginFill(0x0a1420, 0.98);
        g.drawRect(0, 0, Defs.displayarea_w, Defs.displayarea_h);
        g.endFill();
        g.lineStyle(1, 0x3a5a7a, 0.8);
        g.drawRect(ox, oy, bw * scale, bh * scale);

        // --- terrain (static solid polys) filled, so the navigable space reads ---
        var space = try PhysicsBase.GetNapeSpace() catch (e : Dynamic) null;
        if (space != null)
        {
            for (b in space.bodies)
            {
                if (!b.isStatic()) continue;
                for (s2 in b.shapes)
                {
                    if (s2.sensorEnabled || !s2.isPolygon()) continue;
                    var p : nape.shape.Polygon = cast s2;
                    var lv = p.worldVerts;
                    if (lv.length < 3) continue;
                    g.lineStyle(1, 0x5c8a4a, 0.35);
                    g.beginFill(0x3a5e3c, 0.95);
                    g.moveTo(mx(lv.at(0).x), my(lv.at(0).y));
                    for (i in 1...lv.length) g.lineTo(mx(lv.at(i).x), my(lv.at(i).y));
                    g.lineTo(mx(lv.at(0).x), my(lv.at(0).y));
                    g.endFill();
                }
            }
        }

        // --- current camera viewport (where the live view is) ---
        g.lineStyle(1.5, 0xffffff, 0.9);
        g.drawRect(mx(Game.camera.x), my(Game.camera.y), Defs.displayarea_w * scale, Defs.displayarea_h * scale);

        // --- collectibles + goal + ball ---
        var nStar = 0, nGot = 0, nTroph = 0;
        for (go in GameObjects.objs)
        {
            if (go == null || !go.active) continue;
            var tn = tmpl(go);
            if (tn == null) continue;
            var px = mx(go.xpos), py = my(go.ypos);
            if (tn == "pickup_normal")
            {
                var got = false;
                try { got = (go.onHitFunction == null); } catch (e : Dynamic) {}
                nStar++;
                if (got) nGot++;
                star(g, px, py, 6, got ? 0x666644 : 0xffe24a, got ? 0.55 : 1.0);
            }
            else if (tn.substr(0, 13) == "pickup_trophy")
            {
                nTroph++;
                star(g, px, py, 8, 0xffaa00, 1.0);
                g.lineStyle(2, 0xffd86a, 0.95);
                g.drawCircle(px, py, 11);
            }
            else if (tn == "goal")
            {
                g.lineStyle(2, 0x44ddff, 0.9);
                g.drawRect(px - 6, py - 10, 12, 20);
            }
        }
        // player ball
        var fb : Dynamic = GameVars.footballGO;
        if (fb != null)
        {
            var bx = mx(fb.xpos), by = my(fb.ypos);
            g.lineStyle(1, 0x000000, 1);
            g.beginFill(0xffffff, 1);
            g.drawCircle(bx, by, 5);
            g.endFill();
        }

        // --- title / counts ---
        if (tf == null)
        {
            tf = new TextField();
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.width = Defs.displayarea_w - 16;
            tf.x = 10;
            tf.y = 5;
            dmc.addChild(tf);
        }
        tf.defaultTextFormat = new TextFormat("_sans", 14, 0xffffff, true);
        tf.text = "MAP [S]   stars " + nGot + "/" + nStar + " collected   trophies " + nTroph
            + "   (yellow=star  gold=trophy  white box=view  white dot=ball)";

        target.draw(dmc, null, null, null, null, false);
    }
}
