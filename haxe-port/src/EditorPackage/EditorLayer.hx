package editorPackage;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import uIPackage.UI;

/**
	 * ...
	 * @author Julian
	 */
class EditorLayer
{
    private var name : String;
    private var index : Int;
    private var visible : Bool;
    private var locked : Bool;
    private var active : Bool;
    private var mc : EditorEditItemLayer;
    
    public function new(_index : Int, _name : String)
    {
        name = _name;
        index = _index;
        visible = true;
        locked = false;
        active = false;
        mc = new EditorEditItemLayer();
        
        mc.editorLayer = this;
        mc.displayText.text = "LAYER " + as3hx.Compat.parseInt(index + 1);
        
        UI.AddBarebonesMCButton(mc.buttonVisible, clickedVisible);
        UI.AddBarebonesMCButton(mc.buttonLocked, clickedLocked);
        UI.AddBarebonesMCButton(mc.buttonSelected, clickedSelected);
        
        UI.SetNonPropagateMouse(mc.buttonVisible);
        UI.SetNonPropagateMouse(mc.buttonLocked);
        UI.SetNonPropagateMouse(mc.buttonSelected);
    }
    
    private function clickedVisible(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        ToggleVisibility();
        UpdateUI();
    }
    private function clickedLocked(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        ToggleLocked();
        UpdateUI();
    }
    private function clickedSelected(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        EditorLayers.SetActive(index);
        EditorLayers.UpdateUI();
    }
    
    public function UpdateUI()
    {
        mc.buttonVisible.cross.visible = true;
        mc.buttonLocked.cross.visible = true;
        mc.buttonSelected.cross.visible = true;
        
        if (visible)
        {
            mc.buttonVisible.cross.visible = false;
        }
        if (locked)
        {
            mc.buttonLocked.cross.visible = false;
        }
        if (active)
        {
            mc.buttonSelected.cross.visible = false;
        }
    }
    
    public function ToggleVisibility()
    {
        visible = (visible == false);
    }
    public function ToggleLocked()
    {
        locked = (locked == false);
    }
    public function ToggleActive()
    {
        active = (active == false);
    }
    
    public function IsVisible() : Bool
    {
        return visible;
    }
    public function IsLocked() : Bool
    {
        return locked;
    }
    public function IsActive() : Bool
    {
        return active;
    }
}

