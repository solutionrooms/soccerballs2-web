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
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = op.name;
        
        (untyped mc).displayText.mouseEnabled = false;
        
        
        UI.AddBarebonesMCButton((untyped mc).buttonTrue, TruePressed);
        UI.AddBarebonesMCButton((untyped mc).buttonFalse, FalsePressed);
        
        UpdateButtons();
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    public function UpdateButtons()
    {
        (untyped mc.buttonTrue).highlight.visible = false;
        (untyped mc.buttonFalse).highlight.visible = false;
        
        if (op.value == "true")
        {
            (untyped mc.buttonTrue).highlight.visible = true;
        }
        else
        {
            (untyped mc.buttonFalse).highlight.visible = true;
        }
    }
    
    public function TruePressed(e : MouseEvent)
    {
        op.value = "true";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
    public function FalsePressed(e : MouseEvent)
    {
        op.value = "false";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
}


