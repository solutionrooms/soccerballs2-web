
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
        // The lenient FastXML returns "" (not null) for a MISSING attribute, so the original
        // `if (x != null)` guard no longer catches it and parseFloat("")=NaN slips through. NaN here
        // poisons shape/joint geometry (Nape asserts "Vec2 components cannot be NaN"; the original
        // Flash Nape silently tolerated it). Treat empty/non-numeric as missing -> default.
        if (x == null) return defaultvalue;
        var s : String = Std.string(x);
        if (s == "") return defaultvalue;
        var val : Float = as3hx.Compat.parseFloat(s);
        return if (Math.isNaN(val)) defaultvalue else val;
    }

    public static function GetAttrInt(x : Dynamic, defaultvalue : Int = 0) : Int
    {
        if (x == null) return defaultvalue;
        var s : String = Std.string(x);
        if (s == "") return defaultvalue; // missing attr (lenient FastXML returns "") -> default
        return as3hx.Compat.parseInt(s);
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


