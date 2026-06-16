import flash.display.MovieClip;

/**
	 * ...
	 * @author
	 */
class HintPopup
{
    public var text : String;
    public var shown : Bool;
    
    public var timer : Int = 0;
    public var active : Bool;
    public var mc : MovieClip;
    
    public function new(_text : String)
    {
        text = _text;
        shown = false;
        active = false;
        timer = 0;
    }
    
    public function Clone() : HintPopup
    {
        var clone : HintPopup = new HintPopup("");
        clone.text = Std.string(text);
        return clone;
    }
}


