package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import editorPackage.PhysEditor;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.TextEvent;
import uIPackage.UI;

/**
	 * ...
	 * @author 
	 */
class EditParamEditItemText extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemText();
        
        mc.editorItem = this;
        
        mc.displayText.text = op.name;
        mc.inputText.text = op.value;
        
        mc.displayText.mouseEnabled = false;
        
        mc.inputText.addEventListener(TextEvent.TEXT_INPUT, TextInputDone, false, 0, true);
        mc.inputText.addEventListener(KeyboardEvent.KEY_DOWN, TextInputKeyDown, false, 0, true);
        mc.inputText.addEventListener(FocusEvent.FOCUS_OUT, TextInputLoseFocus, false, 0, true);
        
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    
    private function TextInputLoseFocus(e : FocusEvent)
    {
        PhysEditor.isEntering = false;
        CopyValueToParameter();
    }
    private function TextInputKeyDown(e : KeyboardEvent)
    {
        PhysEditor.isEntering = true;
        
        var code : Int = e.keyCode;
        if (code == KeyReader.KEY_ENTER)
        {
            Utils.print("Entered");
            CopyValueToParameter();
            PhysEditor.isEntering = false;
            mc.stage.focus = null;
        }
    }
    private function TextInputDone(e : TextEvent)
    {
        Utils.print("TextInputDone " + e.text);
    }
}

