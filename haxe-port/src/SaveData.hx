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
    
    public static function Save(allowEmpty : Bool = false) : Void
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
        // DATA-LOSS GUARD: Save() clears the SharedObject and rewrites it from the in-memory tables, so a
        // Save() fired while progress is reset/transient would wipe EVERYTHING on disk. If the disk already
        // holds a save but the in-memory state shows no progress at all (no completed level + no cash),
        // refuse the write and keep the existing save. Worst case this skips one save; it can never lose
        // data. Only the explicit "clear data" flow passes allowEmpty=true to bypass this.
        if (!allowEmpty && so.size > 0 && !Levels.HasAnyProgress() && Game.cash == 0)
        {
            trace("SaveData.Save SKIPPED — refusing to overwrite a non-empty save with empty progress");
            (untyped so).close();
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


        // Flash auto-persisted a SharedObject on close(); openfl-html5's close() is a NO-OP, so the
        // save was never written to localStorage and every stat (coins/trophies/levels/achievements)
        // was lost on refresh. flush() is what actually writes to localStorage.
        so.flush();
    }
}


