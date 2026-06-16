package editorPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class PhysEdGuideLine
{
    public var x0 : Float;
    public var x1 : Float;
    public var y0 : Float;
    public var y1 : Float;
    public var type : Int = 0;
    public var level : Bool;
    
    public function new(l0 : Float, l1 : Float, p : Float, _type : Float, _level : Bool)
    {
        type = as3hx.Compat.parseInt(_type);
        level = _level;
        if (type == 0)
        {
            x0 = l0;
            x1 = l1;
            y0 = p;
            y1 = p;
        }
        else
        {
            y0 = l0;
            y1 = l1;
            x0 = p;
            x1 = p;
        }
    }
}


