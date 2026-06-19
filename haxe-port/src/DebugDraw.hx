import flash.display.BitmapData;
import flash.display.MovieClip;

// Physics debug-draw ("grid view"): outlines every collision shape the engine actually has — terrain
// triangles (so the sliver seams are visible), the ball, walls, posts — colour-coded by body type.
// Toggle with the 'G' key. Drawn onto the foreground layer (above the tilemap) each frame. Pairs with
// the Shift+click picker (BounceDebug) so you can see a triangle/seam and pick its coords.
class DebugDraw
{
    public static var on : Bool = false;
    static var dmc : MovieClip = null;

    public static function Toggle() : Void { on = !on; }

    public static function Draw(target : BitmapData) : Void
    {
        if (!on || target == null) return;
        if (dmc == null) dmc = new MovieClip();
        var g = dmc.graphics;
        g.clear();
        var cx = Game.camera.x; // world -> screen (the renderer draws world at screen = world - camera)
        var cy = Game.camera.y;
        var space = PhysicsBase.GetNapeSpace();
        for (b in space.bodies)
        {
            // static = green, dynamic = yellow, kinematic = cyan
            var col = b.isStatic() ? 0x33ff66 : (b.isDynamic() ? 0xffee33 : 0x33ddff);
            for (sh in b.shapes)
            {
                var alpha = sh.sensorEnabled ? 0.45 : 0.9; // sensors fainter
                g.lineStyle(1, col, alpha);
                if (sh.isPolygon())
                {
                    var p : nape.shape.Polygon = cast sh;
                    var lv = p.worldVerts;
                    var n = lv.length;
                    if (n > 0)
                    {
                        g.moveTo(lv.at(0).x - cx, lv.at(0).y - cy);
                        for (i in 1...n) g.lineTo(lv.at(i).x - cx, lv.at(i).y - cy);
                        g.lineTo(lv.at(0).x - cx, lv.at(0).y - cy);
                    }
                }
                else if (sh.isCircle())
                {
                    var c : nape.shape.Circle = cast sh;
                    var wc = sh.worldCOM;
                    g.drawCircle(wc.x - cx, wc.y - cy, c.radius);
                }
            }
        }
        target.draw(dmc, null, null, null, null, false);
    }
}
