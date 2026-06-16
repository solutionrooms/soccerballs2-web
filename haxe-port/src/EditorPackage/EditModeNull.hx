package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeNull extends EditModeBase
{
    
    public function new()
    {
        super();
    }
    override public function InitOnce() : Void
    {
    }
    override public function OnMouseDown(e : MouseEvent) : Void
    {
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    override public function Update() : Void
    {
    }
    override public function Render(bd : BitmapData) : Void
    {
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        return y;
    }
}


