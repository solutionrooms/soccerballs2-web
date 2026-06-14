package editorPackage;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import textPackage.TextRenderer;

/**
	 * ...
	 * @author Julian
	 */
class EditorGameRenderer
{
    
    public function new()
    {
    }
    
    
    private function RenderHelpText(po : PhysObj, poi : EdObj)
    {
        var bd : BitmapData = PhysEditor.screenBD;
        var p : Point = PhysEditor.GetMapPos(poi.x, poi.y);
        PhysObj.RenderAt(po, p.x, p.y, poi.rot, poi.scale * PhysEditor.zoom, bd, PhysEditor.linesScreen.graphics, true);
        
        var s : String = poi.objParameters.GetValueString("helptext_text", "helptxt");
        var c : String = poi.objParameters.GetValueString("helptext_color");
        var ct : ColorTransform = Utils.HexStringToColorTransform(c);
        
        
        TextRenderer.RenderAt(bd, p.x, p.y, s, Utils.DegToRad(poi.rot), poi.scale, TextRenderer.JUSTIFY_CENTRE, ct);
    }
    
    private function RenderHelpTextWithMarker(po : PhysObj, poi : EdObj)
    {
        var bd : BitmapData = PhysEditor.screenBD;
        var p : Point = PhysEditor.GetMapPos(poi.x, poi.y);
        PhysObj.RenderAt(po, p.x, p.y, poi.rot, poi.scale * PhysEditor.zoom, bd, PhysEditor.linesScreen.graphics, true);
        
        var s : String = poi.objParameters.GetValueString("helptext_text", "helptxt");
        var c : String = poi.objParameters.GetValueString("helptext_color");
        var ct : ColorTransform = Utils.HexStringToColorTransform(c);
        
        
        TextRenderer.RenderAt(bd, p.x, p.y, s, Utils.DegToRad(poi.rot), poi.scale, TextRenderer.JUSTIFY_CENTRE, ct);
        
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("walkthroughMarker");
        dobj.RenderAt(0, bd, p.x - 25, p.y - 10);
    }
}


