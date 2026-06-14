
/**
	 * ...
	 * @author
	 */
class WalkthroughRecording
{
    private var levelName : String;
    private var list : Array<WalkthroughRecordingPoint>;
    private var time : Int;
    private var playbackPos : Int;
    
    public function new(_levelName : String)
    {
        levelName = _levelName;
        list = new Array<WalkthroughRecordingPoint>();
        time = 0;
    }
    
    public function Add(_x : Int, _y : Int, _button : Bool)
    {
        var p : WalkthroughRecordingPoint = new WalkthroughRecordingPoint(_x, _y, _button, time);
        list.push(p);
        time++;
    }
    
    public function StartPlayback()
    {
        playbackPos = 0;
    }
    public function HasFinished() : Bool
    {
        if (playbackPos >= list.length - 1)
        {
            return true;
        }
        return false;
    }
    public function GetNextPoint() : WalkthroughRecordingPoint
    {
        if (list.length == 0)
        {
            return new WalkthroughRecordingPoint(0, 0, false, 0);
        }
        var pos : Int = playbackPos;
        if (pos < 0)
        {
            pos = 0;
        }
        if (pos >= list.length)
        {
            pos = as3hx.Compat.parseInt(list.length - 1);
        }
        
        var p : WalkthroughRecordingPoint = list[pos];
        playbackPos++;
        return p;
    }
    
    public function ExportXML()
    {
        var sss : String = "";
        
        sss += "<recording level=\"" + levelName + "\"";
        sss += " poss=\"";
        
        var i : Int = 0;
        for (p in list)
        {
            var b : Int = 0;
            if (p.mouseButton)
            {
                b = 1;
            }
            sss += p.x + "," + p.y + "," + b;
            if (i != list.length - 1)
            {
                sss += ",";
            }
            i++;
        }
        sss += "\" />";
        sss += "\n";
        
        Utils.print(sss);
        ExternalData.OutputString(sss);
    }
}


