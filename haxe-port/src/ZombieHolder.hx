import haxe.Constraints.Function;
import com.adobe.utils.DictionaryUtil;
import flash.display.MovieClip;
import flash.utils.Dictionary;

/**
	 * ...
	 * @author Julian
	 */
class ZombieHolder
{
    private static var dictionary : Dictionary;
    
    
    
    public function new()
    {
    }
    
    
    public static function InitOnce()
    {
        dictionary = new Dictionary();
    }
    
    public static function Add(mc : MovieClip, _type : String, _cb : Function, _index0 : Int, _index1 : Int, _index2 : Int) : DisplayObj
    {
        var zombieDobj : DisplayObj;
        
        var dictString : String = _type + _index0 + "_" + _index1 + "_" + _index2;
        
        
        if (Reflect.field(dictionary, dictString) == null)
        {
            zombieDobj = new DisplayObj(null, 1, 0);
            zombieDobj.origMC = mc;
            
            
            
            zombieDobj.CreateBlankBitmapsFromMovieClip(zombieDobj.origMC, 0, _cb);
            zombieDobj.name = zombieDobj.origMC.name;
            Reflect.setField(dictionary, dictString, zombieDobj);
        }
        else
        {
            zombieDobj = Reflect.field(dictionary, dictString);
        }
        
        
        
        return zombieDobj;
    }
}

