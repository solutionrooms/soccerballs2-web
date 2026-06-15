package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeBase
{
    
    public function new()
    {
    }
    
    public function InitOnce() : Void
    {
        editSubMode = 0;
    }
    
    public function EnterMode() : Void
    {
        PhysEditor.CursorText_Hide();
        PhysEditor.CursorText_Set("");
        editSubMode = 0;
    }
    
    public var editSubMode : Int = 0;
    public var mx : Int = 0;
    public var my : Int = 0;
    public var sx : Float;
    public var sy : Float;
    public var mxs : Int = 0;
    public var mys : Int = 0;
    
    public function GetMousePositions(e : MouseEvent)
    {
        mx = Std.int(e.stageX);
        my = Std.int(e.stageY);
        
        if (PhysEditor.gridMode_active)
        {
            mx = Math.floor(mx);
            my = Math.floor(my);
            mx = as3hx.Compat.parseInt(as3hx.Compat.parseInt(mx / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap));
            my = as3hx.Compat.parseInt(as3hx.Compat.parseInt(my / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap));
        }
        
        sx = PhysEditor.scrollX;
        sy = PhysEditor.scrollY;
        if (PhysEditor.gridMode_active)
        {
            sx = Math.floor(sx);
            sy = Math.floor(sy);
            sx = as3hx.Compat.parseInt(sx / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap);
            sy = as3hx.Compat.parseInt(sy / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap);
        }
        
        
        mxs = as3hx.Compat.parseInt((mx * (1 / PhysEditor.zoom)) + sx);
        mys = as3hx.Compat.parseInt((my * (1 / PhysEditor.zoom)) + sy);
    }
    
    public function OnMouseDown(e : MouseEvent) : Void
    {
        GetMousePositions(e);
    }
    public function OnMouseUp(e : MouseEvent) : Void
    {
        GetMousePositions(e);
    }
    public function OnMouseMove(e : MouseEvent) : Void
    {
        GetMousePositions(e);
    }
    public function OnMouseWheel(delta : Int) : Void
    {
    }
    public function Update() : Void
    {
    }
    public function Render(bd : BitmapData) : Void
    {
    }
    public function RenderHud(x : Int, y : Int) : Int
    {
        return y;
    }
    
    
    public function GetCurrentLevel() : Level
    {
        return PhysEditor.GetCurrentLevel();
    }
    public function GetCurrentLevelJoints() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevel().joints;
    }
    public function GetCurrentLevelInstances() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevelInstances();
    }
    public function GetCurrentLevelLines() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevelLines();
    }
    public function SetCurrentLevelInstances(instances : Array<Dynamic>) : Void
    {
        PhysEditor.SetCurrentLevelInstances(instances);
    }
}


