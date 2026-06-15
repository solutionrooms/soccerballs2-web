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
class EditParamEditItemList extends EditParamEditItemBase
{
    public var popup : MovieClip;
    public var popupList : Array<Dynamic>;
    
    public function new()
    {
        super();
    }
    
    
    override public function Setup(_op : ObjParameter, _parent : MovieClip = null)
    {
        super.Setup(_op, _parent);
        
        var s : String = op.name + " : " + op.value;
        
        mc = new EditorEditItemList();
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = Std.string(op.name);
        (untyped mc).inputText.text = Std.string(op.value);
        
        (untyped mc).displayText.mouseEnabled = false;
        (untyped mc).inputText.mouseEnabled = false;
        
        UI.AddButton((untyped mc).buttonElipsis, ElipsisPressed);
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    public function ElipsisPressed(e : MouseEvent)
    {
        InitListPopup();
    }
    
    public function CloseListPopup()
    {
        mc.parent.removeChild(popup);
        popup = null;
    }
    public function InitListPopup()
    {
        Utils.print("InitListPopup");
        popup = new MovieClip();
        popup.graphics.clear();
        popup.graphics.beginFill(0x0, 0.5);
        popup.graphics.drawRect(-1000, -1000, Defs.displayarea_w + 1000, Defs.displayarea_h + 1000);
        popup.graphics.endFill();
        
        popupList = [];
        
        var ob : ObjParam = ObjectParameters.GetObjectParamByName(op.name);
        
        var y : Int = 10;
        for (i in 0...ob.valueList.length)
        {
            var itemString : String = ob.valueList[i];
            
            var item : MovieClip = new EditorEditItemListItem();
            (untyped item).displayText.text = Std.string(itemString);
            (untyped item).listIndex = i;
            item.buttonMode = true;
            item.useHandCursor = true;
            item.addEventListener(MouseEvent.CLICK, PopupClicked, false, 0, true);
            
            (untyped item).displayBox.visible = false;
            
            (untyped item).displayText.mouseEnabled = false;
            (untyped item).highlight.visible = false;
            if (itemString == op.value)
            {
                (untyped item).highlight.visible = true;
            }
            
            popupList.push(item);
            popup.addChild(item);
            
            item.x = 10;
            item.y = y;
            y = Std.int(y + item.height);
        }
        mc.parent.addChild(popup);
    }
    
    public function PopupClicked(e : MouseEvent)
    {
        var item : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        Utils.print("pressed " + (untyped item).listIndex);
        CloseListPopup();
        
        (untyped mc).inputText.text = (untyped item).displayText.text;
        CopyValueToParameter();
    }
}


