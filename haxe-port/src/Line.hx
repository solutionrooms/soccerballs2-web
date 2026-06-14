import flash.geom.Rectangle;

/**
	* ...
	* @author Default
	*/
class Line
{
    public var x0 : Float;
    public var y0 : Float;
    public var x1 : Float;
    public var y1 : Float;
    public var nx : Float;
    public var ny : Float;
    public var dir : Float;
    public var normalDir : Float;
    public var length : Float;
    public var dx : Float;
    public var dy : Float;
    public var udx : Float;
    public var udy : Float;
    public var boundingRect : Rectangle;
    
    public function new(_x0 : Float, _y0 : Float, _x1 : Float, _y1 : Float)
    {
        x0 = _x0;
        y0 = _y0;
        x1 = _x1;
        y1 = _y1;
        CalcNormal();
        CalcBoundingRect();
    }
    
    private function CalcBoundingRect() : Void
    {
        var a : Float;
        var b : Float;
        var c : Float;
        var d : Float;
        
        a = x0;
        b = x1;
        if (a > b)
        {
            a = x1;
            b = x0;
        }
        c = y0;
        d = y1;
        if (c > d)
        {
            c = y1;
            d = y0;
        }
        boundingRect = new Rectangle(a, c, (b - a) + 1, (d - c) + 1);
    }
    
    private function CalcNormal() : Void
    {
        dir = Math.atan2(y1 - y0, x1 - x0);
        normalDir = dir - (Math.PI * 0.5);
        nx = Math.cos(normalDir);
        ny = Math.sin(normalDir);
        
        dx = x1 - x0;
        dy = y1 - y0;
        length = Math.sqrt(dx * dx + dy * dy);
        
        udx = Math.cos(dir);
        udy = Math.sin(dir);
    }
}


