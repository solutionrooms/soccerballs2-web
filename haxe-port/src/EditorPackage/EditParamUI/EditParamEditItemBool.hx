package editorPackage.editParamUI;

import editorPackage.ObjParameter;
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
class EditParamEditItemBool extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemBool();
        
        mc.editorItem = this;
        
        mc.displayText.text = op.name;
        
        mc.displayText.mouseEnabled = false;
        
        
        UI.AddBarebonesMCButton(mc.buttonTrue, TruePressed);
        UI.AddBarebonesMCButton(mc.buttonFalse, FalsePressed);
        
        UpdateButtons();
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    private function UpdateButtons()
    {
        mc.buttonTrue.highlight.visible = false;
        mc.buttonFalse.highlight.visible = false;
        
        if (op.value == "true")
        {
            mc.buttonTrue.highlight.visible = true;
        }
        else
        {
            mc.buttonFalse.highlight.visible = true;
        }
    }
    
    private function TruePressed(e : MouseEvent)
    {
        op.value = "true";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
    private function FalsePressed(e : MouseEvent)
    {
        op.value = "false";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
}


