import editorPackage.EdLine;

/**
	 * ...
	 * @author LongAnimals
	 */
class LevelBase
{
    public var id : String;
    public var name : String;
    public var displayName : String;
    public var description : String;
    public var category : Int = 0;
    public var bgFrame : Int = 0;
    public var music : Int = 0;
    public var instances : Array<Dynamic>;
    public var joints : Array<Dynamic>;
    public var helpscreenFrames : Array<Dynamic>;
    public var lines : Array<Dynamic>;
    
    public var fillFrame : Int = 0;
    public var surfaceFrame : Int = 0;
    public var surfaceThickness : Int = 0;
    
    public var owned : Bool;
    
    public var played : Bool;
    public var newlyAvailable : Bool;
    public var markedAsJustUnlocked : Bool;
    public var available : Bool;
    public var complete : Bool;
    public var numRockets : Int = 0;
    
    public var exclusiveChar : Int = 0;
    public var eventType : String;
    public var eventOpponentsString : String;
    public var eventWinParam : Float;
    
    public var endLightColor : Int = 0;
    
    public var cost : Int = 0;
    public var locked : Bool;
    
    public var bestShots : Int = 0;
    public var bestScore : Int = 0;
    public var levelScore : Int = 0;
    
    public var percentage : Float;
    public var bestPercentage : Float;
    public var rating : Int = 0;
    public var lastTime : Int = 0;
    public var lastPlace : Int = 0;
    public var lastTimeTotal : Int = 0;
    public var bestPlace : Int = 0;
    public var bestTime : Int = 0;
    public var bestTimeTotal : Int = 0;
    public var goldTime : Int = 0;
    public var silverTime : Int = 0;
    
    public var aiCarMaxSpeed : Float;
    public var aiCarMinSpeed : Float;
    public var raceType : String;
    public var aiCarTypeString : String;
    public var levelFunctionName : String;
    
    public var map : Array<Dynamic>;
    public var mapCellW : Int = 0;
    public var mapCellH : Int = 0;
    public var mapMinX : Int = 0;
    public var mapMinY : Int = 0;
    public var mapMaxX : Int = 0;
    public var mapMaxY : Int = 0;
    
    public var fullyLoaded : Bool;
    public var creator : String;
    public var gotBonus : Bool;
    
    public function new()
    {
        locked = false;
        name = "";
        displayName = "";
        description = "";
        instances = [];
        joints = [];
        helpscreenFrames = [];
        lines = [];
        music = 0;
        category = 0;
        fillFrame = 1;
        surfaceFrame = 5;
        surfaceThickness = 10;
        newlyAvailable = false;
        markedAsJustUnlocked = false;
        available = false;
        complete = false;
        eventType = "none";
        eventOpponentsString = "";
        eventWinParam = 1;
        exclusiveChar = 1;
        lastPlace = 9999999;
        lastTime = 9999999;
        lastTimeTotal = 9999999;
        bestTime = 9999999;
        bestTimeTotal = 9999999;
        goldTime = as3hx.Compat.parseInt(10 * Defs.fps);
        silverTime = as3hx.Compat.parseInt(20 * Defs.fps);
        played = false;
        numRockets = 0;
        bestPlace = 99999;
        bestScore = 0;
        bestShots = 99999;
        percentage = 0;
        bestPercentage = 0;
        creator = "";
        gotBonus = false;
        
        var i : Int = 0;        map = [];
        mapCellW = 16;
        mapCellH = 16;
        mapMinX = 0;
        mapMaxX = 0;
        mapMinY = 0;
        mapMaxY = 0;
        
        levelFunctionName = "";
        rating = 0;
        endLightColor = 0;
        
        cost = 500;
        owned = true;
        
        
        fullyLoaded = false;
    }
    public function Calculate()
    {
    }
    
    public function GetLineByName(name : String) : EdLine
    {
        for (l in lines)
        {
            if (l.id == name)
            {
                return l;
            }
        }
        return null;
    }
    public function GetLineByIndex(index : Int) : EdLine
    {
        if (index < 0)
        {
            return null;
        }
        if (index >= lines.length)
        {
            return null;
        }
        return lines[index];
    }
}


