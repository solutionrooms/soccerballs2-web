import flash.display.BitmapData;
import flash.geom.Point;
import flash.ui.Mouse;
import flash.ui.MouseCursorData;

/**
	 * ...
	 * @author
	 */
class CustomCursor
{
    
    public function new()
    {
    }
    
    public static function Use(b : Bool)
    {
        return;
        
        if (b)
        {
            Mouse.cursor = "pointer";
        }
        else
        {
            Mouse.cursor = "null";
        }
    }
    public static function InitOnce()
    {
        return;
        
        var cursorData : MouseCursorData = null;        
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("Cursor_Pointer");
        cursorData = new MouseCursorData();
        cursorData.hotSpot = new Point(5, 2);
        var bitmapDatas : Array<BitmapData> = [];
        for (i in 0...dobj.GetNumFrames())
        {
            bitmapDatas[i] = dobj.GetBitmapData(i);
        }
        cursorData.data = bitmapDatas;
        cursorData.frameRate = 30;
        
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("Cursor_CanPress");
        cursorData = new MouseCursorData();
        cursorData.hotSpot = new Point(7, 2);
        var bitmapDatas : Array<BitmapData> = [];
        for (i in 0...dobj.GetNumFrames())
        {
            bitmapDatas[i] = dobj.GetBitmapData(i);
        }
        cursorData.data = bitmapDatas;
        cursorData.frameRate = 30;
        
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("Cursor_Pointer_CantPress");
        cursorData = new MouseCursorData();
        cursorData.hotSpot = new Point(5, 2);
        var bitmapDatas : Array<BitmapData> = [];
        for (i in 0...dobj.GetNumFrames())
        {
            bitmapDatas[i] = dobj.GetBitmapData(i);
        }
        cursorData.data = bitmapDatas;
        cursorData.frameRate = 30;
    }
}


