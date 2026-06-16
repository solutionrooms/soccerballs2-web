
/**
	 * ...
	 * @author LongAnimals
	 */
class Anim
{
    public var name : String;
    public var minFrame : Int = 0;
    public var maxFrame : Int = 0;
    public var speed : Float;
    
    public function new(_n : String, _min : Int, _max : Int, _spd : Float = 1)
    {
        name = _n;
        minFrame = as3hx.Compat.parseInt(_min - 1);
        maxFrame = as3hx.Compat.parseInt(_max - 1);
        speed = _spd;
    }
}


