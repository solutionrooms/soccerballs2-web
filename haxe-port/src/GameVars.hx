import flash.display.MovieClip;
import flash.geom.Point;
import uIPackage.UI;

/**
	 * ...
	 * @author LongAnimals
	 */
class GameVars
{
    public static var gameMode : Int;
    public static var gameTimer : Int;
    public static var gameTimerMax : Int;
    
    public static var numPigsActive : Int;
    public static var totalGoals : Int;
    public static var numGoalsScored : Int;
    public static var numRefsHit : Int;
    public static var totalRefs : Int;
    public static var numAnimalsKilled : Int;
    public static var bossDefeated : Bool;
    
    public static var shadowOffset : Int = 6;
    public static var shadowPower : Int = -200;
    
    public static var guineaPigTypesAllowed : Int = 4;
    
    public static var collectedBonus : Bool;
    
    public static var takingADump : Bool;
    public static inline var gravity : Float = 300;
    public static inline var gravity_GO : Float = 0.2;
    
    public static var pigsUsed : Int;
    
    public static var SnakeReloadTimeNormal : Int = Std.int(Defs.fps * 1);
    public static var SnakeReloadTimeSuper : Int = 0;
    
    public static var snakeUpgradeTexts : Array<Dynamic> = ["", "SuperRegen", "Spitter", "FastSwing", "PigChain"];
    
    public static var snakeUpgrade_None : Int = 0;
    public static var snakeUpgrade_SuperRegen : Int = 1;
    public static var snakeUpgrade_Spitter : Int = 2;
    public static var snakeUpgrade_FastSwing : Int = 3;
    public static var snakeUpgrade_PigChain : Int = 4;
    
    
    public static var snakeUpgradeGO : GameObj = null;
    public static var snakeUpgrade : Int = 0;
    public static var upgradeTimer : Int = 0;
    public static var upgradeTimerMax : Int = Std.int(Defs.fps * 10);
    
    
    public static var ballTimerShowTimerMax : Int = Std.int(Defs.fps * 4);
    public static var ballTimerMax : Int = Std.int(Defs.fps * 6);
    public static var numKicks : Int;
    
    public static var hasPlayedIntro : Bool;
    public static var introGoToLevelSelect : Bool;
    
    public static var cannonHoldTime : Int = Std.int(Defs.fps);
    
    public static inline var ballLineLength : Int = 80;
    
    public static inline var fastForward_numskips : Int = 4;
    public static var doingFastForward : Bool;
    public static var fastforwardoffset : Int;
    
    public static var maxKicks : Int;
    public static var goldKicks : Int;
    
    public static var football_footOffsetX : Float = 10;
    public static var football_footOffsetY : Float = -9;
    public static var useFeature1 : Bool;
    public static var useFeature2 : Bool;
    public static var useFeature3 : Bool;
    public static var useFeature4 : Bool;
    
    
    public static function IsFeatureUnlocked(index : Int) : Bool
    {
        if (index == 0)
        {
            if (GetTotalCoinsCollected() >= 50)
            {
                return true;
            }
        }
        else if (index == 1)
        {
            if (GetTotalCoinsCollected() >= totalGameCoins)
            {
                return true;
            }
        }
        else if (index == 2)
        {
            if (GetNumTrophies() >= 10)
            {
                return true;
            }
        }
        else if (index == 3)
        {
            var count : Int = 0;
            for (i in 0...36)
            {
                if (Levels.GetLevel(i).rating > 0)
                {
                    count++;
                }
            }
            if (count >= 36)
            {
                return true;
            }
        }
        return false;
    }
    
    public static var grassFrame : Int;
    public static var dirtFrame : Int;
    
    public static var currentWalkthroughPage : Int = 0;
    
    public function new()
    {
    }
    public static function InitOnce()
    {
        ResetEverything();
    }
    
    
    public static var unlockList : Array<Dynamic> = [
        [1, 2], 
        [2, 3], 
        [3, 4], 
        
        [4, 5, 6], 
        [5, 7], 
        [7, 9], 
        
        [6, 8], 
        
        [8, 9], 
        [9, 10], 
        [10, 11], 
        [11, 12], 
        [12, 13], 
        [13, 14], 
        
        [14, 15, 16], 
        
        [16, 17, 19], 
        [17, 18], 
        
        [19, 20], 
        [20, 21], 
        [21, 22], 
        [22, 23], 
        [23, 24], 
        
        [24, 25, 27], 
        [25, 26], 
        [26, 29], 
        [27, 28], 
        [28, 29], 
        
        [29, 30], 
        
        [30, 31, 34], 
        [31, 32], 
        [32, 33], 
        
        [34, 35], 
        [35, 36], 
        [36, 37], 
        [37, 38], 
        [38, 39], 
        [39, 40, 43], 
        [40, 41], 
        [41, 42], 
        
        [43, 44], 
        [44, 45], 
        [45, 46], 
        [46, 47], 
        [47, 48], 
        [48, 49], 
        [49, 50]];
    
    
    public static function GetUnlockedLevels(levelID : Int) : Array<Dynamic>
    {
        var unlocked : Array<Dynamic> = [];
        for (a in unlockList)
        {
            if (Reflect.field(a, Std.string(0)) == levelID)
            {
                for (i in 1...a.length)
                {
                    unlocked.push(Reflect.field(a, Std.string(i)));
                }
                return unlocked;
            }
        }
        Utils.print("GetUnlockedLevels error can't find level " + levelID);
        return unlocked;
    }
    
    public static var DumpBackToLevelMapLevels : Array<Dynamic> = [4, 5, 6, 7, 8, 
        14, 15, 
        16, 17, 18, 
        24, 25, 26, 27, 28, 
        30, 31, 32, 33, 
        39, 40, 41, 42];
    
    
    public static function ShouldDumpBackToLevelMap(levelID : Int) : Bool
    {
        for (l in DumpBackToLevelMapLevels)
        {
            if (l == levelID)
            {
                return true;
            }
        }
        return false;
    }
    
    
    public static function GetNumBonusGold() : Int
    {
        var count : Float = 0;
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            if (l.gotBonus)
            {
                count++;
            }
        }
        return Std.int(count);
    }
    public static function GetLevelProgress() : Float
    {
        var totalCount : Float = 0;
        var count : Float = 0;
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            totalCount += 3;
            if (l.complete)
            {
                count++;
                if (l.rating == 0)
                {
                    count++;
                }
            }
            
            if (l.gotBonus)
            {
                count++;
            }
        }
        return (count / totalCount);
    }
    
    public static function ResetEverything()
    {
        currentWalkthroughPage = 0;
        InitCoinsOnce();
        useFeature1 = false;
        useFeature2 = false;
        useFeature3 = false;
        useFeature4 = false;
        InitKeeperActions();
        TrophiesCollected = [];
        TrophiesCollected.push(
                false, false, false, false, false, 
                false, false, false, false, false
        );
        
        playerTeam = 0;
        opponentTeam = 1;
        InitTeamsOnce();
        hasPlayedIntro = false;
        gameMode = 0;
        takingADump = false;
    }
    
    public static var renderDebugMode : Int;
    public static var renderDebugModeMax : Int = 5;
    
    public static var patrolMarkers : Array<GameObj>;
    public static var jumpMarkers : Array<GameObj>;
    public static var runMarkers : Array<GameObj>;
    public static var footballGO : GameObj;
    
    public static var numHierarchiesRendered : Int;
    public static var numHierarchiesClipped : Int;
    public static function ExitForFrame()
    {
    }
    public static function InitForFrame()
    {
        numHierarchiesRendered = 0;
        numHierarchiesClipped = 0;
    }
    
    public static function InitForLevel_PostObjects()
    {
        patrolMarkers = GameObjects.GetGameObjVectorByName("patrol_marker");
        jumpMarkers = GameObjects.GetGameObjVectorByName("jump_marker");
        runMarkers = GameObjects.GetGameObjVectorByName("run_marker");
        footballGO = GameObjects.GetGameObjByName("football");
        CalculateNumLevelCoinsCollected();
    }
    
    
    public static function InitForLevel()
    {
        InitCoinsForLevel();
        renderDebugMode = 0;
        var l : Level = Levels.GetCurrent();
        
        fastforwardoffset = 0;
        doingFastForward = false;
        maxKicks = l.failKicks;
        goldKicks = l.goldKicks;
        
        numKicks = 0;
        
        numPigsActive = 0;
        totalGoals = 0;
        numRefsHit = 0;
        totalRefs = 0;
        numGoalsScored = 0;
        numAnimalsKilled = 0;
        pigsUsed = 0;
        upgradeTimer = 0;
        bossDefeated = false;
        snakeUpgrade = snakeUpgrade_None;
        collectedBonus = false;
    }
    
    
    public static var currentPickTeam : Int = 0;
    public static var currentEditTeamIndex : Int = 0;
    
    public static var teams : Array<TeamDef>;
    
    public static function GetTeam(index : Int) : TeamDef
    {
        return teams[index];
    }
    
    public static var playerTeam : Int;
    public static var opponentTeam : Int;
    
    public static function GetKitColorRGBArrayByIndex(index : Int) : Array<Dynamic>
    {
        return kitColors[index];
    }
    
    
    
    public static function ToSharedObject() : Dynamic
    {
        var o : Dynamic = {};
        
        o.hasPlayedIntro = hasPlayedIntro;
        
        
        
        
        
        o.teams = [];
        
        for (i in 0...teams.length)
        {
            var t : TeamDef = teams[i];
            var o1 : Dynamic = {};
            o1.kitColorShirt = t.kitColorShirt;
            o1.kitColorShorts = t.kitColorShorts;
            o1.kitColorSocks = t.kitColorSocks;
            o1.kitColorPattern = t.kitColorPattern;
            o1.kitStyle = t.kitStyle;
            o1.teamName = t.teamName;
            
            o.teams.push(o1);
        }
        
        o.useFeature1 = useFeature1;
        o.useFeature2 = useFeature2;
        o.useFeature3 = useFeature3;
        o.useFeature4 = useFeature4;
        
        o.TrophiesCollected = [];
        for (b/* AS3HX WARNING could not determine type for var: b exp: EIdent(TrophiesCollected) type: null */ in TrophiesCollected)
        {
            o.TrophiesCollected.push(b);
        }
        
        o.coinsTable = [];
        for (i/* AS3HX WARNING could not determine type for var: i exp: EIdent(coinsTable) type: null */ in coinsTable)
        {
            o.coinsTable.push(i);
        }
        
        
        /*
			o.upgradeLevels = new Array();
			o.sliderLevels = new Array();

			o.slot0 = saveSlots[0].Clone();
			o.slot1 = saveSlots[1].Clone();
			o.slot2 = saveSlots[2].Clone();
			o.slot3 = saveSlots[3].Clone();
			o.slot4 = saveSlots[4].Clone();

			for (var i:int = 0; i < 6; i++)
			{
				o.upgradeLevels.push(upgradeLevels[i]);
				o.sliderLevels.push(sliderLevels[i]);
			}
			*/
        
        return o;
    }
    
    public static function FromSharedObject(o : Dynamic)
    {
        if (o == null)
        {
            return;
        }
        
        hasPlayedIntro = o.hasPlayedIntro;
        
        
        
        
        
        for (i in 0...teams.length)
        {
            var t : TeamDef = teams[i];
            var o1 : Dynamic = o.teams[i];
            t.kitColorShirt = o1.kitColorShirt;
            t.kitColorShorts = o1.kitColorShorts;
            t.kitColorSocks = o1.kitColorSocks;
            t.kitColorPattern = o1.kitColorPattern;
            t.kitStyle = o1.kitStyle;
            t.teamName = o1.teamName;
        }
        
        
        useFeature1 = o.useFeature1;
        useFeature2 = o.useFeature2;
        useFeature3 = o.useFeature3;
        useFeature4 = o.useFeature4;
        
        TrophiesCollected = [];
        for (b/* AS3HX WARNING could not determine type for var: b exp: EField(EIdent(o),TrophiesCollected) type: null */ in (o.TrophiesCollected : Array<Dynamic>))
        {
            TrophiesCollected.push(b);
        }
        
        coinsTable = [];
        for (i/* AS3HX WARNING could not determine type for var: i exp: EField(EIdent(o),coinsTable) type: null */ in (o.coinsTable : Array<Dynamic>))
        {
            coinsTable.push(i);
        }
    }
    
    
    
    public static var parts_player : Array<Dynamic> = [
        "upperArmRight", 
        "upperArmRight.tint", 
        "upperArmRight.lines", 
        
        "lowerArmRight", 
        
        "upperLegRight", 
        "upperLegRight.tint", 
        "upperLegRight.lines", 
        
        "footRight", 
        "footRight.tint", 
        "footRight.lines", 
        
        "head", 
        
        "upperLegLeft", 
        "upperLegLeft.tint", 
        "upperLegLeft.lines", 
        
        "body", 
        "body.tint", 
        "body.tint_stripes", 
        "body.tint_hoops", 
        "body.lines", 
        
        "footLeft", 
        "footLeft.tint", 
        "footLeft.lines", 
        
        "upperArmLeft", 
        "upperArmLeft.tint", 
        "upperArmLeft.lines", 
        
        "lowerArmLeft"
    ];
    
    
    public static var clips_player : Array<Dynamic> = [
        "player_upperArm", 
        "tint_topArm", 
        "player_toparmLines", 
        
        "player_foreArm", 
        
        "player_topLeg", 
        "tint_topLeg", 
        "player_shortLines", 
        
        "player_foot", 
        "tint_socks", 
        "player_legLines", 
        
        "player_head", 
        
        "player_topLeg", 
        "tint_topLeg", 
        "player_shortLines", 
        
        "player_body", 
        "tint_shirtbase", 
        "tint_shirtStripes", 
        "tint_hoopsEXP", 
        "shirt_lines", 
        
        "player_foot", 
        "tint_socks", 
        "player_legLines", 
        
        "player_upperArm", 
        "tint_topArm", 
        "player_toparmLines", 
        
        "player_foreArm"
    ];
    
    
    public static var parts_ref : Array<Dynamic> = [
        "upperArmRight", 
        "lowerArmRight", 
        "upperLegRight", 
        "footRight", 
        "head", 
        "upperLegLeft", 
        "body", 
        "footLeft", 
        "upperArmLeft", 
        "lowerArmLeft"
    ];
    
    
    public static var clips_ref : Array<Dynamic> = [
        "ref_upperArm", 
        "ref_foreArm", 
        "ref_topLeg", 
        "ref_foot", 
        "ref_head", 
        "ref_topLeg", 
        "ref_body", 
        "ref_foot", 
        "ref_upperArm", 
        "ref_foreArm"
    ];
    
    public static var parts_keeper : Array<Dynamic> = [
        "upperArmRight", 
        "lowerArmRight", 
        "upperLegRight", 
        "footRight", 
        "head", 
        "upperLegLeft", 
        "body", 
        "footLeft", 
        "upperArmLeft", 
        "lowerArmLeft"
    ];
    
    
    public static var clips_keeper : Array<Dynamic> = [
        "keeper_upperArm", 
        "keeper_foreArm", 
        "keeper_topLeg", 
        "keeper_foot", 
        "keeper_head", 
        "keeper_topLeg", 
        "keeper_body", 
        "keeper_foot", 
        "keeper_upperArm", 
        "keeper_foreArm"
    ];
    
    
    public static function InitHierarchies()
    {
        hierarchy_player = new AnimHierarchy();
        hierarchy_player.Init(null, new Player(), parts_player, clips_player);
        hierarchy_ref = new AnimHierarchy();
        hierarchy_ref.Init(null, new Ref(), parts_ref, clips_ref);
        hierarchy_keeper = new AnimHierarchy();
        hierarchy_keeper.Init(null, new Keeper(), parts_keeper, clips_keeper);
    }
    public static var hierarchy_player : AnimHierarchy;
    public static var hierarchy_ref : AnimHierarchy;
    public static var hierarchy_keeper : AnimHierarchy;
    
    
    public static var oppo_kick_table : Array<Dynamic> = [
        new OppoKick(67, 14, -6), 
        new OppoKick(68, 23, -13), 
        new OppoKick(69, 30, -26)];
    
    
    
    public static var coinsTable : Array<Dynamic>;
    public static function InitCoinsForLevel()
    {
        totalLevelCoins = 0;
        currentCoinIndex = 0;
    }
    public static function InitCoinsOnce()
    {
        coinsTable = [];
    }
    
    public static var currentCoinIndex : Dynamic;
    public static var numLevelCoinsCollected : Dynamic;
    public static var totalLevelCoins : Dynamic;
    public static var totalGameCoins = 935;
    public static function CalculateNumCoinsInLevel()
    {
        var l : Level = Levels.GetCurrent();
        totalLevelCoins = l.totalCoins;
    }
    public static function CalculateNumLevelCoinsCollected()
    {
        numLevelCoinsCollected = 0;
        var num : Int = as3hx.Compat.parseInt(coinsTable.length / 2);
        for (i in 0...num)
        {
            if (coinsTable[(i * 2)] == Levels.currentIndex)
            {
                numLevelCoinsCollected++;
            }
        }
    }
    public static function GetTotalCoinsCollected() : Int
    {
        return as3hx.Compat.parseInt(coinsTable.length / 2);
    }
    public static function CollectCoin(coinIndex : Int)
    {
        coinsTable.push(Levels.currentIndex);
        coinsTable.push(coinIndex);
        CalculateNumLevelCoinsCollected();
    }
    public static function IsCoinCollected(coinIndex : Int) : Bool
    {
        var num : Int = as3hx.Compat.parseInt(coinsTable.length / 2);
        for (i in 0...num)
        {
            if (coinsTable[(i * 2)] == Levels.currentIndex)
            {
                if (coinsTable[(i * 2) + 1] == coinIndex)
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    
    public static var TrophiesCollected : Array<Dynamic>;
    
    public static function GetNumTrophies() : Int
    {
        var num : Int = 0;
        for (b in TrophiesCollected)
        {
            if (b == true)
            {
                num++;
            }
        }
        return num;
    }
    public static function HasTrophy(index : Int) : Bool
    {
        return TrophiesCollected[index];
    }
    public static function SetHasTrophy(index : Int)
    {
        TrophiesCollected[index] = true;
    }
    
    public static function InitCoinBoxClip(coinBox : MovieClip)
    {
        var a : Int = GetTotalCoinsCollected();
        var b : Int = totalGameCoins;
        
        (untyped coinBox).coinsCollected.text = a + "/" + b;
    }
    public static function InitTrophiesClip(trophies : MovieClip)
    {
        for (i in 0...10)
        {
            var mc : MovieClip = try cast(trophies.getChildByName("trophy" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            if (HasTrophy(i))
            {
                mc.filters = [];
            }
            else
            {
                mc.filters = [UI.blackFilter];
            }
        }
        (untyped trophies).numberText.text = Std.string(GetNumTrophies()) + "/10";
    }
    
    
    public static function KeeperNextAction(name : String, index : Int) : Int
    {
        for (i in 0...Std.int(keeperActions.length / 2))
        {
            var s : String = keeperActions[(i * 2) + 0];
            var a : Array<Dynamic> = keeperActions[(i * 2) + 1];
            if (s == name)
            {
                index++;
                if (index >= a.length)
                {
                    index = 0;
                }
            }
        }
        return index;
    }
    public static function GetKeeperAction(name : String, index : Int) : Point
    {
        for (i in 0...Std.int(keeperActions.length / 2))
        {
            var s : String = keeperActions[(i * 2) + 0];
            var a : Array<Dynamic> = keeperActions[(i * 2) + 1];
            if (s == name)
            {
                return a[index];
            }
        }
        return null;
    }
    public static var keeperActions : Array<Dynamic>;
    public static function InitKeeperActions()
    {
        keeperActions = [];
        keeperActions.push("stationary");
        keeperActions.push([new Point(0, -1)]);
        
        keeperActions.push("jump1");
        keeperActions = keeperActions.concat([[new Point(0, 3), new Point(1, 0)]]);
        
        keeperActions.push("crouch1");
        keeperActions = keeperActions.concat([[new Point(0, 3), new Point(2, 0)]]);
        
        keeperActions.push("jumpcrouch1");
        keeperActions = keeperActions.concat([[new Point(0, 3), new Point(1, 0), new Point(2, 0)]]);
        
    }
    public static function InitTeamsOnce()
    {
        teams = [];
        for (i in 0...9)
        {
            teams.push(new TeamDef());
        }
        
        teams[0].teamName = "ENgland";
        teams[0].kitColorPattern = 9;
        teams[0].kitColorShirt = 0;
        teams[0].kitColorShorts = 0;
        teams[0].kitColorSocks = 0;
        teams[0].kitStyle = 0;
        
        teams[1].teamName = "France";
        teams[1].kitColorPattern = 6;
        teams[1].kitColorShirt = 7;
        teams[1].kitColorShorts = 7;
        teams[1].kitColorSocks = 7;
        teams[1].kitStyle = 0;
        
        teams[2].teamName = "BRAZIL";
        teams[2].kitColorPattern = 0;
        teams[2].kitColorShirt = 3;
        teams[2].kitColorShorts = 6;
        teams[2].kitColorSocks = 0;
        teams[2].kitStyle = 0;
        
        teams[3].teamName = "NETHERLANDS";
        teams[3].kitColorPattern = 0;
        teams[3].kitColorShirt = 12;
        teams[3].kitColorShorts = 12;
        teams[3].kitColorSocks = 12;
        teams[3].kitStyle = 0;
        
        teams[4].teamName = "Germany";
        teams[4].kitColorPattern = 10;
        teams[4].kitColorShirt = 0;
        teams[4].kitColorShorts = 1;
        teams[4].kitColorSocks = 0;
        teams[4].kitStyle = 0;
        
        teams[5].teamName = "SPAIN";
        teams[5].kitColorPattern = 0;
        teams[5].kitColorShirt = 9;
        teams[5].kitColorShorts = 7;
        teams[5].kitColorSocks = 9;
        teams[5].kitStyle = 0;
        
        teams[6].teamName = "USA";
        teams[6].kitColorPattern = 8;
        teams[6].kitColorShirt = 0;
        teams[6].kitColorShorts = 0;
        teams[6].kitColorSocks = 0;
        teams[6].kitStyle = 1;
        
        teams[7].teamName = "GLASGOW";
        teams[7].kitColorPattern = 0;
        teams[7].kitColorShirt = 15;
        teams[7].kitColorShorts = 0;
        teams[7].kitColorSocks = 15;
        teams[7].kitStyle = 1;
        
        teams[8].teamName = "DESIGN YOUR OWN";
        teams[8].kitColorPattern = 6;
        teams[8].kitColorShirt = 13;
        teams[8].kitColorShorts = 10;
        teams[8].kitColorSocks = 15;
        teams[8].kitStyle = 1;
    }
    public static var kitColors : Array<Dynamic> = [
        [255, 255, 255], 
        [10, 10, 10], 
        [100, 100, 100], 
        [247, 245, 70], 
        
        [0, 173, 245], 
        [72, 117, 246], 
        [30, 76, 208], 
        [19, 21, 97], 
        
        [237, 28, 36], 
        [157, 10, 14], 
        [112, 36, 54], 
        [77, 3, 3], 
        
        [255, 78, 0], 
        [237, 20, 90], 
        [28, 185, 104], 
        [29, 124, 51]];
}


