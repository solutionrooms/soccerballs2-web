
/**
	 * ...
	 * @author LongAnimals
	 */
class Anim
{
    private var name : String;
    private var minFrame : Int;
    private var maxFrame : Int;
    private var speed : Float;
    
    public function new(_n : String, _min : Int, _max : Int, _spd : Float = 1)
    {
        name = _n;
        minFrame = as3hx.Compat.parseInt(_min - 1);
        maxFrame = as3hx.Compat.parseInt(_max - 1);
        speed = _spd;
    }
}

