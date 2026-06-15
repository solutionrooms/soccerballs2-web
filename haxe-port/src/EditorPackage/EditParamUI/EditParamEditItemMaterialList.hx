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
        
        mc = new EditorEditItemMaterialList();
        
        (untyped mc).editorItem = this;
        
        (untyped mc).displayText.text = op.name;
        (untyped mc).inputText.text = op.value;
        
        (untyped mc).displayText.mouseEnabled = false;
        (untyped mc).inputText.mouseEnabled = false;
        
        
        UpdateEverything();
        
        UI.AddButton((untyped mc).buttonElipsis, ElipsisPressed);
        
        
        mc.filters = [];
        if (_op.multipleValues)
        {
            mc.filters = [UI.greyFilter];
        }
        
        PostSetup();
    }
    
    public function UpdateEverything()
    {
        (untyped mc).displayBox.visible = false;
        
        var polyMaterial : PolyMaterial = PolyMaterials.GetByName(op.value);
        
        if (polyMaterial != null && polyMaterial.graphicName != "")
        {
            var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
            
            var box : MovieClip = new MovieClip();
            var g : Graphics = box.graphics;
            g.beginBitmapFill(dobj.GetBitmapData(polyMaterial.fillFrame), null, true, true);
            g.drawRect(0, 0, (untyped mc).displayBox.width, (untyped mc).displayBox.height);
            g.endFill();
            
            mc.addChild(box);
            box.x = (untyped mc).displayBox.x;
            box.y = (untyped mc).displayBox.y;
        }
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
            (untyped item).displayText.text = itemString;
            (untyped item).listIndex = i;
            item.buttonMode = true;
            item.useHandCursor = true;
            item.addEventListener(MouseEvent.CLICK, PopupClicked, false, 0, true);
            
            (untyped item).displayBox.visible = false;
            
            var polyMaterial : PolyMaterial = PolyMaterials.GetByName(itemString);
            
            if (polyMaterial.graphicName != "")
            {
                var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
                
                if (dobj != null)
                {
                    var box : MovieClip = new MovieClip();
                    var g : Graphics = box.graphics;
                    g.beginBitmapFill(dobj.GetBitmapData(polyMaterial.fillFrame), null, true, true);
                    g.drawRect(0, 0, (untyped item).displayBox.width, (untyped item).displayBox.height);
                    g.endFill();
                    
                    item.addChild(box);
                    box.x = (untyped item).displayBox.x;
                    box.y = (untyped item).displayBox.y;
                }
            }
            
            
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
        UpdateEverything();
    }
}


