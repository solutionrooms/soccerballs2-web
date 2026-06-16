package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class EdPlacementObj
{
    public var typeName : String;
    public var xpos : Float;
    public var ypos : Float;
    public var xoff : Float;
    public var yoff : Float;
    public var rot : Float;
    public var scale : Float;
    public var objChangeValue : Float;
    public var objParameters : ObjParameters;
    
    
    
    public function new(_typeName : String = "", _params : ObjParameters = null)
    {
        typeName = _typeName;
        xoff = 0;
        yoff = 0;
        rot = 0;
        scale = 1;
        xpos = 0;
        ypos = 0;
        objChangeValue = 0.5;
        objParameters = null;
        if (_params != null)
        {
            objParameters = _params.Clone();
        }
    }
}


