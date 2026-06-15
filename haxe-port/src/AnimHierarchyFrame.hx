import flash.geom.ColorTransform;

/**
	 * ...
	 * @author
	 */
class AnimHierarchyFrame
{
    public var parts : Array<AnimHierarchyFramePart>;
    
    public function Clone() : AnimHierarchyFrame
    {
        var f : AnimHierarchyFrame = new AnimHierarchyFrame();
        f.parts = [];
        for (p in parts)
        {
            f.parts.push(p.Clone());
        }
        return f;
    }
    
    public function new()
    {
        parts = [];
    }
}


