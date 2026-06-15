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
    public var name : String;
    public var index : Int;
    public var visible : Bool;
    public var locked : Bool;
    public var active : Bool;
    public var mc : EditorEditItemLayer;
    
    public function new(_index : Int, _name : String)
    {
        name = _name;
        index = _index;
        visible = true;
        locked = false;
        active = false;
        mc = new EditorEditItemLayer();
        
        (untyped mc).editorLayer = this;
        (untyped mc).displayText.text = "LAYER " + as3hx.Compat.parseInt(index + 1);
        
        UI.AddBarebonesMCButton((untyped mc).buttonVisible, clickedVisible);
        UI.AddBarebonesMCButton((untyped mc).buttonLocked, clickedLocked);
        UI.AddBarebonesMCButton((untyped mc).buttonSelected, clickedSelected);
        
        UI.SetNonPropagateMouse((untyped mc).buttonVisible);
        UI.SetNonPropagateMouse((untyped mc).buttonLocked);
        UI.SetNonPropagateMouse((untyped mc).buttonSelected);
    }
    
    public function clickedVisible(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        ToggleVisibility();
        UpdateUI();
    }
    public function clickedLocked(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        ToggleLocked();
        UpdateUI();
    }
    public function clickedSelected(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
        EditorLayers.SetActive(index);
        EditorLayers.UpdateUI();
    }
    
    public function UpdateUI()
    {
        (untyped mc).buttonVisible.cross.visible = true;
        (untyped mc).buttonLocked.cross.visible = true;
        (untyped mc).buttonSelected.cross.visible = true;
        
        if (visible)
        {
            (untyped mc).buttonVisible.cross.visible = false;
        }
        if (locked)
        {
            (untyped mc).buttonLocked.cross.visible = false;
        }
        if (active)
        {
            (untyped mc).buttonSelected.cross.visible = false;
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


