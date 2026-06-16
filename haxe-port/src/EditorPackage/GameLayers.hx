package editorPackage;

import flash.utils.Dictionary;

/**
	 * ...
	 * @author
	 */
class GameLayers
{
    public static var layers : Array<GameLayer>;
    public static var nameDictionary : Dictionary<Dynamic, Dynamic>;
    
    public function new()
    {
    }
    
    // nameDictionary is written via array access (nameDictionary[gl.name]=gl in InitOnce); as3hx
    // converted these reads to Reflect.field, which doesn't interoperate with array writes on a
    // Map-backed Dictionary. Use consistent array access.
    public static function GetZPosByName(name : String) : Float
    {
        if (nameDictionary[name] == null)
        {
            return 0;
        }
        return nameDictionary[name].zpos;
    }
    public static function GetByName(name : String) : GameLayer
    {
        if (nameDictionary[name] == null)
        {
            return null;
        }
        return nameDictionary[name];
    }
    public static function InitOnce(x : FastXML)
    {
        layers = [];
        nameDictionary = new Dictionary<Dynamic, Dynamic>();
        for (i in 0...x.nodes.gamelayer.length())
        {
            var lx : FastXML = x.nodes.gamelayer.get(i);
            var gl : GameLayer = new GameLayer();
            gl.FromXML(lx);
            layers.push(gl);
            nameDictionary[gl.name] = gl;
        }
        
        if (layers.length != 0)
        {
            var s : String = "";
            for (i in 0...layers.length)
            {
                var gl : GameLayer = layers[i];
                s += gl.name;
                if (i != layers.length - 1)
                {
                    s += ",";
                }
            }
            ObjectParameters.AddParam("game_layer", "list", layers[0].name, s);
        }
    }
}


