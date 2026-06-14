package editorPackage;

import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author ...
	 */
class EditableObjectBase
{
    public var prev_id : String;
    public var id : String;
    public var objParameters : ObjParameters;
    public var xoff : Float;
    public var yoff : Float;
    public var switchName : String;
    public var classType = "base";
    
    public var sort_zpos : Float;
    
    public function new()
    {
        classType = "base";
        id = "";
        prev_id = "";
        objParameters = new ObjParameters();
        
        xoff = 0;
        yoff = 0;
        switchName = "";
    }
    
    
    public function SetSortPosFromGameLayer()
    {
        sort_zpos = 0;
        if (objParameters.Exists("game_layer"))
        {
            var layerName : String = objParameters.GetValueString("game_layer");
            sort_zpos = GameLayers.GetZPosByName(layerName);
        }
    }
    
    public static inline var HIGHLIGHT_HOVER : Int = 0;
    public static inline var HIGHLIGHT_SELECTED : Int = 1;
    
    public function IsSpline() : Bool
    {
        return objParameters.GetValueBoolean("line_spline");
    }
    
    public function GetCurrentPolyMaterial() : PolyMaterial
    {
        var polyMatName : String = objParameters.GetValueString("line_material");
        var pm : PolyMaterial = PolyMaterials.GetByName(polyMatName);
        return pm;
    }
    public function GetCurrentLayer() : Int
    {
        var layer : Int = 0;
        if (objParameters.GetParam("editor_layer") != "")
        {
            layer = as3hx.Compat.parseInt(objParameters.GetValueInt("editor_layer") - 1);
        }
        return layer;
    }
    
    public function CopyBaseToDuplicate(dup : EditableObjectBase)
    {
        dup.id = "";
        dup.objParameters = objParameters.Clone();
        dup.xoff = xoff;
        dup.yoff = yoff;
        dup.switchName = switchName;
        dup.classType = classType;
    }
    public function Duplicate() : EditableObjectBase
    {
        return null;
    }
    
    public function HitTestRectangle(r : Rectangle) : Bool
    {
        return false;
    }
    
    public function HitTest(x : Int, y : Int) : Bool
    {
        return false;
    }
    
    public function MoveBy(x : Float, y : Float) : Void
    {
    }
    
    public function RotateBy(cx : Float, cy : Float, da : Float) : Void
    {
    }
    
    
    public function Render() : Void
    {
    }
    public function RenderHighlighted(highlightType : Int) : Void
    {
    }
    
    public function GetCentreHandle() : Point
    {
        return new Point(0, 0);
    }
    
    public function GetEditorHoverName() : String
    {
        return id;
    }
}

