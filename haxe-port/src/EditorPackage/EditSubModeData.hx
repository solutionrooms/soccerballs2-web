package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class EditSubModeData
{
    public var name : String;
    public var displayName : String;
    public var keyCode : Int;
    public var setMode : Bool;
    
    public function new(_name : String, _setMode : Bool, _keyCode : Int, _displayName : String)
    {
        name = _name;
        keyCode = _keyCode;
        displayName = _displayName;
        setMode = _setMode;
    }
}


