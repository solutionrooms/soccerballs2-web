import flash.geom.ColorTransform;

/**
	 * ...
	 * @author 
	 */
class AnimHierarchyFramePart
{
    private var x : Float;
    private var y : Float;
    private var r : Float;
    private var partName : String;
    private var dobjName : String;
    private var scale : Float;
    private var colorTransform : ColorTransform;
    private var frame : Int;
    private var visible : Bool;
    private var interpolate : Bool;
    
    
    public function Clone() : AnimHierarchyFramePart
    {
        var p : AnimHierarchyFramePart = new AnimHierarchyFramePart();
        p.x = x;
        p.y = y;
        p.r = r;
        p.partName = partName;
        p.dobjName = dobjName;
        p.scale = scale;
        p.colorTransform = Utils.CopyColorTransform(colorTransform);
        p.frame = frame;
        p.visible = visible;
        p.interpolate = interpolate;
        return p;
    }
    
    public function new()
    {
        colorTransform = null;
        frame = 0;
        visible = true;
        interpolate = true;
    }
}

