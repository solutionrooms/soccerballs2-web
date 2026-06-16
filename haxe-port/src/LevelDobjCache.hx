import flash.errors.Error;
import haxe.Constraints.Function;
import flash.display.MovieClip;

/**
	 * ...
	 * @author ...
	 */
class LevelDobjCache
{
    public static var list : Array<DisplayObj>;
    
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        list = [];
    }
    
    
    public static function InitForLevel()
    {
    }
    
    public static function ExitForLevel()
    {
    }
    
    
    public static function Add(mcName : String, flags : String, scale : Float, _frameCB : Function) : DisplayObj
    {
        var classRef : Class<Dynamic> = null;
        
        try
        {
            classRef = Type.getClass(Type.resolveClass(mcName));
        }
        catch (e : Error)
        {
            Utils.traceerror("LevelDobjCache - can't find obj: " + mcName);
            return null;
        }
        var mc : MovieClip = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        var dobj : DisplayObj = new DisplayObj(mc, scale, flags, _frameCB);
        list.push(dobj);
        mc = null;
        
        
        
        return dobj;
    }
}


