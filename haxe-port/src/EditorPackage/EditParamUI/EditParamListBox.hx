package editorPackage.editParamUI;

import haxe.Constraints.Function;
import editorPackage.ObjParameter;
import editorPackage.ObjParameters;
import flash.display.MovieClip;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;

/**
	 * ...
	 * @author
	 */
class EditParamListBox extends MovieClip
{
    public var objParameters : ObjParameters;
    public var items : Array<Dynamic>;
    public var closed_function : Function;
    
    public function new()
    {
        super();
        
        closed_function = null;
        addEventListener(MouseEvent.CLICK, PreventPropogationHandler);
        addEventListener(MouseEvent.MOUSE_DOWN, PreventPropogationHandler);
        addEventListener(MouseEvent.MOUSE_UP, PreventPropogationHandler);
        
        addEventListener(KeyboardEvent.KEY_DOWN, TextInputKeyDown, false, 0, true);
        
        
        /*
			var bg:MovieClip = new MovieClip();
			bg.graphics.clear();
			bg.graphics.beginFill(0x0, 0.5);
			bg.graphics.drawRect(0, 0, Defs.displayarea_w, Defs.displayarea_h);
			bg.graphics.endFill();
			addChild(bg);
			*/
        
        items = [];
    }
    
    public function TextInputKeyDown(e : KeyboardEvent)
    {
        var code : Int = e.keyCode;
        if (code == KeyReader.KEY_ESCAPE)
        {
            Utils.print("Closed");
            if (closed_function != null)
            {
                closed_function();
            }
        }
    }
    
    public function PreventPropogationHandler(e : MouseEvent)
    {
        e.stopImmediatePropagation();
    }
    
    public function SetPos(_x : Int, _y : Int)
    {
        x = _x;
        y = _y;
    }
    public function SetParameters(_objParameters : ObjParameters)
    {
        items = [];
        objParameters = _objParameters;
        
        var y : Int = 0;
        
        var i : Int = 0;
        for (op/* AS3HX WARNING could not determine type for var: op exp: EField(EIdent(objParameters),list) type: null */ in objParameters.list)
        {
            var type : String = "undefined";
            var ob : ObjParam = ObjectParameters.GetObjectParamByName(op.name);
            if (ob != null)
            {
                type = ob.type;
            }
            
            var item : EditParamEditItemBase = null;            
            if (type == "text")
            {
                item = new EditParamEditItemText();
            }
            else if (type == "number")
            {
                item = new EditParamEditItemNumber();
            }
            else if (type == "angle")
            {
                item = new EditParamEditItemAngle();
            }
            else if (type == "list")
            {
                item = new EditParamEditItemList();
            }
            else if (type == "materiallist")
            {
                item = new EditParamEditItemMaterialList();
            }
            else if (type == "bool")
            {
                item = new EditParamEditItemBool();
            }
            else if (type == "linelink")
            {
                item = new EditParamEditItemLinePicker();
            }
            else if (type == "editorlayer")
            {
                item = new EditParamEditItemEditorLayer();
            }
            else if (type == "undefined")
            {
                Utils.print("undefined edit item type. ERROR");
            }
            else
            {
                Utils.print("unhandled edit item type: " + ob.type);
                item = try cast(new EditParamEditItemText(), EditParamEditItemBase) catch(e:Dynamic) null;
            }
            
            
            item.Setup(op, this);
            item.parent_index = i;
            
            item.SetPos(0, y);
            
            items.push(item);
            y = Std.int(y + item.mc.height);
            i++;
        }
        
        for (item in items)
        {
            item.MovePos(0, Defs.displayarea_h - 20 - y);
        }
    }
}


