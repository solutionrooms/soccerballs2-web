package editorPackage;

import flash.utils.Dictionary;

/**
	 * ...
	 * @author 
	 */
class GameLayers
{
    private static var layers : Array<GameLayer>;
    private static var nameDictionary : Dictionary;
    
    public function new()
    {
    }
    
    public static function GetZPosByName(name : String) : Float
    {
        if (Reflect.field(nameDictionary, name) == null)
        {
            return 0;
        }
        return Reflect.field(nameDictionary, name).zpos;
    }
    public static function GetByName(name : String) : GameLayer
    {
        if (Reflect.field(nameDictionary, name) == null)
        {
            return null;
        }
        return Reflect.field(nameDictionary, name);
    }
    public static function InitOnce(x : FastXML)
    {
        layers = new Array<GameLayer>();
        nameDictionary = new Dictionary();
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
                gl = layers[i];
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

