
/**
	 * ...
	 * @author
	 */
class WalkthroughRecordingPoint
{
    private var x : Int;
    private var y : Int;
    private var mouseButton : Bool;
    private var time : Int;
    
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


