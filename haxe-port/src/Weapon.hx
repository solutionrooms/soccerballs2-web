
/**
	 * ...
	 * @author Julian
	 */
class Weapon
{
    private var fireRate : Int;
    private var objName : String;
    private var name : String;
    private var isStraight : Bool;
    
    public function new(_name : String, _objName : String, _fireRate : Float, _isStraight : Bool = false)
    {
        name = _name;
        objName = _objName;
        fireRate = as3hx.Compat.parseInt(_fireRate * Defs.fps);
        isStraight = _isStraight;
    }
}

