import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class PhysObjBody
{
    public var name : String;
    public var shapes : Array<Dynamic>;
    public var graphics : Array<Dynamic>;
    public var fixed : Bool;
    public var sensor : Bool;
    public var linearDamping : Float;
    public var angularDamping : Float;
    
    public var pos : Point;
    
    
    
    public function new()
    {
        shapes = new Array<Dynamic>();
        graphics = new Array<Dynamic>();
        name = "";
        pos = new Point();
        fixed = true;
        sensor = false;
        linearDamping = 0.1;
        angularDamping = 1;
    }
}


