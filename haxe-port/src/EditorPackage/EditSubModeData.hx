package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class EditSubModeData
{
    private var name : String;
    private var displayName : String;
    private var keyCode : Int;
    private var setMode : Bool;
    
    public function new(_name : String, _setMode : Bool, _keyCode : Int, _displayName : String)
    {
        name = _name;
        keyCode = _keyCode;
        displayName = _displayName;
        setMode = _setMode;
    }
}

