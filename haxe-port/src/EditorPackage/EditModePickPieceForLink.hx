package editorPackage;

import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.events.MouseEvent;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModePickPieceForLink extends EditModeBase
{
    public var pickedObject : EdObj;
    public var returnFunction : Function;
    public var hoveredObj : EdObj;
    
    public function new()
    {
        super();
    }
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        pickedObject = null;
        hoveredObj = null;
    }
    override public function InitOnce() : Void
    {
        hoveredObj = null;
    }
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        pickedObject = null;
        var poi : EdObj = PhysEditor.HitTestPhysObjGraphics(mx, my, true);
        pickedObject = poi;
        returnFunction(pickedObject);
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        hoveredObj = PhysEditor.HitTestPhysObjGraphics(mxs, mys, false);
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
        if (hoveredObj != null)
        {
            hoveredObj.RenderHighlighted(EditableObjectBase.HIGHLIGHT_HOVER);
        }
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        return y;
    }
}


