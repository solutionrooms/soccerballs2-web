package editorPackage.editParamUI;

import editorPackage.ObjParameter;
import editorPackage.PolyMaterial;
import editorPackage.PolyMaterials;
import flash.display.Graphics;
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
class EditParamEditItemMaterialList extends EditParamEditItemBase
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
        
        mc = new EditorEditItemMaterialList();
        
        mc.editorItem = this;
        
        mc.displayText.text = op.name;
        mc.inputText.text = op.value;
        
        mc.displayText.mouseEnabled = false;
        mc.inputText.mouseEnabled = false;
        
        
        UpdateEverything();
        
        UI.AddButton(mc.buttonElipsis, ElipsisPressed);
        
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    private function UpdateEverything()
    {
        mc.displayBox.visible = false;
        
        var polyMaterial : PolyMaterial = PolyMaterials.GetByName(op.value);
        
        if (polyMaterial != null && polyMaterial.graphicName != "")
        {
            var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
            
            var box : MovieClip = new MovieClip();
            var g : Graphics = box.graphics;
            g.beginBitmapFill(dobj.GetBitmapData(polyMaterial.fillFrame), null, true, true);
            g.drawRect(0, 0, mc.displayBox.width, mc.displayBox.height);
            g.endFill();
            
            mc.addChild(box);
            box.x = mc.displayBox.x;
            box.y = mc.displayBox.y;
        }
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
            
            var polyMaterial : PolyMaterial = PolyMaterials.GetByName(itemString);
            
            if (polyMaterial.graphicName != "")
            {
                var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
                
                if (dobj != null)
                {
                    var box : MovieClip = new MovieClip();
                    var g : Graphics = box.graphics;
                    g.beginBitmapFill(dobj.GetBitmapData(polyMaterial.fillFrame), null, true, true);
                    g.drawRect(0, 0, item.displayBox.width, item.displayBox.height);
                    g.endFill();
                    
                    item.addChild(box);
                    box.x = item.displayBox.x;
                    box.y = item.displayBox.y;
                }
            }
            
            
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
        UpdateEverything();
    }
}


