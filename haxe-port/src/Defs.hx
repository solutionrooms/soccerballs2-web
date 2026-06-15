import flash.geom.Point;
import flash.geom.Rectangle;

/**
	* ...
	* @author Default
	*/
class Defs
{
    
    public static inline var maxParticles : Int = 30;
    public static inline var maxGameObjects : Int = 450;
    
    public static inline var editor_area_w : Int = 1200;
    public static inline var editor_x : Int = 700;
    
    public static inline var displayarea_w : Int = 700;
    public static inline var displayarea_h : Int = 525;
    public static inline var gamearea_h : Int = 525;
    public static var displayarea_w2 : Int = Std.int(700 / 2);
    public static var displayarea_h2 : Int = Std.int(525 / 2);
    public static var fps : Float = 60;
    public static inline var ui_fps : Float = 30;
    
    public static var screenRect : Rectangle = new Rectangle(0, 0, displayarea_w, displayarea_h);
    public static var pointZero : Point = new Point(0, 0);
    
    public function new()
    {
    }
}


