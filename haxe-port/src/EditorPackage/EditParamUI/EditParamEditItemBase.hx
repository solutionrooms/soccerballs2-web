package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import flash.display.MovieClip;

/**
	 * ...
	 * @author
	 */
class EditParamEditItemBase
{
    
    public var op : ObjParameter;
    public var parent : MovieClip;
    public var mc : MovieClip;
    public var selected : Bool;
    public var parent_index : Int;
    
    public var x : Float;
    public var y : Float;
    
    public function new()
    {
        op = null;
        parent = null;
        parent_index = 0;
        mc = null;
        selected = false;
    }
    
    public function SetPos(_x : Int, _y : Int)
    {
        mc.x = _x;
        mc.y = _y;
    }
    public function MovePos(_x : Int, _y : Int)
    {
        mc.x += _x;
        mc.y += _y;
    }
    
    
    public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        op = _op;
        parent = _parent;
        selected = false;
    }
    public function PostSetup()
    {
        if (parent != null)
        {
            parent.addChild(mc);
        }if ((untyped mc).highlight != null)
        {
            (untyped mc).highlight.visible = false;
        }
    }
    
    public function CancelParameter()
    {
    }
    public function ValidateParameter() : Bool
    {
        return true;
    }
    public function CopyValueToParameter()
    {
        op.value = mc.inputText.text;
        EditParams.DoChangedCallback(op);
    }
}


