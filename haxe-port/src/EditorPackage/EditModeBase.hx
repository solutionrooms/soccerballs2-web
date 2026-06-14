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
    
    private var editSubMode : Int;
    private var mx : Int;
    private var my : Int;
    private var sx : Float;
    private var sy : Float;
    private var mxs : Int;
    private var mys : Int;
    
    private function GetMousePositions(e : MouseEvent)
    {
        mx = e.stageX;
        my = e.stageY;
        
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
    
    
    private function GetCurrentLevel() : Level
    {
        return PhysEditor.GetCurrentLevel();
    }
    private function GetCurrentLevelJoints() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevel().joints;
    }
    private function GetCurrentLevelInstances() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevelInstances();
    }
    private function GetCurrentLevelLines() : Array<Dynamic>
    {
        return PhysEditor.GetCurrentLevelLines();
    }
    private function SetCurrentLevelInstances(instances : Array<Dynamic>) : Void
    {
        PhysEditor.SetCurrentLevelInstances(instances);
    }
}


