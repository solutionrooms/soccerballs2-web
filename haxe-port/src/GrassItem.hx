
/**
	 * ...
	 * @author
	 */
class GrassItem
{
    public var origx : Float;
    public var origy : Float;
    public var xpos : Float;
    public var ypos : Float;
    public var gf : GrassFrame;
    public var visible : Bool;
    public var rot : Float;
    public var timer : Int = 0;
    public var frameIndex : Int = 0;
    
    public function new(_x : Float, _y : Float, _gf : GrassFrame, _frameIndex : Int)
    {
        origx = _x;
        xpos = _x;
        origy = _y;
        ypos = _y;
        gf = _gf;
        visible = true;
        rot = 0;
        timer = 0;
        frameIndex = _frameIndex;
    }
    
    public function Clone() : GrassItem
    {
        var clone : GrassItem = new GrassItem(xpos, ypos, gf, frameIndex);
        clone.visible = visible;
        return clone;
    }
}


