import flash.geom.ColorTransform;

/**
	 * ...
	 * @author
	 */
class AnimHierarchyFramePart
{
    public var x : Float;
    public var y : Float;
    public var r : Float;
    public var partName : String;
    public var dobjName : String;
    public var scale : Float;
    public var colorTransform : ColorTransform;
    public var frame : Int;
    public var visible : Bool;
    public var interpolate : Bool;
    
    
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


