
/**
	 * ...
	 * @author LongAnimals
	 */
class ObjParam
{
    public var name : String;
    public var type : String;
    public var defaultValue : String;
    public var valueList : Array<Dynamic>;
    
    public var number_useRangeMin : Bool;
    public var number_useRangeMax : Bool;
    public var number_min : Float;
    public var number_max : Float;
    public var number_step : Float;
    
    public function new()
    {
        name = "";
        type = "";
        defaultValue = "";
        valueList = new Array<Dynamic>();
        
        number_useRangeMin = false;
        number_useRangeMax = false;
        number_min = 0;
        number_max = 0;
        number_step = 1;
    }
    
    public function AddValuesString(vals : String) : Void
    {
        if (vals == null)
        {
            return;
        }
        if (vals == "")
        {
            return;
        }
        valueList = vals.split(",");
    }
}


