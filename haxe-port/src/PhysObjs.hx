
/**
	 * ...
	 * @author ...
	 */
class PhysObjs
{
    public var list : Array<Dynamic>;
    
    public function new()
    {
        list = [];
    }
    
    
    
    
    public function InitFromXml(x : FastXML) : Void
    {
        list = [];
        var i : Int;
        
        for (i in 0...x.nodes.physobj.length())
        {
            var px : FastXML = x.nodes.physobj.get(i);
            var physobj : PhysObj = new PhysObj();
            physobj.FromXml(px);
            list.push(physobj);
        }
    }
    
    
    public function FindIndexByName(name : String) : Int
    {
        var index : Int = 0;
        for (po in list)
        {
            if (po.name == name)
            {
                return index;
            }
            index++;
        }
        trace("ERROR PhysObjs FindByName " + name);
        return 0;
    }
    
    
    public function FindByName(name : String) : PhysObj
    {
        for (po in list)
        {
            if (po.name == name)
            {
                return po;
            }
        }
        trace("ERROR PhysObjs FindByName " + name);
        return null;
    }
    
    public function GetNum() : Int
    {
        return list.length;
    }
    
    public function GetByIndex(index : Int) : PhysObj
    {
        return list[index];
    }
}


