package achievementPackage;


/**
	 * ...
	 * @author ...
	 */
class Achievement
{
    public var index : Int;
    public var name : String;
    public var description : String;
    public var toUnlockText : String;
    public var complete : Bool;
    public var testList : Array<AchievementTest>;
    public var completeFunction : String;
    public var completeFunctionParams : String;
    public var specificLevel : Int;
    public var specificLevelName : String;
    
    private var popupFrame : Int;
    
    public function new()
    {
        name = "undefined";
        description = "undefined";
        complete = false;
        
        completeFunction = null;
        completeFunctionParams = null;
        specificLevel = -1;
        specificLevelName = "";
        
        testList = new Array<AchievementTest>();
    }
}


