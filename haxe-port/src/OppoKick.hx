
/**
	 * ...
	 * @author
	 */
class OppoKick
{
    public var frame : Int = 0;
    public var xoff : Int = 0;
    public var yoff : Int = 0;
    public var force : Float;
    
    public function new(_frame : Int, _x : Int, _y : Int, _force : Float = 1)
    {
        frame = _frame;
        xoff = _x;
        yoff = _y;
        force = _force;
    }
}


