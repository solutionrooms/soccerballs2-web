import flash.geom.Point;

/**
	 * ...
	 * @author LongAnimals
	 */
class Camera
{
    public var x : Float;
    public var y : Float;
    
    public var oldX : Float;
    public var oldY : Float;
    public var cx : Float;
    public var cy : Float;
    public var maxX : Float;
    public var maxY : Float;
    public var minX : Float;
    public var minY : Float;
    public var toDX : Float;
    public var toDY : Float;
    public var toX : Float;
    public var toY : Float;
    public var scale : Float;
    
    
    public function new()
    {
        Reset();
    }
    
    public var savedx : Float;
    public var savedy : Float;
    public function PushPos()
    {
        savedx = x;
        savedy = y;
    }
    public function PopPos()
    {
        x = savedx;
        y = savedy;
    }
    
    public function ResetBounds()
    {
        minX = 12345678;
        maxX = 12345678;
        minY = 12345678;
        maxY = 12345678;
    }
    
    public function UpdatePosition(px : Float, py : Float, linv : Point)
    {
        oldX = x;
        oldY = y;
        
        
        var dx : Float;
        var dy : Float;
        
        var xoff : Float = 320;
        var yoff : Float = 240;
        
        
        cx = px;
        cy = py;
        
        var ang : Float = Math.atan2(linv.y, linv.x);
        var speed : Float = Utils.GetLength(linv.x, linv.y);
        
        if (speed < 3)
        {
            dx = 0;
            dy = 0;
        }
        else
        {
            speed = Utils.LimitNumber(3, 10, speed);
            var dist : Float = Utils.ScaleTo(0, 150, 0, 30, speed);
            dx = Math.cos(ang) * dist;
            dy = Math.sin(ang) * dist;
        }
        
        toDX += (dx - toDX) * 0.1;
        toDY += (dy - toDY) * 0.1;
        
        x = (px - xoff) + toDX;
        y = (py - yoff) + toDY;
        
        
        
        
        
        
        if (minX != 12345678 && minY != 12345678)
        {
            if (x < minX)
            {
                x = minX;
            }
            if (y < minY)
            {
                y = minY;
            }
            if (x > (maxX - Defs.displayarea_w))
            {
                x = (maxX - Defs.displayarea_w);
            }
            if (y > (maxY - Defs.displayarea_h))
            {
                y = (maxY - Defs.displayarea_h);
            }
        }
        
        scale = 1;
    }
    public function Reset()
    {
        x = 0;
        y = 0;
        oldX = 0;
        oldY = 0;
        cx = 0;
        cy = 0;
        maxX = minX = 0;
        maxY = minY = 0;
        toDX = toDY = 0;
        scale = 1;
        toX = 0;
        toY = 0;
    }
    
    public static var shakeCamToX : Float = 0;
    public static var shakeCamToY : Float = 0;
    public static var shakeCamX : Float = 0;
    public static var shakeCamY : Float = 0;
    public static var shakeCamDX : Float = 0;
    public static var shakeCamDY : Float = 0;
    public static var shakeCamTimer : Int = 50;
    public static var shakeCamTimerMax : Int = 50;
    public static function UpdateShakeCam(speed : Float) : Void
    {
        shakeCamTimer--;
        if (shakeCamTimer <= 0)
        {
            shakeCamTimer = Utils.RandBetweenInt(5, 20);
            shakeCamTimerMax = shakeCamTimer;
            
            
            var dist : Float = Utils.ScaleTo(2, 20, 0, 30, speed);
            
            shakeCamToX = Utils.RandBetweenFloat(-dist, dist);
            shakeCamToY = Utils.RandBetweenFloat(-dist, dist);
            
            shakeCamDX = (shakeCamToX - shakeCamX) / shakeCamTimer;
            shakeCamDY = (shakeCamToY - shakeCamY) / shakeCamTimer;
        }
        
        
        shakeCamX += shakeCamDX;
        shakeCamY += shakeCamDY;
    }
}


