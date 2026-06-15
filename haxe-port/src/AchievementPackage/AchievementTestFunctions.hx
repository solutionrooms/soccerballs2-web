package achievementPackage;


/**
	 * ...
	 * @author
	 */
class AchievementTestFunctions
{
    
    public function new()
    {
    }
    public function AchPass_Null() : Void
    {
        Achievements.currentAch.popupFrame = 37;
    }
    
    public function AchPass_Cash() : Void
    {
        var num : Int = Utils.GetParamInt("cash");
        
        Game.currentScore += num;
    }
    
    public function AchPass_UnlockLevel() : Void
    {
        var num : Int = Utils.GetParamInt("levelnum");
        Levels.GetLevel(num - 1).locked = false;
        Levels.GetLevel(num - 1).complete = false;
        Levels.GetLevel(num - 1).available = true;
        Levels.GetLevel(num - 1).newlyAvailable = true;
        Levels.GetLevel(num - 1).markedAsJustUnlocked = true;
        Achievements.currentAch.popupFrame = num;
        
        Game.currentScore += 500;
    }
    
    
    public function AchTest_Place() : Bool
    {
        var reqPlace : Int = Utils.GetParamInt("place");
        if (race_place <= (reqPlace - 1))
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_NotUsingSpecialCar() : Bool
    {
        return true;
    }
    public function AchTest_UsingSpecialCar() : Bool
    {
        return false;
    }
    
    
    public function AchTest_LevelTime() : Bool
    {
        var time : Int = as3hx.Compat.parseInt(Utils.GetParamInt("time") * Defs.fps);
        if (Levels.GetCurrent().complete)
        {
            var t : Int = Levels.GetCurrent().bestTime;
            if (t <= time)
            {
                return true;
            }
        }
        return false;
    }
    public function AchTest_WinAllLevels() : Bool
    {
        var count : Int = 0;
        for (i in 0...Levels.list.length)
        {
            var l : Level = Levels.GetLevel(i);
            if (l.complete)
            {
                if (l.bestPlace == 0)
                {
                    count++;
                }
            }
        }
        if (count == 24)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_CompleteAllLevels() : Bool
    {
        var count : Int = 0;
        for (i in 0...24)
        {
            var l : Level = Levels.GetLevel(i);
            if (l.complete)
            {
                count++;
            }
        }
        if (count == 24)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_AllGreenLights() : Bool
    {
        var count : Int = 0;
        for (i in 0...24)
        {
            var l : Level = Levels.GetLevel(i);
            if (l.complete)
            {
                if (l.endLightColor == 1)
                {
                    count++;
                }
            }
        }
        if (count == 16)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_LevelComplete() : Bool
    {
        var num : Int = Utils.GetParamInt("levelnum");
        if (Levels.GetLevel(num - 1).complete)
        {
            return true;
        }
        return false;
    }
    
    
    public function AchTest_IntGreaterOrEqual() : Bool
    {
        var varName : String = Utils.GetParamString("variable");
        var value : Int = Utils.GetParamInt("value");
        var intVar : Int = Reflect.field(this, varName);
        
        if (intVar >= value)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_IntLessOrEqual() : Bool
    {
        var varName : String = Utils.GetParamString("variable");
        var value : Int = Utils.GetParamInt("value");
        var intVar : Int = Reflect.field(this, varName);
        if (intVar <= value)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_FlagSet() : Bool
    {
        var flagName : String = Utils.GetParamString("flag");
        if (Reflect.field(this, flagName) == true)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_FlagNotSet() : Bool
    {
        var flagName : String = Utils.GetParamString("flag");
        if (Reflect.field(this, flagName) == false)
        {
            return true;
        }
        return false;
    }
    
    public function AchTest_Cones() : Bool
    {
        return false;
    }
    public function AchTest_Nitros() : Bool
    {
        return false;
    }
    public function AchTest_CashPickup() : Bool
    {
        return false;
    }
    public function AchTest_NitroOvertake() : Bool
    {
        return false;
    }
    public function AchTest_DontHitSides() : Bool
    {
        return true;
    }
    
    public function AchTest_FinishPlace() : Bool
    {
        return false;
    }
    
    public function AchTest_FinishAll() : Bool
    {
        var num : Int = Utils.GetParamInt("place");
        num--;
        
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            if (l.complete)
            {
            }
            else
            {
                return false;
            }
        }
        
        return true;
    }
    
    
    public function AchTest_FinishTime() : Bool
    {
        return false;
    }
    
    public function AchTest_Falls() : Bool
    {
        return false;
    }
    
    
    
    
    
    
    
    public var num_hits : Int = 0;
    public var race_time : Int = 999999;
    public var race_place : Int = 99999;
    
    
    public function UpdateFromGameVars()
    {
    }
    
    public function ResetForLevel() : Void
    {
        num_hits = 0;
        race_time = 9999999;
        race_place = 9999999;
    }
}


