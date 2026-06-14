import flash.display.MovieClip;

/**
	 * ...
	 * @author
	 */
class HintPopup
{
    private var text : String;
    private var shown : Bool;
    
    private var timer : Int;
    private var active : Bool;
    private var mc : MovieClip;
    
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
        clone.text = text;
        return clone;
    }
}


