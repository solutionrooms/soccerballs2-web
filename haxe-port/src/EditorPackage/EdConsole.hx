package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class EdConsole
{
    public static var lineList : Array<EdConsoleItem>;
    public static var activeList : Array<EdConsoleItem>;
    
    
    public function new()
    {
    }
    public static function InitOnce()
    {
        lineList = [];
        activeList = [];
    }
    
    
    public static function Add(text : String)
    {
        activeList.push(new EdConsoleItem(text));
        lineList.push(new EdConsoleItem(text));
    }
    
    
    public static function UpdateOncePerFrame()
    {
        var removeList : Array<Dynamic> = [];
        for (item in activeList)
        {
            item.timer--;
            if (item.timer <= 0)
            {
                removeList.push(item);
            }
        }
        for (item in removeList)
        {
            var index : Int = Lambda.indexOf(activeList, item);
            activeList.splice(Lambda.indexOf(activeList, index), 1);
        }
    }
}


