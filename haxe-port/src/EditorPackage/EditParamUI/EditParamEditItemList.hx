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
    private var popup : MovieClip;
    private var popupList : Array<Dynamic>;
    
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
        
        mc.displayText.text = op.name;
        mc.inputText.text = op.value;
        
        mc.displayText.mouseEnabled = false;
        mc.inputText.mouseEnabled = false;
        
        UI.AddButton(mc.buttonElipsis, ElipsisPressed);
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    private function ElipsisPressed(e : MouseEvent)
    {
        InitListPopup();
    }
    
    private function CloseListPopup()
    {
        mc.parent.removeChild(popup);
        popup = null;
    }
    private function InitListPopup()
    {
        Utils.print("InitListPopup");
        popup = new MovieClip();
        popup.graphics.clear();
        popup.graphics.beginFill(0x0, 0.5);
        popup.graphics.drawRect(-1000, -1000, Defs.displayarea_w + 1000, Defs.displayarea_h + 1000);
        popup.graphics.endFill();
        
        popupList = new Array<Dynamic>();
        
        var ob : ObjParam = ObjectParameters.GetObjectParamByName(op.name);
        
        var y : Int = 10;
        for (i in 0...ob.valueList.length)
        {
            var itemString : String = ob.valueList[i];
            
            var item : MovieClip = new EditorEditItemListItem();
            item.displayText.text = itemString;
            item.listIndex = i;
            item.buttonMode = true;
            item.useHandCursor = true;
            item.addEventListener(MouseEvent.CLICK, PopupClicked, false, 0, true);
            
            item.displayBox.visible = false;
            
            item.displayText.mouseEnabled = false;
            item.highlight.visible = false;
            if (itemString == op.value)
            {
                item.highlight.visible = true;
            }
            
            popupList.push(item);
            popup.addChild(item);
            
            item.x = 10;
            item.y = y;
            y += item.height;
        }
        mc.parent.addChild(popup);
    }
    
    private function PopupClicked(e : MouseEvent)
    {
        var item : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        Utils.print("pressed " + item.listIndex);
        CloseListPopup();
        
        mc.inputText.text = item.displayText.text;
        CopyValueToParameter();
    }
}

