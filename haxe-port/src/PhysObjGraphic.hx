import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class PhysObjGraphic
{
    public var graphicName : String;
    public var frame : Int = 0;
    public var offset : Point;
    public var rot : Float;
    public var goInitFuntion : String;
    public var goInitFuntionVarString : String;
    public var zoffset : Float;
    public var hasShadow : Bool;
    
    public function new()
    {
        graphicName = "";
        frame = 0;
        offset = new Point(0, 0);
        rot = 0;
        goInitFuntion = "";
        goInitFuntionVarString = "";
        zoffset = 0;
        hasShadow = true;
    }
    
    public function Calculate()
    {
    }
}


