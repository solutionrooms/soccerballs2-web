
/**
	 * ...
	 * @author Julian
	 */
class Weapon
{
    public var fireRate : Int = 0;
    public var objName : String;
    public var name : String;
    public var isStraight : Bool;
    
    public function new(_name : String, _objName : String, _fireRate : Float, _isStraight : Bool = false)
    {
        name = _name;
        objName = _objName;
        fireRate = as3hx.Compat.parseInt(_fireRate * Defs.fps);
        isStraight = _isStraight;
    }
}


