package uIPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class UIScreen
{
    public var name : String;
    public var overlay : Bool;
    public var theClass : Class<Dynamic>;
    public var params : Dynamic;
    
    public function new(_name : String, _overlay : Bool, _className : Class<Dynamic>, _params)
    {
        name = _name;
        overlay = _overlay;
        theClass = _className;
        params = _params;
    }
}


