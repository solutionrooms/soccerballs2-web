package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import flash.display.MovieClip;

/**
	 * ...
	 * @author 
	 */
class EditParamEditItemBase
{
    
    private var op : ObjParameter;
    private var parent : MovieClip;
    private var mc : MovieClip;
    private var selected : Bool;
    private var parent_index : Int;
    
    private var x : Float;
    private var y : Float;
    
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
        }if (mc.highlight != null)
        {
            mc.highlight.visible = false;
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

