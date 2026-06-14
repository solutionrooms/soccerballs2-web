
/**
	 * ...
	 * @author
	 */
class WalkthroughRecordings
{
    private static var list : Array<WalkthroughRecording>;
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        list = new Array<WalkthroughRecording>();
        LoadXML();
    }
    
    public static function GetByLevelName(name : String) : WalkthroughRecording
    {
        for (r in list)
        {
            if (r.levelName == name)
            {
                return r;
            }
        }
        return null;
    }
    public static function AddRecording(r : WalkthroughRecording)
    {
        r.ExportXML();
        var i : Int = 0;
        for (rr in list)
        {
            if (rr.levelName == r.levelName)
            {
                list[i] = r;
                
                return;
            }
            i++;
        }
        list.push(r);
    }
    
    public static function LoadXML()
    {
        var i : Int;
        var j : Int;
        var x : FastXML = ExternalData.levelsXml;
        var num : Int = x.nodes.recording.length();
        for (i in 0...x.nodes.recording.length())
        {
            var rx : FastXML = x.nodes.recording.get(i);
            var r : WalkthroughRecording = new WalkthroughRecording(rx.att.level);
            var poss : String = rx.att.poss;
            var a : Array<Dynamic> = poss.split(",");
            var numPositions : Int = as3hx.Compat.parseInt(a.length / 3);
            
            
            for (j in 0...numPositions)
            {
                var xp : Int = a[(j * 3) + 0];
                var yp : Int = a[(j * 3) + 1];
                var b : Int = a[(j * 3) + 2];
                var mb : Bool = false;
                if (b == 1)
                {
                    mb = true;
                }
                r.Add(xp, yp, mb);
            }
            list.push(r);
        }
        
        
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            var gotit : Bool = false;
            for (r in list)
            {
                if (r.levelName == l.name)
                {
                    gotit = true;
                }
            }
            if (gotit == false)
            {
            }
        }
    }
    public static function ExportXML()
    {
        var sss : String = "";
        
        for (r in list)
        {
            sss += "<recording level=\"" + r.levelName + "\"";
            sss += " poss=\"";
            
            var i : Int = 0;
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(r),list) type: null */ in r.list)
            {
                var b : Int = 0;
                if (p.mouseButton)
                {
                    b = 1;
                }
                sss += p.x + "," + p.y + "," + b;
                if (i != r.list.length - 1)
                {
                    sss += ",";
                }
                i++;
            }
            sss += "\" />";
            sss += "\n";
        }
        Utils.print(sss);
        ExternalData.OutputString(sss);
    }
}


