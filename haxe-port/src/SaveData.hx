import achievementPackage.Achievements;
import flash.system.System;
import flash.net.SharedObject;

/**
	 * ...
	 * @author ...
	 */
class SaveData
{
    
    public function new()
    {
    }
    
    public static var id : String = "soccerballs2_9988";
    
    
    
    public static function Exists() : Bool
    {
        if (Game.doWalkthrough)
        {
            return false;
        }
        var so : SharedObject = SharedObject.getLocal(id);
        if (so == null)
        {
            trace("Shared Object: " + id + " null");
            return false;
        }
        if (so.size == 0)
        {
            trace("Shared Object: " + id + " size 0");
            (untyped so).close();
            return false;
        }
        
        (untyped so).close();
        return true;
    }
    
    public static function Load() : Void
    {
        if (Game.doWalkthrough)
        {
            return;
        }
        var so : SharedObject = SharedObject.getLocal(id);
        if (so == null)
        {
            trace("Shared Object: " + id + " is null");
            return;
        }
        if (so.size == 0)
        {
            trace("Shared Object: " + id + " size=0");
            (untyped so).close();
            return;
        }
        
        HintPopups.FromSharedObject(so.data.hintpopups);
        Levels.FromSharedObject(so.data.levels);
        GameVars.FromSharedObject(so.data.gamevars);
        Achievements.FromSharedObject(so.data.achievements);
        
        // AS3 coerces an undefined SharedObject field to 0 for an int; Haxe leaves it undefined (-> the
        // HUD shows "null" on a save that never stored these keys). Default missing values to 0.
        Game.cash = (so.data.cash != null) ? so.data.cash : 0;
        Game.currentScore = (so.data.score != null) ? so.data.score : 0;
        
        (untyped so).close();
        Utils.print("Loaded data OK");
    }
    
    
    public static function DontLoad() : Void
    {
    }
    
    
    public static function Clear() : Void
    {
        if (Game.doWalkthrough)
        {
            return;
        }
        var so : SharedObject = SharedObject.getLocal(id);
        so.clear();
        (untyped so).close();
        so.flush();
        trace("SaveData Data Cleared");
        trace("len: " + so.size);
    }
    
    public static function DontSave() : Void
    {
    }
    
    public static function Save() : Void
    {
        if (Game.doWalkthrough)
        {
            return;
        }
        var i : Int = 0;        var so : SharedObject = SharedObject.getLocal(id);
        if (so == null)
        {
            trace("SO null");
            return;
        }
        if (so.size == 0)
        {
            trace("SO size 0");
        }
        
        so.clear();
        
        so.data.hintpopups = HintPopups.ToSharedObject();
        so.data.levels = Levels.ToSharedObject();
        so.data.gamevars = GameVars.ToSharedObject();
        so.data.achievements = Achievements.ToSharedObject();
        
        so.data.cash = Game.cash;
        so.data.score = Game.currentScore;
        
        
        (untyped so).close();
    }
}


