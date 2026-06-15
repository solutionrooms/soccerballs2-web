import flash.display.MovieClip;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;

class Particles
{
    public static inline var type_dust = 0;
    
    public static var max : Int = 0;
    public static var list : Array<Particle>;
    public static var nextIndex : Int = 0;
    
    public static function InitOnce(_max : Int) : Void
    {
        max = _max;
        nextIndex = 0;
        list = [];
        var i : Int = 0;        var j : Int = 0;        for (i in 0...max)
        {
            list[i] = new Particle();
            list[i].active = false;
        }
    }
    
    public function new()
    {
    }
    
    public static function CountActive() : Int
    {
        var numActive : Int = 0;
        var i : Int = 0;        for (i in 0...max)
        {
            if (list[i].active)
            {
                numActive++;
            }
        }
        return numActive;
    }
    
    public static function GetNextIndex() : Int
    {
        return nextIndex;
    }
    
    public static function Reset()
    {
        nextIndex = 0;
        var i : Int = 0;        for (i in 0...max)
        {
            list[i].active = false;
        }
    }
    
    
    
    public static function Add(xpos : Float, ypos : Float) : Particle
    {
        var vel : Float = Math.NaN;        var ang : Float = Math.NaN;        var p : Particle = list[nextIndex];
        nextIndex++;
        if (nextIndex >= max)
        {
            nextIndex = 0;
        }
        p.active = true;
        p.timer = 0;
        p.alpha = 1.0;
        p.alphaAdd = 0;
        p.visible = true;
        p.xpos = xpos;
        p.ypos = ypos;
        p.angle = 0;
        p.psize = 1;
        p.dobj = null;
        return p;
    }
    
    public static function Update()
    {
        var i : Int = 0;        for (i in 0...max)
        {
            var p : Particle = list[i];
            if (p.active == true)
            {
                p.updateFunction();
            }
        }
    }
    
    public static function Render(_bd : BitmapData)
    {
        if (false)
        {
            return;
        }
        
        var bd : BitmapData = _bd;
        
        var camScale : Float = Game.camera.scale;
        
        var ct : ColorTransform = new ColorTransform();
        
        
        bd.lock();
        var x0 : Float = 0 - 16;
        var x1 : Float = Defs.displayarea_w + 16;
        var y0 : Float = 0 - 16;
        var y1 : Float = Defs.displayarea_h + 16;
        var sx : Float = Game.camera.x;
        var sy : Float = Game.camera.y;
        var i : Int = 0;        var j : Int = 0;        for (i in 0...max)
        {
            var p : Particle = list[i];
            if (p.active && p.visible)
            {
                var xp1 : Float = (p.xpos - sx) * camScale;
                var yp1 : Float = (p.ypos - sy) * camScale;
                
                
                {
                    
                    var sc : Float = camScale;
                    
                    if (p.dobj != null)
                    {
                        if (p.angle == 0 && p.alpha == 1)
                        {
                            p.dobj.RenderAt(as3hx.Compat.parseInt(p.frame), bd, xp1, yp1);
                        }
                        else
                        {
                            ct.alphaMultiplier = p.alpha;
                            p.dobj.RenderAtRotScaled(as3hx.Compat.parseInt(p.frame), bd, xp1, yp1, sc, p.angle, ct);
                        }
                    }
                    else if (p.psize == 1)
                    {
                        bd.setPixel32(Std.int(xp1), Std.int(yp1), (untyped p).color);
                    }
                    else if (p.psize == 2)
                    {
                        bd.setPixel32(Std.int(xp1), Std.int(yp1), (untyped p).color);
                        bd.setPixel32(Std.int(xp1 + 1), Std.int(yp1), (untyped p).color);
                        bd.setPixel32(Std.int(xp1), Std.int(yp1 + 1), (untyped p).color);
                        bd.setPixel32(Std.int(xp1 + 1), Std.int(yp1 + 1), (untyped p).color);
                    }
                    else if (p.psize == 3)
                    {
                        var c : Int = (untyped p).color;
                        c = c | as3hx.Compat.parseInt(Std.int(p.alpha) << 24);
                        
                        bd.setPixel32(Std.int(xp1 - 1), Std.int(yp1 - 1), c);
                        bd.setPixel32(Std.int(xp1), Std.int(yp1 - 1), c);
                        bd.setPixel32(Std.int(xp1 + 1), Std.int(yp1 - 1), c);
                        bd.setPixel32(Std.int(xp1 - 1), Std.int(yp1), c);
                        bd.setPixel32(Std.int(xp1), Std.int(yp1), c);
                        bd.setPixel32(Std.int(xp1 + 1), Std.int(yp1), c);
                        bd.setPixel32(Std.int(xp1 - 1), Std.int(yp1 + 1), c);
                        bd.setPixel32(Std.int(xp1), Std.int(yp1 + 1), c);
                        bd.setPixel32(Std.int(xp1 + 1), Std.int(yp1 + 1), c);
                    }
                }
            }
        }
        bd.unlock();
    }
}




