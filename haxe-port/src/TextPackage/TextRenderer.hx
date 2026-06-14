package textPackage;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author 
	 */
class TextRenderer
{
    
    
    public function new()
    {
    }
    
    
    public static function InitOnce()
    {
    }
    
    public static var xspacing_offset : Int = -3;
    
    public static inline var JUSTIFY_LEFT : Int = 0;
    public static inline var JUSTIFY_CENTRE : Int = 1;
    public static inline var JUSTIFY_RIGHT : Int = 2;
    
    public static var stringCharX : Float;
    public static var stringCharY : Float;
    public static var stringCharBitmapData : BitmapData;
    private static var m : Matrix = new Matrix();
    private static var p : Point = new Point(0, 0);
    public static function RenderAt(screenBD : BitmapData, x : Float, y : Float, str : String, dir : Float = 0, scale : Float = 1, justify : Int = JUSTIFY_CENTRE, ct : ColorTransform = null)
    {
        if (Game.use_localisation)
        {
            str = TextStrings.GetLocalisedText(str);
        }
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("font1");
        
        m.identity();
        m.rotate(dir);
        m.scale(scale, scale);
        
        var width : Float = cast((str), GetStringWidth);
        if (justify == JUSTIFY_LEFT)
        {
        }
        else if (justify == JUSTIFY_CENTRE)
        {
            p.x = -(width / 2);
            p.y = 0;
            p = m.transformPoint(p);
            x += p.x;
            y += p.y;
        }
        else if (justify == JUSTIFY_RIGHT)
        {
            p.x = -(width);
            p.y = 0;
            p = m.transformPoint(p);
            x += p.x;
            y += p.y;
        }
        
        
        stringCharX = x;
        stringCharY = y;
        var i : Int;
        for (i in 0...str.length)
        {
            var a : Int = as3hx.Compat.parseInt(str.charCodeAt(i));
            if (a < 0)
            {
                a = 0;
            }
            if (a > 255)
            {
                Utils.print("missing char code " + a);
                a = 32;
            }
            
            dobj.RenderAtRotScaled(a, screenBD, stringCharX, stringCharY, scale, dir, ct);
            
            p.x = dobj.GetWidth(a) + xspacing_offset;
            p.y = 0;
            p = m.transformPoint(p);
            
            stringCharX += p.x;
            stringCharY += p.y;
        }
    }
    
    
    public static function GetStringWidth(str : String) : Float
    {
        return cast((str), GetStringDimensions).width;
    }
    
    public static function GetStringHeight(str : String) : Int
    {
        return cast((str), GetStringDimensions).height;
    }
    public static function GetStringDimensions(str : String) : Rectangle
    {
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("font1");
        
        var r : Rectangle = new Rectangle(0, 0, 1, 1);
        stringCharX = 0;
        stringCharY = 0;
        var i : Int;
        for (i in 0...str.length)
        {
            var a : Int = as3hx.Compat.parseInt(str.charCodeAt(i));
            if (a < 0)
            {
                a = 0;
            }
            if (a > 255)
            {
                a = 32;
            }
            
            var r1 : Rectangle = dobj.GetSourceRect(a).clone();
            r1.x -= r1.x;
            r1.y -= r1.y;
            r1.x += stringCharX;
            r1.y += stringCharY;
            r = r.union(r1);
            stringCharX += r1.width + xspacing_offset;
        }
        return r;
    }
}

