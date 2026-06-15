package editorPackage;

import editorPackage.ObjParameters;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.Sound;
import flash.media.SoundChannel;

/**
	 * ...
	 * @author ...
	 */
class EdObj extends EditableObjectBase
{
    public var instanceName : String;
    
    public var initFunctionParams : String;
    public var typeName : String;
    public var x : Float;
    public var y : Float;
    public var rot : Float;
    public var scale : Float;
    
    public var sortZ : Float;
    public var frame : Float;
    
    
    public function new()
    {
        super();
        classType = "obj";
        scale = 1;
        
        instanceName = "";
        typeName = "";
        x = y = 0;
    }
    
    
    public function GetParameterListForExport() : String
    {
        var exportStr : String = "";
        
        var po : PhysObj = Game.objectDefs.FindByName(typeName);
        
        for (i in 0...po.instanceParams.length)
        {
            var s : String = po.instanceParams[i];
            exportStr += s + "=";
            var s1 : String = objParameters.GetValueString(s);
            exportStr += s1;
            if (i != po.instanceParams.length - 1)
            {
                exportStr += ",";
            }
        }
        return exportStr;
    }
    
    public function Clone() : EdObj
    {
        var clone : EdObj = new EdObj();
        
        clone.classType = classType;
        clone.instanceName = instanceName;
        
        clone.typeName = typeName;
        clone.x = x;
        clone.y = y;
        clone.rot = rot;
        clone.scale = scale;
        clone.id = id;
        clone.objParameters = objParameters.Clone();
        
        return clone;
    }
    
    
    
    
    
    override public function RenderHighlighted(highlightType : Int) : Void
    {
        var po : PhysObj = Game.objectDefs.FindByName(typeName);
        var p : Point = PhysEditor.GetMapPos(Std.int(x), Std.int(y));
        
        
        if (highlightType == EditableObjectBase.HIGHLIGHT_HOVER)
        {
            var ct : ColorTransform = new ColorTransform(1, 1, 1, 1, 255, 0, 0, 0);
            PhysObj.RenderAt(po, p.x, p.y, rot, scale * PhysEditor.zoom, PhysEditor.screenBD, PhysEditor.linesScreen.graphics, true, null, null, ct);
        }
        else if (highlightType == EditableObjectBase.HIGHLIGHT_SELECTED)
        {
            var ct : ColorTransform = new ColorTransform(1, 1, 1, 1, 128, 128, 128, 0);
            PhysObj.RenderAt(po, p.x, p.y, rot, scale * PhysEditor.zoom, PhysEditor.screenBD, PhysEditor.linesScreen.graphics, true, null, null, ct);
        }
    }
    
    override public function Render() : Void
    {
        var po : PhysObj = Game.objectDefs.FindByName(typeName);
        if (po != null)
        {
            var layer : Int = GetCurrentLayer();
            if (EditorLayers.IsVisible(layer) == true)
            {
                if (po.editorRenderFunctionName != null)
                {
                    var renderer : EditorGameRenderer = new EditorGameRenderer();
                    Reflect.callMethod(renderer, Reflect.field(renderer, po.editorRenderFunctionName), [po, this]);
                }
                else
                {
                    var p : Point = PhysEditor.GetMapPos(Std.int(x), Std.int(y));
                    PhysObj.RenderAt(po, p.x, p.y, rot, scale * PhysEditor.zoom, PhysEditor.screenBD, PhysEditor.linesScreen.graphics, true);
                }
            }
        }
    }
    
    
    override public function GetEditorHoverName() : String
    {
        return "OBJ: " + typeName;
    }
    
    override public function MoveBy(_x : Float, _y : Float) : Void
    {
        x += _x;
        y += _y;
        PhysEditor.editModeObj_Joints.UpdateJoints_ObjectMoved(id, _x, _y);
    }
    
    override public function RotateBy(cx : Float, cy : Float, da : Float) : Void
    {
        rot += Utils.RadToDeg(da);
        
        var dx : Float = x;
        var dy : Float = y;
        
        
        var m : Matrix = new Matrix();
        m.rotate(da);
        var p : Point = new Point(x - cx, y - cy);
        p = m.transformPoint(p);
        x = cx + p.x;
        y = cy + p.y;
        
        dx = x - dx;
        dy = y - dy;
    }
    
    
    override public function GetCentreHandle() : Point
    {
        return new Point(x, y);
    }
    
    
    override public function HitTestRectangle(r : Rectangle) : Bool
    {
        if (r.containsPoint(new Point(x, y)))
        {
            return true;
        }
        return false;
    }
    
    override public function Duplicate() : EditableObjectBase
    {
        var dup : EditableObjectBase = try cast(Clone(), EditableObjectBase) catch(e:Dynamic) null;
        CopyBaseToDuplicate(dup);
        return dup;
    }
}







