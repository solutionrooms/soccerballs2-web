import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class ObjColBody
{
    private var type : Int;
    private var shapes : Array<Dynamic>;
    public function new()
    {
        shapes = new Array<Dynamic>();
    }
    public function AddShape(a : Array<Dynamic>)
    {
        var b : Array<Dynamic> = new Array<Dynamic>();
        for (p in a)
        {
            b.push(p.clone());
        }
        shapes.push(b);
    }
}


