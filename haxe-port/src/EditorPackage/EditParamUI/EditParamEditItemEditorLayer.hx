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
class EditParamEditItemEditorLayer extends EditParamEditItemBase
{
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemEditorLayer();
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = op.name;
        (untyped mc).displayText.mouseEnabled = false;
        
        
        UI.AddBarebonesMCButton((untyped mc).button1, Pressed1);
        UI.AddBarebonesMCButton((untyped mc).button2, Pressed2);
        UI.AddBarebonesMCButton((untyped mc).button3, Pressed3);
        UI.AddBarebonesMCButton((untyped mc).button4, Pressed4);
        
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
        (untyped mc.button1).highlight.visible = false;
        (untyped mc.button2).highlight.visible = false;
        (untyped mc.button3).highlight.visible = false;
        (untyped mc.button4).highlight.visible = false;
        
        if (op.value == "1")
        {
            (untyped mc.button1).highlight.visible = true;
        }
        if (op.value == "2")
        {
            (untyped mc.button2).highlight.visible = true;
        }
        if (op.value == "3")
        {
            (untyped mc.button3).highlight.visible = true;
        }
        if (op.value == "4")
        {
            (untyped mc.button4).highlight.visible = true;
        }
    }
    
    public function Pressed1(e : MouseEvent)
    {
        op.value = "1";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
    public function Pressed2(e : MouseEvent)
    {
        op.value = "2";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
    public function Pressed3(e : MouseEvent)
    {
        op.value = "3";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
    public function Pressed4(e : MouseEvent)
    {
        op.value = "4";
        EditParams.DoChangedCallback(op);
        UpdateButtons();
    }
}


