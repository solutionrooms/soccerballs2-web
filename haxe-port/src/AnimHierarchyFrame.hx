import flash.geom.ColorTransform;

/**
	 * ...
	 * @author
	 */
class AnimHierarchyFrame
{
    private var parts : Array<AnimHierarchyFramePart>;
    
    public function Clone() : AnimHierarchyFrame
    {
        var f : AnimHierarchyFrame = new AnimHierarchyFrame();
        f.parts = new Array<AnimHierarchyFramePart>();
        for (p in parts)
        {
            f.parts.push(p.Clone());
        }
        return f;
    }
    
    public function new()
    {
        parts = new Array<AnimHierarchyFramePart>();
    }
}


