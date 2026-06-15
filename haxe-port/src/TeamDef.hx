
/**
	 * ...
	 * @author
	 */
class TeamDef
{
    public var kitColorShirt : Int = 0;
    public var kitColorShorts : Int = 0;
    public var kitColorSocks : Int = 0;
    public var kitColorPattern : Int = 0;
    public var kitStyle : Int = 0;
    public var teamName : String = "your team";
    
    public var playerNames : Array<Dynamic>;
    public var playerHeads : Array<Dynamic>;
    
    public function new()
    {
        var names : Array<Dynamic> = [
        "Clemence", 
        "Callaghan", 
        "Fairclough", 
        "McDermott", 
        "Souness", 
        "Dalglish", 
        "Toshack", 
        "Keegan", 
        "Thompson", 
        "Neil", 
        "Hughes"];
        
        playerNames = [];
        playerHeads = [];
        for (i in 0...11)
        {
            playerHeads.push(i);
            playerNames.push(names[i]);
        }
    }
}


