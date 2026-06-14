package editorPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class ObjParameter
{
    public var name : String;
    public var value : String;
    public var multipleValues : Bool;
    
    public function new()
    {
        multipleValues = false;
    }
    public function Clone() : ObjParameter
    {
        var p : ObjParameter = new ObjParameter();
        p.name = name;
        p.value = value;
        p.multipleValues = multipleValues;
        return p;
    }
}


