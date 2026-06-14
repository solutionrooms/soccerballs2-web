import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class ExhaustPositions
{
    private var points : Array<Dynamic>;
    private var rots : Array<Dynamic>;
    public function new(p0 : Point, dir0 : Float, p1 : Point = null, dir1 : Float = 0, p2 : Point = null, dir2 : Float = 0)
    {
        points = new Array<Dynamic>();
        rots = new Array<Dynamic>();
        points.push(p0);
        rots.push(Utils.DegToRad(dir0));
        if (p1 != null)
        {
            points.push(p1);
            rots.push(Utils.DegToRad(dir1));
        }
        if (p2 != null)
        {
            points.push(p2);
            rots.push(Utils.DegToRad(dir2));
        }
    }
}


