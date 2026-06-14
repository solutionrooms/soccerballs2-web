
/**
	 * ...
	 * @author
	 */
class GrassItem
{
    private var origx : Float;
    private var origy : Float;
    private var xpos : Float;
    private var ypos : Float;
    private var gf : GrassFrame;
    private var visible : Bool;
    private var rot : Float;
    private var timer : Int;
    private var frameIndex : Int;
    
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


