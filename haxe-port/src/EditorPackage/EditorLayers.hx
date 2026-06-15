package editorPackage;

import flash.display.MovieClip;

/**
	 * ...
	 * @author
	 */
class EditorLayers
{
    public static var layers : Array<EditorLayer>;
    public static var layersMC : MovieClip;
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        layers = [];
        layers.push(new EditorLayer(0, "Layer 1"));
        layers.push(new EditorLayer(1, "Layer 2"));
        layers.push(new EditorLayer(2, "Layer 3"));
        layers.push(new EditorLayer(3, "Layer 4"));
        
        layers[0].active = true;
        
        layersMC = new MovieClip();
        var y : Int = 0;
        for (l in layers)
        {
            l.mc.y = y;
            layersMC.addChild(l.mc);
            y += 20;
        }
        UpdateUI();
    }
    
    public static function UpdateUI()
    {
        for (l in layers)
        {
            l.UpdateUI();
        }
    }
    public static function GetContainer() : MovieClip
    {
        return layersMC;
    }
    public static function ShowUI(show : Bool)
    {
    }
    
    public static function GetName(index : Int) : String
    {
        return layers[index].name;
    }
    public static function ToggleVisibility(index : Int)
    {
        layers[index].ToggleVisibility();
    }
    
    public static function ToggleUIVisibility()
    {
        layersMC.visible = (layersMC.visible == false);
    }
    
    public static function SetActive(index : Int)
    {
        for (l in layers)
        {
            l.active = false;
        }
        layers[index].active = true;
    }
    
    
    public static function GetActive() : Int
    {
        for (l in layers)
        {
            if (l.active)
            {
                return as3hx.Compat.parseInt(l.index + 1);
            }
        }
        return 0;
    }
    
    
    public static function ToggleLocked(index : Int)
    {
        layers[index].ToggleLocked();
    }
    public static function IsVisible(index : Int) : Bool
    {
        return layers[index].IsVisible();
    }
}


