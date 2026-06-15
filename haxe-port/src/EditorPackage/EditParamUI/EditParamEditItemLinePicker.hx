package editorPackage.editParamUI;

import editorPackage.EditableObjectBase;
import editorPackage.EdLine;
import editorPackage.ObjParameter;
import editorPackage.PhysEditor;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import uIPackage.UI;

/**
	 * ...
	 * @author
	 */
class EditParamEditItemLinePicker extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemList();
        
        mc.editorItem = this;
        
        (untyped mc).displayText.text = op.name;
        mc.inputText.text = op.value;
        
        (untyped mc).displayText.mouseEnabled = false;
        
        
        mc.inputText.addEventListener(TextEvent.TEXT_INPUT, TextInputDone, false, 0, true);
        mc.inputText.addEventListener(KeyboardEvent.KEY_DOWN, TextInputKeyDown, false, 0, true);
        mc.inputText.addEventListener(FocusEvent.FOCUS_OUT, TextInputLoseFocus, false, 0, true);
        
        mc.addEventListener(MouseEvent.ROLL_OVER, OnRollOver, false, 0, true);
        mc.addEventListener(MouseEvent.ROLL_OUT, OnRollOut, false, 0, true);
        
        UI.AddButton(mc.buttonElipsis, ElipsisPressed);
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    public function OnRollOut(e : MouseEvent)
    {
        var g : Graphics = mc.graphics;
        g.clear();
    }
    public function OnRollOver(e : MouseEvent)
    {
        var obj : EditableObjectBase = PhysEditor.GetAnyObjectById(mc.inputText.text);
        if (obj != null)
        {
            var x1 : Float = obj.GetCentreHandle().x - PhysEditor.scrollX;
            var y1 : Float = obj.GetCentreHandle().y - PhysEditor.scrollY;
            var r : Rectangle = mc.getRect(null);
            var p : Point = mc.localToGlobal(new Point(r.right + 3, (r.top + r.bottom) * 0.5));
            var g : Graphics = mc.graphics;
            g.clear();
            g.lineStyle(3, 0xffffff, 1);
            g.moveTo(p.x, p.y);
            g.lineTo(x1, y1);
        }
    }
    public function ElipsisPressed(e : MouseEvent)
    {
        PhysEditor.oldEditMode = PhysEditor.editMode;
        PhysEditor.editModeObj_PickLineForLink.returnFunction = PickLineReturnFunction;
        PhysEditor.SetEditMode(PhysEditor.editMode_PickLineForLink, false);
        PhysEditor.CursorText_Set("Pick Line");
    }
    public function PickLineReturnFunction(_EdLine : EdLine)
    {
        var id : String = "";
        if (_EdLine != null)
        {
            id = PhysEditor.GetOrCreateUniqueLineID(_EdLine);
        }
        mc.inputText.text = id;
        CopyValueToParameter();
        
        PhysEditor.SetEditMode(PhysEditor.oldEditMode, false);
        PhysEditor.CursorText_Set("");
    }
    
    
    public function TextInputLoseFocus(e : FocusEvent)
    {
        PhysEditor.isEntering = false;
        CancelParameter();
    }
    public function TextInputKeyDown(e : KeyboardEvent)
    {
        PhysEditor.isEntering = true;
        var code : Int = e.keyCode;
        if (code == KeyReader.KEY_ENTER)
        {
            Utils.print("Entered");
            PhysEditor.isEntering = false;
            CopyValueToParameter();
            
            mc.stage.focus = null;
        }
    }
    public function TextInputDone(e : TextEvent)
    {
        Utils.print("TextInputDone " + e.text);
    }
}


