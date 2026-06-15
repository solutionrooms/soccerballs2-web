import flash.geom.Rectangle;

/**
	 * ...
	 * @author
	 */
class GrassSegment
{
    public var list : Array<GrassItem>;
    public var x0 : Float;
    public var x1 : Float;
    public var y0 : Float;
    public var y1 : Float;
    public var boundingRect : Rectangle;
    
    public function new()
    {
        list = [];
    }
}


