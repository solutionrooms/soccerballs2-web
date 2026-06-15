package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import editorPackage.PhysEditor;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import uIPackage.UI;

/**
	 * ...
	 * @author
	 */
class EditParamEditItemNumber extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemNumber();
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = Std.string(op.name);
        (untyped mc).inputText.text = Std.string(op.value);
        
        (untyped mc).displayText.mouseEnabled = false;
        
        
        (untyped mc).inputText.addEventListener(TextEvent.TEXT_INPUT, TextInputDone, false, 0, true);
        (untyped mc).inputText.addEventListener(KeyboardEvent.KEY_DOWN, TextInputKeyDown, false, 0, true);
        (untyped mc).inputText.addEventListener(FocusEvent.FOCUS_OUT, TextInputLoseFocus, false, 0, true);
        
        UI.AddButton((untyped mc).buttonPlus, PlusPressed);
        UI.AddButton((untyped mc).buttonMinus, MinusPressed);
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    
    public function PlusPressed(e : MouseEvent)
    {
        var ob : ObjParam = ObjectParameters.GetObjectParamByName((untyped mc).displayText.text);
        var inc : Float = ob.number_step;
        var val : Float = as3hx.Compat.parseFloat((untyped mc).inputText.text);
        val += inc;
        (untyped mc).inputText.text = Std.string(val);
        
        CheckRange();
        CopyValueToParameter();
    }
    
    public function MinusPressed(e : MouseEvent)
    {
        var ob : ObjParam = ObjectParameters.GetObjectParamByName((untyped mc).displayText.text);
        var inc : Float = -ob.number_step;
        var val : Float = as3hx.Compat.parseFloat((untyped mc).inputText.text);
        val += inc;
        (untyped mc).inputText.text = Std.string(val);
        
        CheckRange();
        
        CopyValueToParameter();
    }
    
    public function CheckRange()
    {
        var val : Float = as3hx.Compat.parseFloat((untyped mc).inputText.text);
        var ob : ObjParam = ObjectParameters.GetObjectParamByName((untyped mc).displayText.text);
        if (ob.number_useRangeMin)
        {
            if (val < ob.number_min)
            {
                val = ob.number_min;
            }
        }
        if (ob.number_useRangeMax)
        {
            if (val > ob.number_max)
            {
                val = ob.number_min;
            }
        }
        (untyped mc).inputText.text = Std.string(val);
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
            
            
            CheckRange();
            
            CopyValueToParameter();
            
            mc.stage.focus = null;
        }
    }
    public function TextInputDone(e : TextEvent)
    {
        Utils.print("TextInputDone " + e.text);
    }
}


