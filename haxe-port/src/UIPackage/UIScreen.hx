package uIPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class UIScreen
{
    private var name : String;
    private var overlay : Bool;
    private var theClass : Class<Dynamic>;
    private var params : Dynamic;
    
    public function new(_name : String, _overlay : Bool, _className : Class<Dynamic>, _params)
    {
        name = _name;
        overlay = _overlay;
        theClass = _className;
        params = _params;
    }
}


