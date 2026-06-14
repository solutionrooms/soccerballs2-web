import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;

/**
	 * ...
	 * @author 
	 */
class Vars
{
    private static var list : Array<Var>;
    
    
    
    
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        if (Game.load_vars_data == false)
        {
            var xml : FastXML = try cast(new FastXML(new ClassVars()), FastXML) catch(e:Dynamic) null;
            cast((xml), DecodeXML);
        }
        else
        {
            ReloadXML();
        }
    }
    
    private static var xmlLoader : URLLoader;
    
    public static function ReloadXML()
    {
        if (Game.load_vars_data)
        {
            FastXML.ignoreWhitespace = true;
            
            xmlLoader = new URLLoader();
            xmlLoader.addEventListener(Event.COMPLETE, XMLLoaded, false, 0, true);
            xmlLoader.load(new URLRequest("VarsData.xml"));
        }
    }
    
    public static function XMLLoaded(e : Event)
    {
        xmlLoader.removeEventListener(Event.COMPLETE, XMLLoaded);
        
        var xml : FastXML = try cast(new FastXML(e.target.data), FastXML) catch(e:Dynamic) null;
        cast((xml), DecodeXML);
    }
    private static function DecodeXML(_xml : FastXML)
    {
        FastXML.ignoreWhitespace = true;
        list = new Array<Var>();
        var i : Int;
        var xml : FastXML = _xml;
        for (i in 0...xml.nodes.variable.length())
        {
            var vx : FastXML = xml.nodes.variable.get(i);
            var v : Var = new Var();
            v.name = vx.att.name;
            v.type = vx.att.type;
            v.valueString = vx.att.value;
            list.push(v);
        }
    }
    
    public static function TraceAll()
    {
        for (v in list)
        {
            v.Trace();
        }
    }
    
    
    
    public static function GetVar(name : String) : Var
    {
        for (v in list)
        {
            if (name == v.name)
            {
                return v;
            }
        }
        return null;
    }
    public static function GetVarAsString(name : String) : String
    {
        var v : Var = cast((name), GetVar);
        return v.valueString;
    }
    public static function GetVarAsNumber(name : String) : Float
    {
        var v : Var = cast((name), GetVar);
        return as3hx.Compat.parseFloat(v.valueString);
    }
    public static function GetVarAsInt(name : String) : Int
    {
        var v : Var = cast((name), GetVar);
        return as3hx.Compat.parseInt(v.valueString);
    }
    private static var Vars_static_initializer = {
        if (Game.load_vars_data == false)
        {
            [Embed(source = "../bin/VarsData.xml", mimeType = "application/octet-stream")];
            private;static;var class_vars : Class<Dynamic>;
        };
        true;
    }

}

