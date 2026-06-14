package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class EdConsole
{
    private static var lineList : Array<EdConsoleItem>;
    private static var activeList : Array<EdConsoleItem>;
    
    
    public function new()
    {
    }
    public static function InitOnce()
    {
        lineList = new Array<EdConsoleItem>();
        activeList = new Array<EdConsoleItem>();
    }
    
    
    public static function Add(text : String)
    {
        activeList.push(new EdConsoleItem(text));
        lineList.push(new EdConsoleItem(text));
    }
    
    
    public static function UpdateOncePerFrame()
    {
        var removeList : Array<Dynamic> = new Array<Dynamic>();
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

