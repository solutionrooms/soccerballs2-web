package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import editorPackage.PhysEditor;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.geom.Point;
import uIPackage.UI;

/**
	 * ...
	 * @author
	 */
class EditParamEditItemAngle extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemAngle();
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = op.name;
        (untyped mc).inputText.text = op.value;
        
        (untyped mc).displayText.mouseEnabled = false;
        
        
        (untyped mc).inputText.addEventListener(TextEvent.TEXT_INPUT, TextInputDone, false, 0, true);
        (untyped mc).inputText.addEventListener(KeyboardEvent.KEY_DOWN, TextInputKeyDown, false, 0, true);
        (untyped mc).inputText.addEventListener(FocusEvent.FOCUS_OUT, TextInputLoseFocus, false, 0, true);
        
        UI.AddButton((untyped mc).buttonPlus, PlusPressed);
        UI.AddButton((untyped mc).buttonMinus, MinusPressed);
        
        (untyped mc).anglePointer.addEventListener(MouseEvent.MOUSE_DOWN, AngleDown, false, 0, true);
        (untyped mc).anglePointer.addEventListener(MouseEvent.MOUSE_MOVE, AngleDown, false, 0, true);
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    
    public function SetAngleArrow()
    {
        (untyped mc).anglePointer.pointer.rotation = as3hx.Compat.parseFloat((untyped mc).inputText.text) - (Math.PI / 2);
    }
    
    public function AngleDown(e : MouseEvent)
    {
        if (e.buttonDown == false)
        {
            return;
        }
        
        var ang : Float = Math.atan2(e.localY, e.localX);
        
        Utils.print("angle down " + ang);
        
        var degree : Float = Utils.RadToDeg(ang + (Math.PI / 2));
        degree = Math.round(degree);
        (untyped mc).anglePointer.pointer.rotation = degree;
        (untyped mc).inputText.text = degree;
        CopyValueToParameter();
    }
    public function PlusPressed(e : MouseEvent)
    {
        var inc : Float = 1;
        var val : Float = as3hx.Compat.parseFloat((untyped mc).inputText.text);
        val += inc;
        (untyped mc).inputText.text = Std.string(val);
        CopyValueToParameter();
        SetAngleArrow();
    }
    
    public function MinusPressed(e : MouseEvent)
    {
        var inc : Float = -1;
        var val : Float = as3hx.Compat.parseFloat((untyped mc).inputText.text);
        val += inc;
        (untyped mc).inputText.text = Std.string(val);
        CopyValueToParameter();
        SetAngleArrow();
    }
    
    public function TextInputLoseFocus(e : FocusEvent)
    {
        PhysEditor.isEntering = false;
        CopyValueToParameter();
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
            SetAngleArrow();
            
            mc.stage.focus = null;
        }
    }
    public function TextInputDone(e : TextEvent)
    {
        Utils.print("TextInputDone " + e.text);
    }
}


