
/**
	 * ...
	 * @author ...
	 */
class XmlHelper
{
    
    public function new()
    {
    }
    
    public static function GetAttrString(x : Dynamic, defaultvalue : String = "") : String
    {
        var val : String = defaultvalue;
        if (x != null)
        {
            val = Std.string(x);
        }
        return val;
    }
    public static function GetAttrNumber(x : Dynamic, defaultvalue : Float = 0) : Float
    {
        var val : Float = defaultvalue;
        if (x != null)
        {
            var s : String = Std.string(x);
            val = as3hx.Compat.parseFloat(x);
        }
        return val;
    }
    
    public static function GetAttrInt(x : Dynamic, defaultvalue : Int = 0) : Int
    {
        var val : Int = defaultvalue;
        if (x != null)
        {
            val = as3hx.Compat.parseInt(x);
        }
        return as3hx.Compat.parseInt(val);
    }
    public static function GetAttrBoolean(x : Dynamic, defaultvalue : Bool = false) : Bool
    {
        var val : Bool = defaultvalue;
        if (x != null && x != null)
        {
            val = false;
            var s : String = Std.string(x);
            s = s.toLowerCase();
            if (x == "true")
            {
                val = true;
            }
        }
        return val;
    }
    
    
    public static function Attr(name : String, value : Dynamic, preSpace : Bool = true) : String
    {
        if (value == null)
        {
            value = "null";
        }
        var s : String = "";
        if (preSpace)
        {
            s += " ";
        }
        s += name + "=\"";
        s += Std.string(value);
        s += "\"";
        return s;
    }
}


