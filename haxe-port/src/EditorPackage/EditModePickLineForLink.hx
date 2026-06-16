package editorPackage;

import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.events.MouseEvent;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModePickLineForLink extends EditModeBase
{
    
    public var pickedLine : EdLine;
    public var returnFunction : Function;
    public var hoveredLine : EdLine;
    
    public function new()
    {
        super();
    }
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        hoveredLine = null;
    }
    override public function InitOnce() : Void
    {
    }
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        pickedLine = null;
        super.OnMouseDown(e);
        PhysEditor.editModeObj_Lines.currentLineIndex = -1;
        
        var line : EdLine = PhysEditor.HitTestLineArea(mxs, mys);
        
        pickedLine = line;
        returnFunction(pickedLine);
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        hoveredLine = null;
        hoveredLine = PhysEditor.HitTestLineArea(mxs, mys);
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    override public function Update() : Void
    {
    }
    override public function Render(bd : BitmapData) : Void
    {
        bd.fillRect(Defs.screenRect, 0xff334455);
        PhysEditor.RenderBackground(bd);
        PhysEditor.Editor_RenderObjects();
        PhysEditor.Editor_RenderPickedObjectsHilight();
        PhysEditor.Editor_RenderMiniMap();
        PhysEditor.Editor_RenderLines1();
        PhysEditor.HighlightLinePoly(hoveredLine);
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        return y;
    }
}


