
/**
	 * ...
	 * @author ...
	 */
class PhysObjBodyUserData
{
    public var type : String;
    public var bodyName : String;
    public var gameObjectIndex : Int;
    public var id : Int;
    public var independantGO : GameObj;
    
    public function new()
    {
        type = "";
        bodyName = "";
        gameObjectIndex = -1;
        id = 0;
        independantGO = null;
    }
    
    public function Clone() : PhysObjBodyUserData
    {
        var copy : PhysObjBodyUserData = new PhysObjBodyUserData();
        copy.type = type;
        copy.bodyName = bodyName;
        copy.gameObjectIndex = gameObjectIndex;
        copy.id = id;
        copy.independantGO = independantGO;
        return copy;
    }
}


