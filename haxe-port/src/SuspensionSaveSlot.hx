
/**
	 * ...
	 * @author ...
	 */
class SuspensionSaveSlot
{
    public var index : Int;
    public var sliderLevels : Array<Dynamic>;
    public var name : String;
    
    public function new(_index : Int)
    {
        sliderLevels = new Array<Dynamic>(50, 50, 50, 50, 50, 50);
        name = "empty";
        index = _index;
    }
    
    
    public function FromObject(o : Dynamic)
    {
        index = o.index;
        name = o.name;
        sliderLevels = new Array<Dynamic>(50, 50, 50, 50, 50, 50);
        for (i in 0...6)
        {
            sliderLevels[i] = o.sliderLevels[i];
        }
    }
    
    public function Clone() : SuspensionSaveSlot
    {
        var c : SuspensionSaveSlot = new SuspensionSaveSlot(index);
        c.name = name;
        c.sliderLevels = new Array<Dynamic>(50, 50, 50, 50, 50, 50);
        for (i in 0...6)
        {
            c.sliderLevels[i] = sliderLevels[i];
        }
        return c;
    }
}


