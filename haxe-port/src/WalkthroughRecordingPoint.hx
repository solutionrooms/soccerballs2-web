
/**
	 * ...
	 * @author
	 */
class WalkthroughRecordingPoint
{
    public var x : Int = 0;
    public var y : Int = 0;
    public var mouseButton : Bool;
    public var time : Int = 0;
    
    public function new(_x : Int, _y : Int, _button : Bool, _time : Int)
    {
        x = _x;
        y = _y;
        mouseButton = _button;
        time = _time;
    }
    
    public function Clone() : WalkthroughRecordingPoint
    {
        var p : WalkthroughRecordingPoint = new WalkthroughRecordingPoint(x, y, mouseButton, time);
        return p;
    }
}


