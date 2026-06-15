import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class ObjColBody
{
    public var type : Int;
    public var shapes : Array<Dynamic>;
    public function new()
    {
        shapes = [];
    }
    public function AddShape(a : Array<Dynamic>)
    {
        var b : Array<Dynamic> = [];
        for (p in a)
        {
            b.push(p.clone());
        }
        shapes.push(b);
    }
}


