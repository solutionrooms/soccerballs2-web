import flash.errors.Error;
import haxe.Constraints.Function;
import achievementPackage.Achievements;
import audioPackage.Audio;
import editorPackage.EdJoint;
import editorPackage.EdLine;
import editorPackage.EdObj;
import editorPackage.GameLayers;
import editorPackage.PhysEditor;
import editorPackage.PolyMaterial;
import editorPackage.PolyMaterials;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.filters.ColorMatrixFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.SoundChannel;
import flash.system.System;
import flash.ui.*;
import GameObj;
import licPackage.AdHolder;
import licPackage.Lic;
import licPackage.LicDef;
import nape.callbacks.BodyCallback;
import nape.constraint.AngleJoint;
import nape.constraint.Constraint;
import nape.constraint.DistanceJoint;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.GeomPoly;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.util.BitmapDebug;
import nape.util.Debug;
import Particles;
import textPackage.TextRenderer;
import textPackage.TextStrings;
import uIPackage.UI;

/**
	* ...
	* @author Default
	*/
class Game
{
    
    public static var saveTextureFiles : Bool = false;
    public static var loadTextureFiles : Bool = false;
    
    public static var doWalkthrough : Bool = false;
    public static var recordWalkthrough : Bool = false;
    public static var playbackWalkthrough : Bool = false;
    public static var usedebug : Bool = true;
    public static var soundon : Bool = true;
    
    public static var use_texturepages : Bool = false;
    public static var use_localisation : Bool = true;
    public static var load_vars_data : Bool = true;
    
    public static var controlMode : Int = 0;
    
    
    
    
    
    
    
    
    
    public static var debugPrint : Bool = false;
    public static var debugPrintError : Bool = true;
    
    public static var recordPlayer : Bool = false;
    
    public static var useLocalRuns : Bool = true;
    
    public static var unlockEverything : Bool = false;
    
    public static var doLevelEndTests : Bool = true;
    public static var onlyFinalLevels : Bool = true;
    
    public static var debugTest1 : Bool = false;
    public static var debugTest2 : Bool = false;
    public static var debugTest3 : Bool = false;
    
    public static var version : Float = 1;
    
    public static inline var gameState_UI = 0;
    public static inline var gameState_Play = 1;
    public static inline var gameState_Walkthrough = 2;
    
    public static inline var levelState_LevelStart = 0;
    public static inline var levelState_Play = 1;
    public static inline var levelState_Null = 2;
    public static inline var levelState_Editor = 3;
    public static inline var levelState_Complete = 4;
    public static inline var levelState_EndScreen = 5;
    public static inline var levelState_BonusSectionStart = 6;
    public static inline var levelState_BonusSection = 7;
    public static inline var levelState_PlayerDead = 8;
    
    
    public static var debugPlayerInvulnerable : Bool = false;
    
    public static var currentGameMusic : Int = 0;
    
    public static var frameSkip : Int = 1;
    
    public static var currentMC : MovieClip;
    public static var main : Main;
    public static var currentScore : Int = 0; // AS3 defaults int fields to 0; Haxe/JS leaves them null
    public static var levelScore : Int = 0;
    public static var scoreMultiplier : Int = 0;
    
    public static var numLevels : Int = 0;
    public static var numLives : Int = 0;
    public static var cash : Int = 0;
    
    public static var pause : Bool;
    public static var pauseGameplayInput : Bool;
    
    public static var goPlayer : GameObj = null;
    public static var levelTimer : Int = 0;
    
    public static var mapBD : BitmapData;
    public static var polyDOF : DisplayObjFrame;
    public static var backDOF : DisplayObjFrame;
    public static var backBD : BitmapData;
    public static var backgroundScreenBD : BitmapData;
    public static var polyScreenBD : BitmapData;
    public static var shadowScreenBD : BitmapData;
    public static var scrollScreenBD : BitmapData;
    public static var scrollScreenTempBD : BitmapData;
    public static var foregroundScreenBD : BitmapData;
    public static var flattenedScreenBD : BitmapData;
    public static var particleScreenBD : BitmapData;
    public static var layerScreenBD : BitmapData;
    public static var copyScreenBD : BitmapData;
    public static var fillScreenMC : MovieClip;
    public static var fillScreenMC1 : MovieClip;
    
    public static var camera : Camera;
    public static var boundingRectangle : Rectangle;
    
    public static var levelState : Int = 0;
    public static var gameState : Int = 0;
    public static var levelStateTimer : Int = 0;
    public static var levelStateCount : Int = 0;
    
    public static var objectDefs : PhysObjs;
    public static var physMaterials : Array<Dynamic>;
    
    
    public static var lastGeneratedGameObj : GameObj;
    public static var zsortoffset : Float = 0;
    public static var levelSuccessFlag : Bool;
    public static var levelFailReason : Int = 0;
    
    public static var levelJustUnlocked : Bool = false;
    
    public static var level_instances : Array<Dynamic>;
    
    public static var textFrameOffset : Int = 0;
    
    public static var currentBackground : Int = 0;
    
    public static var goCursor : GameObj;
    public static var goMarker : GameObj;
    
    public static var hudController : HudController;
    
    
    
    public static function InitOnce(_main : Main)
    {
        main = _main;
        currentScore = 0;
        scoreMultiplier = 1;
        numLevels = 8;
        Levels.currentIndex = 0;
        
        Vars.InitOnce();
        
        TextStrings.InitOnce();
        
        
        PolyMaterials.InitOnce(ExternalData.xml);
        ObjectParameters.InitOnce();
        PolyDefs.InitOnce();
        
        hudController = new HudController();
        hudController.InitOnce();
        gameState = gameState_UI;
        InitBitmaps();
        camera = new Camera();
        
        Grass.InitOnce();
        
        GameLayers.InitOnce(ExternalData.xml);
        
        LevelDobjCache.InitOnce();
        
        
        LoadPhysMaterials();
        
        
        objectDefs = new PhysObjs();
        objectDefs.InitFromXml(ExternalData.xml);
        
        GameVars.InitOnce();
        GameVars.InitHierarchies();

        // original: s3d.InitOnce(InitOnceA) — Stage3D init with a completion callback that chains
        // into InitGame()/StartTitleScreen(). The GPU path is dead (useStage3D=false), so we run the
        // callback synchronously. (fixup.sh previously stripped this line as dead Stage3D residue,
        // which silently dropped the entire title-screen kickoff. Called directly because the
        // lowercase `s3d` stub resolves as a package path, not a type.)
        InitOnceA();
    }

    public static function InitOnceA()
    {
        InitGame();
    }
    
    
    public static function InitBitmaps()
    {
        polyScreenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        backgroundScreenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        scrollScreenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        scrollScreenTempBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        copyScreenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        
        backDOF = new DisplayObjFrame();
        polyDOF = new DisplayObjFrame();
        
        
        fillScreenMC = new MovieClip();
        fillScreenMC.x = 0;
        fillScreenMC.y = 0;
        fillScreenMC1 = new MovieClip();
        fillScreenMC1.x = 0;
        fillScreenMC1.y = 0;
    }
    
    public static function StartTitleScreen()
    {
        gameState = gameState_UI;
        main.ClearStage();
        if (doWalkthrough)
        {
            Walkthrough.InitScreens();
            UI.StartTransition("preparingscreen");
        }
        else
        {
            UI.StartTransition("preparingscreen");
        }
    }
    
    
    
    
    public static function InitGame()
    {
        gameState = gameState_Play;
        
        
        
        EngineDebug.debugMode = 0;
        numLives = 3;
        
        Levels.currentIndex = 0;
        
        pause = true;
        
        cash = 0;
        
        currentGameMusic = 0;
        
        Levels.LoadAll();
        WalkthroughRecordings.InitOnce();
        Achievements.InitOnce();
        
        
        
        
        
        
        CustomCursor.InitOnce();
        
        Particles.Reset();
        MouseControl.Reset();
        Particles.Reset();
        GameObjects.ClearAll();
        
        HintPopups.InitOnce();
        
        ResetEverything();
        SaveData.Load();
        SubmitStats();
        Audio.PlayMusic("menus_music");
        
        StartTitleScreen();
    }
    
    public static function FindObjInInstances(l : Level, name : String) : Bool
    {
        for (inst/* AS3HX WARNING could not determine type for var: inst exp: EField(EIdent(l),instances) type: null */ in l.instances)
        {
            if (inst.typeName == name)
            {
                return true;
            }
        }
        return false;
    }
    
    
    public static function ReloadData()
    {
        ExternalData.Load(ReloadData_Done);
    }
    public static function ReloadData_Done()
    {
    }
    
    
    
    public static function Reload(_func : Function)
    {
        ExternalData.Load(_func);
    }
    
    
    
    public static function GetPhysMaterialByName(name : String) : PhysObjMaterial
    {
        for (mat in physMaterials)
        {
            if (mat.name == name)
            {
                return mat;
            }
        }
        Utils.traceerror("ERROR, missing physics material: " + name);
        return new PhysObjMaterial();
    }
    public static function LoadPhysMaterials()
    {
        physMaterials = [];
        var i : Int = 0;        var x : FastXML = ExternalData.xml;
        
        for (i in 0...x.nodes.material.length())
        {
            var px : FastXML = x.nodes.material.get(i);
            var mat : PhysObjMaterial = new PhysObjMaterial();
            mat.FromXML(px);
            physMaterials.push(mat);
        }
    }
    
    
    public static function AddGameObjectAt(objName : String, _x : Float, _y : Float, _rotDeg : Float, _scale : Float, instanceName : String = "", initParams : String = "", _id : String = "") : GameObj
    {
        var go : GameObj = null;
        var physobj : PhysObj = objectDefs.FindByName(objName);
        if (physobj.graphics.length != 0)
        {
            var graphic : PhysObjGraphic = physobj.graphics[0];
            go = GameObjects.AddObj(_x, _y, graphic.zoffset + zsortoffset);
            
            Utils.GetParams(initParams);
            var layerZpos : Float = GameLayers.GetZPosByName(Utils.GetParamString("game_layer"));
            go.zpos = layerZpos + zsortoffset;
            
            go.dobj = GraphicObjects.GetDisplayObjByName(graphic.graphicName);
            go.frame = graphic.frame;
            go.dir = Utils.DegToRad(_rotDeg);
            go.scale = _scale;
            go.initParams = initParams;
            go.id = _id;
            
            if (graphic.goInitFuntion != "")
            {
                go.initFunctionVarString = graphic.goInitFuntionVarString;
                Reflect.callMethod(go, Reflect.field(go, graphic.goInitFuntion), []);
            }
        }
        try
        {
            if (physobj.initFunctionName != "")
            {
                go.initFunctionVarString = physobj.initFunctionParameters;
                Reflect.callMethod(go, Reflect.field(go, physobj.initFunctionName), []);
            }
        }
        catch (err : Error)
        {
            Utils.print("init function doesn't exist: " + physobj.initFunctionName);
        }
        
        return go;
    }
    
    
    
    
    
    public static function GetLineListByType(_type : Int) : Array<Dynamic>
    {
        var list : Array<Dynamic> = [];
        var l : Level = Levels.GetCurrent();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == _type)
            {
                list.push(line);
            }
        }
        return list;
    }
    
    public static function GetNumLinesByType(_type : Int) : Int
    {
        var count : Int = 0;
        var l : Level = Levels.GetCurrent();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == _type)
            {
                count++;
            }
        }
        return count;
    }
    
    
    public static function GetNearestPathLine(x : Float, y : Float) : Int
    {
        var nearestD : Float = 999999;
        var nearestL : Int = 0;
        
        var count : Int = 0;
        var l : Level = Levels.GetCurrent();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == 1)
            {
                var d : Float = Utils.DistBetweenPoints(x, y, line.points[0].x, line.points[0].y);
                if (d < nearestD)
                {
                    nearestD = d;
                    nearestL = count;
                }
            }
            count++;
        }
        return nearestL;
    }
    
    public static function GetLineIndexByTypeIndex(_type : Int, _typeIndex : Int) : Int
    {
        var count : Int = 0;
        var lcount : Int = 0;
        var l : Level = Levels.GetCurrent();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == _type)
            {
                if (count == _typeIndex)
                {
                    return lcount;
                }
                count++;
            }
            lcount++;
        }
        return 0;
    }
    
    
    public static function GetLineByIndex(_index : Int) : EdLine
    {
        var l : Level = Levels.GetCurrent();
        return l.lines[_index];
    }
    
    
    
    
    
    public static function NextLevel() : Void
    {
        Audio.StopAllSFX();
        Levels.IncrementLevel();
        StartLevel();
    }
    public static function RestartLevel() : Void
    {
        UI.StartTransition("gamescreen");
    }
    
    
    
    public static function InitLevelGameplay()
    {
    }
    
    
    
    public static function scoreOverlay_EnterFrame(e : Event)
    {
        var mc : MovieClip = try cast(e.target, MovieClip) catch(e:Dynamic) null;
        if (mc.currentFrame == mc.totalFrames)
        {
            mc.stop();
            mc.visible = false;
        }
    }
    
    
    public static function UpdateLevel()
    {
    }
    
    
    /*
		static function InitPhysicsGO(x:Number, y:Number,graphic:PhysObjGraphic,_gid:int = 0,_frame:int = 0,_zpos:Number=0):int
		{
			var go:GameObj;

			_zpos += graphic.zoffset;

			if (graphic == null)
			{
				go = GameObjects.AddObj(x*PhysicsBase.p2w, y*PhysicsBase.p2w, _zpos+zsortoffset);
				go.InitPhysicsObject(_gid, _frame,0,0,"",false);
			}
			else
			{
				if (graphic.goInitFuntion == "")
				{
					go = GameObjects.AddObj(x*PhysicsBase.p2w, y*PhysicsBase.p2w, _zpos+zsortoffset);
					go.InitPhysicsObject(_gid, _frame,graphic.offset.x,graphic.offset.y,graphic.goInitFuntionVarString,graphic.hasShadow);
				}
				else
				{
					go = GameObjects.AddObj(x*PhysicsBase.p2w, y*PhysicsBase.p2w, _zpos+zsortoffset);
					go.InitPhysicsObject(_gid, _frame,graphic.offset.x,graphic.offset.y,graphic.goInitFuntionVarString,graphic.hasShadow);
					go.initFunctionVarString = graphic.goInitFuntionVarString;
					Reflect.callMethod(go, Reflect.field(go, graphic.goInitFuntion), []);
				}
			}
			lastGeneratedGameObj = go;
			return GameObjects.lastGenIndex;
		}
		*/
    
    
    
    
    
    
    
    public static function InitLevelState(s : Int)
    {
        trace("[SB2] InitLevelState(" + s + ") successFlag=" + levelSuccessFlag + " gameState=" + gameState + " numKicks=" + GameVars.numKicks + "/" + GameVars.maxKicks);
        levelState = s;
        levelStateTimer = 0;
        if (levelState == levelState_LevelStart)
        {
            levelState = levelState_Play;
        }
        if (levelState == levelState_Complete)
        {
            if (recordWalkthrough)
            {
                WalkthroughRecordings.AddRecording(walkthroughRecording);
            }
            
            levelStateTimer = 0;
            
            if (levelSuccessFlag == true)
            {
                DoEndLevelStuff();
            }
        }
        if (levelState == levelState_EndScreen)
        {
            SaveData.Save();
            InitLevelState(levelState_Null);
            
            if (levelSuccessFlag == true)
            {
                UI.StartTransitionImmediate("levelcomplete");
            }
            else
            {
                UI.StartTransitionImmediate("levelfailed");
            }
        }
        
        
        if (levelState == levelState_PlayerDead)
        {
            levelTimer = as3hx.Compat.parseInt(Defs.fps * 1.5);
        }
        if (levelState == levelState_BonusSection)
        {
            levelTimer = as3hx.Compat.parseInt(Defs.fps * 10);
        }
        if (levelState == levelState_Play)
        {
            levelStateTimer = 0;
        }
        if (levelState == levelState_Editor)
        {
            PhysEditor.InitEditor(camera.x, camera.y);
            PhysEditor.currentLevel = Levels.currentIndex;
        }
    }
    
    
    public static function LevelFailed()
    {
        InitLevelState(levelState_Null);
        UI.StartTransition("levelfailed");
    }
    
    
    
    public static function ResetEverything()
    {
        Levels.ClearAll();
        Levels.GetLevel(0).available = true;
        Levels.GetLevel(0).locked = false;
        Levels.GetLevel(0).newlyAvailable = true;
        Levels.currentIndex = 0;
        CalculateScore();
        Achievements.ClearAll();
        GameVars.ResetEverything();
        HintPopups.ResetEverything();
        cash = 0;
        currentScore = 0;
        if (unlockEverything)
        {
            cash = 100000;
        }
    }
    
    
    
    public static var killScore : Int = 0;
    public static var rating : Int = 0;
    public static var endLevelScore : Int = 0;
    
    
    public static function DoEndLevelStuff()
    {
        if (levelTimer < 0)
        {
            levelTimer = 0;
        }
        
        var l : Level = Levels.GetCurrent();
        l.complete = true;
        
        l.newlyAvailable = false;
        
        if (GameVars.collectedBonus)
        {
            l.gotBonus = true;
        }
        
        var rating : Int = 0;
        if (GameVars.numKicks <= GameVars.goldKicks)
        {
            rating = 1;
        }
        
        if (GameVars.numKicks < l.bestShots)
        {
            l.bestShots = GameVars.numKicks;
        }
        
        if (rating > l.rating)
        {
            l.rating = rating;
        }
        
        var unlockedLevels : Array<Dynamic> = GameVars.GetUnlockedLevels(Levels.currentIndex + 1);
        for (levelID in unlockedLevels)
        {
            levelJustUnlocked = false;
            l.levelScore = levelScore;
            var l1 : Level = Levels.GetLevel(Std.int(levelID - 1));
            if (l1 != null)
            {
                if (l1.available == false)
                {
                    levelJustUnlocked = true;
                    l1.newlyAvailable = true;
                }
                Utils.print("making available " + l1.id);
                l1.available = true;
            }
        }
        
        /*
			var cl:int = Levels.currentIndex;
			Levels.IncrementLevel();
			levelJustUnlocked = false;
			l.levelScore = levelScore;

			var l1:Level = Levels.GetLevel(Levels.currentIndex);
			if (l1 != null)
			{
				if (l1.available == false)
				{
					levelJustUnlocked = true;
					l1.newlyAvailable = true;
				}
				Utils.trace("making available " + l1.id);
				l1.available = true;
			}
			Levels.currentIndex = cl;
			*/
        
        
        
        
        if (levelScore > l.bestScore)
        {
            l.bestScore = levelScore;
        }
        
        
        CalculateScore();
        
        
        SubmitStats();
    }
    
    public static function SubmitMinigameStats()
    {
    }
    
    public static function SubmitStats()
    {
        var l : Level = null;        
        
        
        
        
        
        Lic.Kongregate_SubmitStat(currentScore, "highscore");
        
        
        var totalcoins : Int = GameVars.GetTotalCoinsCollected();
        Lic.Kongregate_SubmitStat(totalcoins, "totalcoins");
        
        var totalcups : Int = GameVars.GetNumTrophies();
        Lic.Kongregate_SubmitStat(totalcups, "totalcups");
        
        var numcomplete : Int = 0;
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            if (l.complete)
            {
                numcomplete++;
            }
        }
        Lic.Kongregate_SubmitStat(numcomplete, "numcomplete");
    }
    
    
    public static function GetHighestScore() : Int
    {
        var bestScore : Int = 0;
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            if (l.bestScore > bestScore)
            {
                bestScore = l.bestScore;
            }
        }
        return bestScore;
    }
    
    public static function GetNumLevelsUnlocked() : Int
    {
        var num : Int = 0;
        for (l/* AS3HX WARNING could not determine type for var: l exp: EField(EIdent(Levels),list) type: null */ in Levels.list)
        {
            if (l.available)
            {
                num++;
            }
        }
        return num;
    }
    
    
    
    public static var numGolds : Int = 0;
    public static function CalculateScore()
    {  /*
			currentScore = 0;
			for each(var l:Level in Levels.list)
			{
				currentScore += l.bestScore;
				if (l.rating != 0) numGolds++;
			}
			*/  
        
    }
    
    public static function GetSwitchJointName(name : String) : String
    {
        if (name == "")
        {
            return "";
        }
        var l : Level = Levels.GetCurrent();
        var jointList : Array<Dynamic> = Levels.GetCurrentLevelJoints();
        
        var p : Point = null;        var p1 : Point = null;        
        for (joint in jointList)
        {
            if (joint.type == EdJoint.Type_Switch)
            {
                if (joint.obj0Name == name)
                {
                    return joint.obj1Name;
                }
                if (joint.obj1Name == name)
                {
                    return joint.obj0Name;
                }
            }
        }
        return "";
    }
    
    
    public static function InitLevelPlayFromEditorObjects()
    {
        zsortoffset = 0;
        
        level_instances = Levels.GetCurrentLevelInstances();
        for (inst in level_instances)
        {
            var physobj : PhysObj = objectDefs.FindByName(inst.typeName);
            
            if (physobj.bodies.length == 0)
            {
                AddGameObjectAt(inst.typeName, inst.x, inst.y, inst.rot, inst.scale, inst.instanceName, inst.objParameters.ToString(), inst.id);
                zsortoffset += 0.01;
            }
            else if (physobj.graphics.length != 0)
            {
                AddGameObjectAt(inst.typeName, inst.x, inst.y, inst.rot, inst.scale, inst.instanceName, inst.objParameters.ToString(), inst.id);
                zsortoffset += 0.01;
            }
            else
            {
                PhysicsBase.AddPhysObjAt(inst.typeName, inst.x, inst.y, inst.rot, inst.scale, inst.instanceName, inst.objParameters.ToString(), inst.id);
                zsortoffset += 0.01;
            }
        }
    }
    
    
    
    
    
    
    public static function GetMapData(x : Int, y : Int) : Int
    {
        var l : Level = Levels.GetCurrent();
        x = Std.int(x / l.mapCellW);
        y = Std.int(y / l.mapCellH);
        if (x < l.mapMinX || x > l.mapMaxX || y < l.mapMinY || y > l.mapMaxY)
        {
            return 0;
        }
        var w : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        x -= l.mapMinX;
        y -= l.mapMinY;
        return l.map[x + (y * w)];
    }
    
    
    public static var goBackground : GameObj;
    public static var goPolyLayer : GameObj;
    
    
    
    public static function StopLevel()
    {
        HintPopups.ExitForLevel();
        LevelDobjCache.ExitForLevel();
        Audio.StopAllSFX();
        gameState = gameState_UI;
    }
    
    
    public static var doingWalkthrough : Bool;
    public static function StartLevel(_doingWalkthrough : Bool = false) : Void
    {
        doingWalkthrough = _doingWalkthrough;
        
        StartLevelA();
        
        var a : Int = 0;
    }
    public static function StartLevelA() : Void
    {
        
        
        LevelDobjCache.InitForLevel();
        
        Grass.InitForLevel();
        
        
        gameState = gameState_Play;
        
        
        Mouse.show();
        var go : GameObj = null;        
        KeyReader.InitOnce(main.stage);
        
        
        
        
        QuietAllSounds();
        
        
        boundingRectangle = new Rectangle(-10000, -10000, 20000, 20000);
        
        textFrameOffset = 0;
        
        
        var l : Level = Levels.GetCurrent();
        
        Particles.Reset();
        PhysicsBase.Init();
        
        camera.ResetBounds();
        
        GameVars.InitForLevel();
        
        GameObjects.ClearAll();
        
        InitLevelState(levelState_LevelStart);
        
        InitLevelPlayFromEditorObjects();
        PhysicsBase.InitLines();
        PhysicsBase.InitJoints();
        
        
        
        
        pause = false;
        pauseGameplayInput = false;
        
        
        
        levelTimer = 0;
        
        levelScore = 0;
        
        if (doingWalkthrough == false)
        {
            currentMC.addChild(hudController.hudMC);
        }
        
        
        
        
        
        
        
        
        if (new EReg("Boss", "").match(l.name))
        {
            Audio.PlayMusic("music_boss");
        }
        else
        {
            Audio.PlayMusic("music_ingame1");
        }
        
        currentGameMusic++;
        if (currentGameMusic >= 2)
        {
            currentGameMusic = 0;
        }
        
        
        
        
        
        
        
        scoreMultiplier = 1;
        
        InitLevelGameplay();
        
        
        
        
        
        
        goPolyLayer = GameObjects.AddObj(0, 0, 0);
        goPolyLayer.InitPolyLayer();
        
        go = GameObjects.AddObj(0, 0, -10000);
        go.InitFastForward();
        
        
        
        
        
        
        
        InitControl();
        
        
        
        
        Grass.PreRenderLines();
        var goGrass : GameObj = GameObjects.AddObj(0, 0, -10);
        goGrass.InitGrass();
        
        
        StartLevelSounds();
        hudController.SetupMuteButtons();
        
        
        
        
        
        hudController.Update();
        
        
        InitScroll();
        
        createdForegroundBitmaps = false;
        
        hudController.InitForLevel();
        
        Achievements.ResetForLevel();
        
        
        
        HintPopups.InitForLevel();
        
        
        
        CustomCursor.Use(true);
        
        
        if (false)
        {
            backDOF = GraphicObjects.GetDisplayObjByName("backgrounds").GetFrame(currentBackground);
        }
        else
        {
            if (backgroundsMC == null)
            {
                backgroundsMC = new Backgrounds();
            }
            
            
            backBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, false, 0x0);
            backBD.fillRect(backBD.rect, 0);
            backgroundsMC.gotoAndStop(currentBackground + 1);
            backBD.draw(backgroundsMC);
            
            
            
            backDOF.CreateStandalone(backBD, 0, 0);
            backDOF.ReUploadBitmap(backBD);
            
            
            
            
            
            InitClouds();
        }
        polyDOF.CreateStandalone(polyScreenBD, 0, 0);
        polyDOF.ReUploadBitmap(polyScreenBD);
        
        
        GameVars.grassFrame = Levels.currentIndex % 4;
        GameVars.dirtFrame = Levels.currentIndex % 3;
        
        if (recordWalkthrough)
        {
            walkthroughRecording = new WalkthroughRecording(l.name);
        }
        if (playbackWalkthrough)
        {
            walkthroughRecording = WalkthroughRecordings.GetByLevelName(l.name);
            
            if (walkthroughRecording == null)
            {
                playbackWalkthrough = false;
            }
            else
            {
                walkthroughRecording.StartPlayback();
            }
            walkthroughCursorGO = GameObjects.AddObj(0, 0, -10000);
            walkthroughCursorGO.InitPlaybackCursor();
        }
        
        InitBallPathForLevel();
        
        
        
        if (false)
        {
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, MouseMoveHandler);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, MouseClickHandler);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, MouseUpHandler);
        }
        
        
        GameVars.InitForLevel_PostObjects();
    }
    public static var walkthroughCursorGO : GameObj;
    public static var walkthroughRecording : WalkthroughRecording;
    
    public static var backgroundsMC : MovieClip = null;
    
    
    public static function InitClouds()
    {
        var totalClouds : Int = 30;
        for (i in 0...totalClouds)
        {
            var go : GameObj = GameObjects.AddObj(0, 0, 0);
            go.InitCloud();
        }
    }
    
    
    public static function PreRenderPolys()
    {
        camera.x = 0;
        camera.y = 0;
        camera.scale = 1;
        
        polyScreenBD.fillRect(Defs.screenRect, 0);
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active)
            {
                if (go.preRenderFunction != null)
                {
                    go.bd = polyScreenBD;
                    go.preRenderFunction();
                }
            }
        }
    }
    
    public static function InitBackgroundSounds()
    {
    }
    
    public static function QuietAllSounds()
    {
    }
    
    
    public static function StopAllLoops()
    {
    }
    
    
    public static function StartLevelSounds()
    {
    }
    
    
    
    
    
    
    
    public static var currentWalkthroughRecordingPoint : WalkthroughRecordingPoint = null;
    public static var testTextureFrame : Int = 0;
    
    public static function UpdateGameplay() : Void
    {
        EngineDebug.StartTimers();
        
        EngineDebug.StartTimer("gameplay");
        
        
        var numLoops : Int = 1;
        if (false)
        {
            numLoops = 2;
        }
        if (GameVars.doingFastForward)
        {
            numLoops = GameVars.fastForward_numskips;
        }
        for (loopCount in 0...numLoops)
        {
            if (gameState == gameState_UI)
            {
                return;
            }
            
            if (gameState == gameState_Walkthrough)
            {
                if (usedebug)
                {
                    if (KeyReader.Pressed(KeyReader.KEY_W))
                    {
                        gameState = gameState_Play;
                        doWalkthrough = false;
                        UI.StartTransition("gamescreen");
                        return;
                    }
                }
                
                UpdateScroll_Walkthrough();
                GameObjects.UpdateWalkthroughObjects();
                
                return;
            }
            
            if (pause)
            {
                return;
            }
            
            if (usedebug)
            {
                if (KeyReader.Pressed(KeyReader.KEY_V))
                {
                    Vars.ReloadXML();
                    Vars.TraceAll();
                }
            }
            
            if (PauseMenu.IsPaused())
            {
                return;
            }
            if (levelState == levelState_EndScreen)
            {
                return;
            }
            if (levelState == levelState_Null)
            {
                return;
            }
            if (levelState == levelState_Editor)
            {
                PhysEditor.UpdateEditor();
                return;
            }
            
            
            if (usedebug)
            {
                if (KeyReader.Pressed(KeyReader.KEY_W))
                {
                    KeyReader.ClearKey(KeyReader.KEY_W);
                    gameState = gameState_UI;
                    doWalkthrough = true;
                    Walkthrough.InitScreen();
                    gameState = gameState_UI;
                    
                    UI.StartTransition("walkthrough_screen");
                    gameState = gameState_UI;
                    return;
                }
                
                if (KeyReader.Pressed(KeyReader.KEY_F))
                {
                }
                if (KeyReader.Pressed(KeyReader.KEY_S))
                {
                }
                if (KeyReader.Pressed(KeyReader.KEY_SPACE))
                {
                    Mouse.cursor = MouseCursor.AUTO;
                    InitLevelState(levelState_Editor);
                }
                if (KeyReader.Pressed(KeyReader.KEY_C))
                {
                    InitClouds();
                }
            }
            
            
            var numUpdates : Int = 1;
            
            
            if (usedebug)
            {
                if (KeyReader.Pressed(KeyReader.KEY_1))
                {
                    EngineDebug.debugMode = EngineDebug.debugMode ^ 1;
                }
                if (KeyReader.Pressed(KeyReader.KEY_2))
                {
                    EngineDebug.debugMode = EngineDebug.debugMode ^ 2;
                }
                if (KeyReader.Pressed(KeyReader.KEY_3))
                {
                    EngineDebug.debugMode = EngineDebug.debugMode ^ 4;
                }
                if (KeyReader.Pressed(KeyReader.KEY_4))
                {
                    EngineDebug.debugMode = EngineDebug.debugMode ^ 8;
                }
                
                if (KeyReader.Pressed(KeyReader.KEY_6))
                {
                }
                if (KeyReader.Pressed(KeyReader.KEY_7))
                {
                    RestartLevel();
                }
                
                
                if (KeyReader.Pressed(KeyReader.KEY_8))
                {
                    Levels.DecrementLevel();
                    RestartLevel();
                }
                if (KeyReader.Pressed(KeyReader.KEY_9))
                {
                    NextLevel();
                }
            }
            
            if (levelState == levelState_Play)
            {
                if (levelStateTimer == 1)
                {
                }
                levelStateTimer++;
            }
            if (levelState == levelState_LevelStart)
            {
            }
            
            
            
            
            
            
            if (levelState == levelState_Play || levelState == levelState_BonusSection)
            {
                if (playbackWalkthrough)
                {
                    if (walkthroughRecording != null)
                    {
                        var wpos : WalkthroughRecordingPoint = walkthroughRecording.GetNextPoint();
                        currentWalkthroughRecordingPoint = wpos.Clone();
                        MouseControl.x = wpos.x;
                        MouseControl.y = wpos.y;
                        MouseControl.buttonPressed = wpos.mouseButton;
                        walkthroughCursorGO.xpos = wpos.x;
                        walkthroughCursorGO.ypos = wpos.y;
                        
                        if (wpos.mouseButton)
                        {
                            var go : GameObj = GameObjects.AddObj(wpos.x, wpos.y, -11000);
                            go.InitPlaybackClick();
                        }
                    }
                }
                
                UpdateControl();
            }
            
            
            if (recordWalkthrough)
            {
                if (walkthroughRecording != null)
                {
                    walkthroughRecording.Add(Std.int(MouseControl.x), Std.int(MouseControl.y), buttonClickedThisUpdate);
                }
            }
            
            
            var gravity : Float = Vars.GetVarAsNumber("gravity");
            PhysicsBase.SetGravity(gravity);
            
            EngineDebug.StartTimer("nape");
            GameObjects.PreUpdateGOsBeforePhysics();
            PhysicsBase.TimeStep();
            GameObjects.UpdateGOsFromPhysics_Nape();
            EngineDebug.EndTimer("nape");
            
            if (levelState == levelState_Play || levelState == levelState_LevelStart || levelState == levelState_Complete || levelState == levelState_BonusSection || levelState == levelState_BonusSectionStart)
            {
                EngineDebug.StartTimer("update GOs");
                GameObjects.ClearAddList();
                GameObjects.Update();
                GameObjects.KillObjects();
                GameObjects.DoAddList();
                Particles.Update();
                hudController.Update();
                EngineDebug.EndTimer("update GOs");
            }
            
            
            
            if (levelState == levelState_Play)
            {
                levelTimer++;
                
                
                
                if (doLevelEndTests && (doWalkthrough == false))
                {
                    var gotRefs : Bool = true;
                    if (GameVars.totalRefs > 0)
                    {
                        gotRefs = false;
                        if (GameVars.numRefsHit >= GameVars.totalRefs)
                        {
                            gotRefs = true;
                        }
                    }
                    if (GameVars.totalGoals > 0)
                    {
                        if (GameVars.numGoalsScored >= GameVars.totalGoals)
                        {
                            if (gotRefs)
                            {
                                levelSuccessFlag = true;
                                Audio.OneShot("sfx_levelcomplete");
                                InitLevelState(levelState_Complete);
                            }
                        }
                    }
                }
            }
            
            
            if (levelState == levelState_Complete)
            {
                Achievements.TestAll();
                
                
                var stillUpdating : Bool = Achievements.UpdateDisplayQueue();
                
                levelStateTimer++;
                var time : Int = as3hx.Compat.parseInt(Defs.fps * 1);
                
                
                if (levelStateTimer > time && stillUpdating == false)
                {
                    InitLevelState(levelState_EndScreen);
                }
            }
            
            if (levelState == levelState_PlayerDead)
            {
            }
            
            
            
            
            
            UpdateScroll();
            
            if (playbackWalkthrough)
            {
                if (walkthroughRecording != null)
                {
                    if (walkthroughRecording.HasFinished())
                    {
                        var w : WalkthroughScreen = Walkthrough.walkthroughScreens[Levels.currentIndex];
                        w.StopPlayback();
                        UI.StartTransition("walkthrough");
                    }
                }
            }
        }
        EngineDebug.EndTimer("gameplay");
    }
    
    
    public static function InitCreateForegroundBitmaps()
    {
    }
    
    public static var createdForegroundBitmaps : Bool = false;
    public static var scrollFirstTime : Bool;
    public static function InitScroll()
    {
        scrollFirstTime = true;
    }
    
    
    public static function UpdateScroll_Garage()
    {
        var go : GameObj = GameObjects.GetGameObjByName("player");
        if (go == null)
        {
            return;
        }
        
        camera.x = go.xpos - Defs.displayarea_w / 2;
        camera.y = go.ypos - Defs.displayarea_w / 2;
    }
    
    
    public static var scrollMode : Int = 0;
    public static var scrollDragX : Float;
    public static var scrollDragY : Float;
    public static var doKick : Bool = false;
    
    public static var mouse_ox : Float = 0;
    public static var mouse_oy : Float = 0;
    public static var mouse_x : Float = 0;
    public static var mouse_y : Float = 0;
    public static var mouse_dx : Float = 0;
    public static var mouse_dy : Float = 0;
    
    public static function MouseMoveHandler(event : MouseEvent) : Void
    {
        var go : GameObj = GameVars.footballGO;
        if (go == null)
        {
            return;
        }
        
        var scalex : Float = ScreenSize.fullScreenScale;
        var scaley : Float = ScreenSize.fullScreenScale;
        
        var mx : Float = Math.NaN;        var my : Float = Math.NaN;        
        mouse_ox = mouse_x;
        mouse_oy = mouse_y;
        
        mx = Utils.ScaleToPreLimit(0, Defs.displayarea_w, ScreenSize.fullScreenScaleXOffset, ScreenSize.gameStageWidth - ScreenSize.fullScreenScaleXOffset, event.stageX);
        my = Utils.ScaleToPreLimit(0, Defs.displayarea_h, 0, ScreenSize.gameStageHeight, event.stageY);
        
        mouse_dx = mx - mouse_ox;
        mouse_dy = my - mouse_oy;
        mouse_x = mx;
        mouse_y = my;
        
        var cx : Float = Defs.displayarea_w / 2;
        var cy : Float = Defs.displayarea_h / 2;
        
        if (controlMode == 1)
        {
            if (scrollMode == 0)
            {
            }
            else if (scrollMode == 1)
            {
                camera.x -= mouse_dx;
                camera.y -= mouse_dy;
                Utils.print("mouse_dx " + mouse_dx + "   " + mx);
                Utils.print("mouse_dy " + mouse_dy + "   " + my);
            }
            else if (scrollMode == 2)
            {
                var scaler : Float = 0.4;
                var dx : Float = cx - mouse_x;
                var dy : Float = cy - mouse_y;
                camera.x = (go.xpos + (dx * scaler)) - cx;
                camera.y = (go.ypos + (dy * scaler)) - cy;
            }
        }
    }
    
    
    
    public static function MouseClickHandler(event : MouseEvent) : Void
    {
        if (OptionsScreen.open) return; // options overlay is modal — don't let clicks reach gameplay
        if (true)
        {
            if (event.stageX < 100 && event.stageY < 100)
            {
                hudController.CycleDebugModes();
            }
            if (event.stageX < 100 && event.stageY > 300)
            {
                GameVars.renderDebugMode++;
                if (GameVars.renderDebugMode >= GameVars.renderDebugModeMax)
                {
                    GameVars.renderDebugMode = 0;
                }
            }
        }
        
        var go : GameObj = GameVars.footballGO;
        if (go == null)
        {
            return;
        }
        if (controlMode == 0 && Settings.mobileControlScheme != Settings.SCHEME_B && Settings.mobileControlScheme != Settings.SCHEME_C)
        {
            // schemes B/C route kicks through their own handler (tap), not a raw pointer-down click
            doKick = true;
        }
        if (controlMode == 1)
        {
            if (scrollMode == 0)
            {
                if (Utils.DistBetweenPoints(mouse_x + camera.x, mouse_y + camera.y, go.xpos, go.ypos) < 50)
                {
                    scrollMode = 2;
                }
                else
                {
                    scrollMode = 1;
                }
            }
            else if (scrollMode == 1)
            {
            }
            else if (scrollMode == 2)
            {
            }
        }
    }
    
    
    public static function MouseUpHandler(event : MouseEvent) : Void
    {
        if (OptionsScreen.open) return; // options overlay is modal
        if (controlMode == 0)
        {
        }
        if (controlMode == 1)
        {
            if (scrollMode == 0)
            {
            }
            else if (scrollMode == 1)
            {
                scrollMode = 0;
            }
            else if (scrollMode == 2)
            {
                scrollMode = 0;
                doKick = true;
            }
        }
    }
    
    
    
    public static function UpdateScroll_Walkthrough()
    {
        mouse_x = MouseControl.x;
        mouse_y = MouseControl.y;
        var v : Vec = new Vec();
        v.SetFromDxDy(mouse_x - Defs.displayarea_w2, mouse_y - Defs.displayarea_h2);
        v.speed *= 0.04;
        camera.x += v.X();
        camera.y += v.Y();
        
        if (camera.x < boundingRectangle.x)
        {
            camera.x = boundingRectangle.x;
        }
        if (camera.y < boundingRectangle.y)
        {
            camera.y = boundingRectangle.y;
        }
        
        if (camera.x + Defs.displayarea_w > boundingRectangle.right)
        {
            camera.x = boundingRectangle.right - Defs.displayarea_w;
        }
        if (camera.y + Defs.displayarea_h > boundingRectangle.bottom)
        {
            camera.y = boundingRectangle.bottom - Defs.displayarea_h;
        }
    }
    public static function UpdateScroll()
    {
        if (controlMode == 1)
        {
            if (scrollMode == 0)
            {
                var go : GameObj = GameVars.footballGO;
                if (go == null)
                {
                    return;
                }
                camera.x = go.xpos - (Defs.displayarea_w / 2);
                camera.y = go.ypos - (Defs.displayarea_h / 2);
                return;
            }
            
            return;
        }
        
        var go : GameObj = GameVars.footballGO;
        if (go == null)
        {
            return;
        }
        
        mouse_x = MouseControl.x;
        mouse_y = MouseControl.y;
        
        
        var p : Point = new Point(go.xpos, go.ypos);
        
        var c : Float = 0.1;
        var w2 : Float = Defs.displayarea_w / 2;
        var h2 : Float = Defs.displayarea_h / 2;
        
        if (scrollFirstTime)
        {
            scrollFirstTime = false;
            c = 1;
        }
        
        
        
        
        
        
        
        if (go.state == 1)
        {
            var mx : Float = MouseControl.x;
            var my : Float = MouseControl.y;
            #if (js && html5)
            // Scheme C (aim pad): the finger is on the dead-space joystick, not panning across the play
            // field, so MouseControl.x/y don't reflect the aim. Drive the scroll from the latched aim
            // cursor instead, so the camera looks ahead toward where you're shooting (as on desktop).
            if (MobileAimPad.IsActive())
            {
                mx = MobileAimPad.ScrollCursorX();
                my = MobileAimPad.ScrollCursorY();
            }
            #end

            var tox : Float = (((mx - w2) * 0.5) + p.x) - w2;
            var toy : Float = (((my - h2) * 0.5) + p.y) - h2;
            camera.x += (tox - camera.x) * c;
            camera.y += (toy - camera.y) * c;
        }
        else
        {
            camera.x += (p.x - w2 - camera.x) * c;
            camera.y += (p.y - h2 - camera.y) * c;
        }
        
        
        if (camera.x < boundingRectangle.x)
        {
            camera.x = boundingRectangle.x;
        }
        if (camera.y < boundingRectangle.y)
        {
            camera.y = boundingRectangle.y;
        }
        
        if (camera.x + Defs.displayarea_w > boundingRectangle.right)
        {
            camera.x = boundingRectangle.right - Defs.displayarea_w;
        }
        if (camera.y + Defs.displayarea_h > boundingRectangle.bottom)
        {
            camera.y = boundingRectangle.bottom - Defs.displayarea_h;
        }
        
        
        return;
        
        if (scrollMode == 0)
        {
            var go : GameObj = GameVars.footballGO;
            if (go == null)
            {
                return;
            }
            camera.x = go.xpos - (Defs.displayarea_w / 2);
            camera.y = go.ypos - (Defs.displayarea_h / 2);
            return;
        }
        return;
        
        var go : GameObj = GameVars.footballGO;
        if (go == null)
        {
            return;
        }
        
        if (controlMode == 0)
        {
            camera.x = go.xpos - (Defs.displayarea_w / 2);
            camera.y = go.ypos - (Defs.displayarea_h / 2);
            return;
        }
        
        var cx : Float = Defs.displayarea_w / 2;
        var cy : Float = Defs.displayarea_h / 2;
        
        if (scrollMode == 0)
        {
            doKick = false;
            if (MouseControl.buttonPressed)
            {
                if (Utils.DistBetweenPoints(MouseControl.x + camera.x, MouseControl.y + camera.y, go.xpos, go.ypos) < 50)
                {
                    scrollMode = 2;
                }
                else
                {
                    scrollMode = 1;
                    scrollDragX = 0;
                    scrollDragY = 0;
                    MouseControl.dx = 0;
                    MouseControl.dy = 0;
                }
            }
        }
        else if (scrollMode == 1)
        {
            camera.x -= MouseControl.dx;
            camera.y -= MouseControl.dy;
            scrollDragX = MouseControl.x;
            scrollDragY = MouseControl.y;
            MouseControl.dx = 0;
            MouseControl.dy = 0;
            if (MouseControl.buttonPressed == false)
            {
                scrollMode = 0;
            }
        }
        else if (scrollMode == 2)
        {
            var dx : Float = cx - MouseControl.x;
            var dy : Float = cy - MouseControl.y;
            var scaler : Float = 0.8;
            camera.x = (go.xpos + (dx * scaler)) - cx;
            camera.y = (go.ypos + (dy * scaler)) - cy;
            if (MouseControl.buttonPressed == false)
            {
                scrollMode = 0;
                doKick = true;
            }
        }
        
        
        return;
        var mx : Float = MouseControl.x;
        var my : Float = MouseControl.y;
        
        var screenw : Float = 800;
        var screenh : Float = 700;
        
        var diffx : Float = screenw - Defs.displayarea_w;
        var diffy : Float = screenh - Defs.displayarea_h;
        
        var offx : Float = Utils.ScaleTo(0, diffx, 0, Defs.displayarea_w, mx);
        var offy : Float = Utils.ScaleTo(0, diffy, 0, Defs.displayarea_h, my);
        
        camera.x = offx;
        camera.y = offy;
        
        return;
        
        
        var go : GameObj = GameObjects.GetGameObjByName("player");
        
        if (go == null)
        {
            return;
        }
        if (Game.levelState == Game.levelState_Complete)
        {
            return;
        }
        
        
        camera.oldX = camera.x;
        camera.oldY = camera.y;
        
        
        
        var playerPos : Point = new Point(go.xpos, go.ypos);
        
        var dx : Float = Math.NaN;        var dy : Float = Math.NaN;        
        var xoff : Float = Defs.displayarea_w / 2;
        var yoff : Float = Defs.displayarea_h / 2;
        var linv : Vec2 = go.GetBodyLinearVelocity(0);
        
        var ang : Float = Math.atan2(linv.y, linv.x);
        var speed : Float = linv.length;
        
        if (false)
        {
            dx = 0;
            dy = 0;
        }
        else
        {
            speed = Utils.LimitNumber(0, 30, speed);
            var dist : Float = Utils.ScaleTo(100, 250, 0, 30, speed);
            dx = Math.cos(ang) * dist;
            dy = Math.sin(ang) * dist;
            
            dx = dist;
            dy = 0;
        }
        
        
        camera.toX = (playerPos.x - xoff) + dx;
        camera.toY = (playerPos.y - yoff) + dy;
        
        UpdateShake();
        
        camera.toY += shakeX;
        camera.toY += shakeY;
        
        var a : Float = (camera.toX - camera.x);
        var b : Float = (camera.toY - camera.y);
        
        camera.x += (camera.toX - camera.x) * 0.3;
        camera.y += (camera.toY - camera.y) * 0.3;
        
        camera.x = Math.round(camera.x);
        camera.y = Math.round(camera.y);
    }
    
    public static var shakeX : Float = 0;
    public static var shakeY : Float = 0;
    public static function UpdateShake()
    {
        shakeX = 0;
        shakeY = 0;
        var max : Float = 0;
        
        shakeX = Utils.RandBetweenFloat(-max, max);
        shakeY = Utils.RandBetweenFloat(-max, max);
    }
    
    public static function GetRankString(pc : Float) : String
    {
        pc *= 0.01;
        
        if (pc <= 0.2)
        {
            return "E";
        }
        if (pc <= 0.4)
        {
            return "D";
        }
        if (pc <= 0.6)
        {
            return "C";
        }
        if (pc <= 0.8)
        {
            return "B";
        }
        if (pc <= 0.9)
        {
            return "A";
        }
        if (pc <= 0.95)
        {
            return "AA";
        }
        if (pc >= 1.0)
        {
            return "AAA";
        }
        return "POO";
    }
    
    public static function GetRankIndex(pc : Float) : Int
    {
        pc *= 0.01;
        
        if (pc <= 0.2)
        {
            return 0;
        }
        if (pc <= 0.4)
        {
            return 1;
        }
        if (pc <= 0.6)
        {
            return 2;
        }
        if (pc <= 0.8)
        {
            return 3;
        }
        if (pc <= 0.9)
        {
            return 4;
        }
        if (pc <= 0.95)
        {
            return 5;
        }
        if (pc >= 1.0)
        {
            return 6;
        }
        return 0;
    }
    
    
    public static function AddScore(sc : Int) : Void
    {
        if (GameVars.useFeature1)
        {
            sc *= 2;
        }
        if (GameVars.useFeature2)
        {
            sc *= 2;
        }
        if (GameVars.useFeature3)
        {
            sc *= 2;
        }
        if (GameVars.useFeature4)
        {
            sc *= 2;
        }
        
        currentScore += (sc);
    }
    
    
    public static var addedNapeDisplay : Bool = false;
    
    public static function Render(_bd : BitmapData)
    {
        EngineDebug.StartTimer("render");
        
        if (gameState == gameState_UI)
        {
            return;
        }
        if (gameState == gameState_Walkthrough)
        {
            return RenderWalkthrough(_bd);
        }
        if (pause)
        {
            return;
        }
        
        if (PauseMenu.IsPaused())
        {
            return;
        }
        
        if (levelState == levelState_EndScreen)
        {
            return;
        }
        if (levelState == levelState_Null)
        {
            return;
        }
        
        if (levelState == levelState_Editor)
        {
            return;
        }
        
        var screenBD : BitmapData = _bd;
        // GPU sprite layer for this frame: the converted leaf render methods push sprites/HUD as Tiles.
        // screenBD remains the SOFTWARE underlay for the background + per-frame vector terrain, composited
        // beneath the Tilemap. So `bd` (the per-object software target) is now screenBD itself.
        TileRenderer.Begin();
        var bd : BitmapData = screenBD;

        var gfxid : Int = 0;        var numf : Int = 0;        var px : Float = Math.NaN;
        var x : Int = 0;        var y : Int = 0;


        var level : Level = Levels.GetCurrent();

        EngineDebug.StartTimer("r_back");
        // background straight into the software underlay (kept off the GPU layer so it stays behind terrain)
        if (backBD != null) screenBD.copyPixels(backBD, backBD.rect, Defs.pointZero, null, null, false);
        else screenBD.fillRect(screenBD.rect, 0);
        EngineDebug.EndTimer("r_back");



        EngineDebug.StartTimer("r_go");
        GameObjects.Render(bd);
        Particles.Render(bd);
        EngineDebug.EndTimer("r_go");

        EngineDebug.RenderNape(bd);

        EngineDebug.EndTimer("render");
        EngineDebug.StopTimers();
        RenderPanel(screenBD);
        EngineDebug.RenderTimers(screenBD);
        EngineDebug.CreateGetTimerStrings();
    }
    
    public static function RenderWalkthrough(_bd : BitmapData)
    {
        var screenBD : BitmapData = _bd;
        // GPU sprite layer for this frame: the converted leaf render methods push sprites/HUD as Tiles.
        // screenBD remains the SOFTWARE underlay for the background + per-frame vector terrain, composited
        // beneath the Tilemap. So `bd` (the per-object software target) is now screenBD itself.
        TileRenderer.Begin();
        var bd : BitmapData = screenBD;

        var gfxid : Int = 0;        var numf : Int = 0;        var px : Float = Math.NaN;
        var x : Int = 0;        var y : Int = 0;


        var level : Level = Levels.GetCurrent();

        EngineDebug.StartTimer("r_back");
        // background straight into the software underlay (kept off the GPU layer so it stays behind terrain)
        if (backBD != null) screenBD.copyPixels(backBD, backBD.rect, Defs.pointZero, null, null, false);
        else screenBD.fillRect(screenBD.rect, 0);
        EngineDebug.EndTimer("r_back");



        EngineDebug.StartTimer("r_go");
        GameObjects.Render(bd);
        Particles.Render(bd);
        EngineDebug.EndTimer("r_go");

        EngineDebug.RenderNape(bd);

        EngineDebug.EndTimer("render");
        EngineDebug.StopTimers();
        RenderPanel(screenBD);
        EngineDebug.RenderTimers(screenBD);
        EngineDebug.CreateGetTimerStrings();
    }
    
    
    public static var currentDisplayTexture : Int = -1;
    
    public static var gm : Matrix = new Matrix();
    
    
    public static function RenderCircle(g : Graphics, x : Float, y : Float, rad : Float, col : Int) : Void
    {
        var numP : Int = 50;
        var dx : Float = Math.PI * 2 / numP;
        var i : Int = 0;        var ang : Float = 0;
        for (i in 0...numP)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            var ang1 : Float = ang + dx;
            var xp : Float = x + (Math.cos(ang) * rad);
            var yp : Float = y + (Math.sin(ang) * rad);
            var xp1 : Float = x + (Math.cos(ang1) * rad);
            var yp1 : Float = y + (Math.sin(ang1) * rad);
            ang += dx;
            
            g.beginFill(col, 1);
            g.lineStyle(null, null, 0);
            g.moveTo(x, y);
            g.lineTo(xp, yp);
            g.lineTo(xp1, yp1);
            g.lineTo(x, y);
            g.endFill();
        }
    }
    
    
    public static function RenderCursor(bd : BitmapData)
    {
    }
    
    
    public static var zorder : Array<Dynamic>;
    public static function RenderNearGOs(bd : BitmapData) : Void
    {
        var go : GameObj = null;        var i : Int = zorder.length;
        for (a in 0...i)
        {
            go = Reflect.field(zorder, Std.string(a));
            if (go.zpos < -1000)
            {
                go.Render(bd);
            }
        }
    }
    public static function RenderFarGOs(bd : BitmapData) : Void
    {
        var go : GameObj = null;        var i : Int = 0;
        
        
        EngineDebug.StartTimer("sort");
        
        i = 0;
        zorder = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.visible)
            {
                zorder.push(go);
                i++;
            }
        }
        Sort.numericDesc(zorder, "zpos");
        
        EngineDebug.EndTimer("sort");
        
        for (a in 0...i)
        {
            go = Reflect.field(zorder, Std.string(a));
            if (go.zpos >= -1000)
            {
                go.Render(bd);
            }
        }
    }
    
    
    public static function RenderFloorGrass(bd : BitmapData) : Void
    {
        var i : Int = 0;        var p0 : Point = null;        var p1 : Point = null;        var l : Level = Levels.GetCurrent();
        
        var dobj_spikes : DisplayObj = GraphicObjects.GetDisplayObjByName("spikes");
        var numf_spikes : Int = dobj_spikes.GetNumFrames();
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == 3)
            {
                for (i in 0...line.points.length)
                {
                    var j : Int = as3hx.Compat.parseInt(i + 1);
                    j = Std.int(j % line.points.length);
                    p0 = line.points[i].clone();
                    p1 = line.points[j].clone();
                    
                    var dx : Float = p1.x - p0.x;
                    var dy : Float = p1.y - p0.y;
                    
                    var len : Float = Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
                    
                    dx /= len;
                    dy /= len;
                    
                    var k : Float = Math.NaN;                    k = 0;
                    while (k < len)
                    {
                        var xx : Float = p0.x + (dx * k);
                        var yy : Float = p0.y + (dy * k);
                        
                        
                        var ang : Float = Math.atan2(dy, dx);
                        dobj_spikes.RenderAtRotScaled(Utils.RandBetweenInt(0, numf_spikes - 1), bd, xx, yy, 1, ang, null, true);
                        k += 7;
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    public static function InitMessage(_message : String, x : Float = 320, y : Float = 100)
    {
        var go : GameObj = null;        go = GameObjects.AddObj(0, 0, -500);
        go.InitTextMessage(_message, x, y);
    }
    
    public static function RenderPanel(bd : BitmapData)
    {
        var l : Level = Levels.GetCurrent();
        if (l == null)
        {
            Utils.print("null level " + Levels.currentIndex);
            return;
        }
        
        
        var x : Float = Math.NaN;        var y : Float = Math.NaN;        var s : String = null;        var w : Float;
        
        var f : Int = 0;        x = 10;
        y = 35;
        
        
        
        if (usedebug == true)
        {
        }
        else
        {
        }
    }
    
    public static function InitControl()
    {
    }
    
    public static function InitShot()
    {
    }
    
    
    
    public static function GetLineIndexByName(name : String) : Int
    {
        var l : Level = Levels.GetCurrent();
        var index : Int = 0;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.id == name)
            {
                return index;
            }
            index++;
        }
        return -1;
    }
    
    
    
    public static function InitDrag()
    {
        dragState = 0;
    }
    
    public static var dragState : Int = 0;
    public static var dragPosX : Float = 0;
    public static var dragPosY : Float = 0;
    
    public static var buttonClickedThisUpdate : Bool;
    
    public static function UpdateControl()
    {
        buttonClickedThisUpdate = false;
    }
    
    public static function DoOnClickedControl()
    {
        var curs : String = "pointer";
        
        var mx : Float = MouseControl.x;
        var my : Float = MouseControl.y;
        var buttonPressed : Bool = MouseControl.buttonPressed;
        
        if (playbackWalkthrough)
        {
            if (currentWalkthroughRecordingPoint != null)
            {
                mx = currentWalkthroughRecordingPoint.x;
                my = currentWalkthroughRecordingPoint.y;
                buttonPressed = currentWalkthroughRecordingPoint.mouseButton;
            }
        }
        
        
        var go : GameObj = HitTestPhysObjGraphics(mx, my);
        if (go != null)
        {
            if (go.onClickedFunction != null)
            {
                if (go.canClickFunction == null)
                {
                    curs = "canpress";
                }
                else if (go.canClickFunction() == true)
                {
                    curs = "canpress";
                }
                else
                {
                    curs = "cantpress";
                }
            }
        }
        if (Mouse.cursor != curs)
        {
            if (false == false)
            {
                Mouse.cursor = curs;
            }
        }
        
        
        
        
        if (buttonPressed)
        {
            MouseControl.buttonPressed = false;
            buttonClickedThisUpdate = true;
            
            var go : GameObj = null;            var go : GameObj = HitTestPhysObjGraphics(mx, my);
            if (go != null)
            {
                if (go.onClickedFunction != null)
                {
                    go.onClickedFunction();
                    return;
                }
            }
            else
            {
            }
        }
    }
    
    
    public static function HitTestGOLine(go : GameObj, mx : Int, my : Int) : Bool
    {
        var x : Float = Math.round(go.xpos);
        var y : Float = Math.round(go.ypos);
        x -= Math.round(Game.camera.x);
        y -= Math.round(Game.camera.y);
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        var newpoints : Array<Dynamic> = [];
        
        var p0 : Point = null;        
        var index : Int = 0;
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EField(EIdent(go),linkedPhysLine),points) type: null */ in go.linkedPhysLine.points)
        {
            p0 = p.clone();
            p0.x -= go.linkedPhysLine.centrex;
            p0.y -= go.linkedPhysLine.centrey;
            p0.x += go.xpos;
            p0.y += go.ypos;
            p0.x -= sx;
            p0.y -= sy;
            newpoints.push(p0);
            
            index++;
        }
        var edLine : EdLine = new EdLine();
        edLine.SetPointArray(newpoints);
        
        return edLine.PointInPoly(mx, my);
    }
    
    public static function HitTestPhysObjGraphics(x : Float, y : Float) : GameObj
    {
        var bd : BitmapData = Game.main.screenBD;
        var r : Rectangle = new Rectangle(0, 0, 1, 1);
        
        bd.fillRect(Defs.screenRect, 0);
        
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.onClickedFunction != null)
            {
                if (go.clickTestType == 1)
                {
                    if (HitTestGOLine(go, Std.int(x), Std.int(y)))
                    {
                        return go;
                    }
                }
                else
                {
                    var dobj : DisplayObj = go.dobj;
                    
                    var extra : Float = 100;
                    r = new Rectangle((go.xpos - camera.x) - extra, (go.ypos - camera.y) - extra, extra * 2, extra * 2);
                    
                    if (r.contains(x, y))
                    {
                        bd.fillRect(r, 0);
                        
                        go.Render(bd);
                        
                        var col : Int = bd.getPixel32(Std.int(x), Std.int(y));
                        if (col != 0)
                        {
                            return go;
                        }
                    }
                }
            }
        }
        return null;
    }
    
    
    public static function HitTestPhysObjGraphics_Stage3D(x : Float, y : Float) : GameObj
    {
        var r : Rectangle = new Rectangle(0, 0, 1, 1);
        
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.onClickedFunction != null)
            {
                if (go.clickTestType == 1)
                {
                }
                else
                {
                    var dobj : DisplayObj = go.dobj;
                    
                    var extra : Float = 100;
                    r = new Rectangle((go.xpos - camera.x) - extra, (go.ypos - camera.y) - extra, extra * 2, extra * 2);
                    
                    if (r.contains(x, y))
                    {
                        return go;
                    }
                }
            }
        }
        return null;
    }
    
    
    
    public static function DoGameObjSwitch(go : GameObjBase)
    {
        for (go1/* AS3HX WARNING could not determine type for var: go1 exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go1.active && go1.switchFunction != null)
            {
                if (go1.switchName == go.id)
                {
                    go1.switchFunction();
                }
            }
        }
    }
    
    public static function DoSwitchPOI(thisPOI : EdObj)
    {
    }
    
    public static function DoSwitch(thisGO : GameObjBase)
    {
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active)
            {
                if (go.switchFunction != null)
                {
                    if (go.logicLink0 == thisGO)
                    {
                        go.switchFunction();
                        Audio.OneShot("sfx_switch");
                    }
                }
            }
        }
    }
    
    
    
    public static function GetPlayerPosition() : Int
    {
        var px : Float = goPlayer.xpos;
        
        var place : Int = 0;
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.name == "aicar")
            {
                if (go.xpos > px)
                {
                    place++;
                }
            }
        }
        return place;
    }
    
    public static function GetAIPosition(aiCar : GameObj) : Int
    {
        var px : Float = aiCar.xpos;
        
        var place : Int = 0;
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && (go.name == "aicar" || go.name == "player"))
            {
                if (go != aiCar)
                {
                    if (go.xpos > px)
                    {
                        place++;
                    }
                }
            }
        }
        return place;
    }
    
    public static var ballpath_grav : Float = 0.1;
    public static var ballpath_mult : Float = 0.07300000000000005;
    public static var renderBallPathTimer : Float = 0;
    public static var ballpath_dx : Float;
    public static var ballpath_dy : Float;
    public static var ballpath_mass : Float;
    public static var ballpath_scaler : Float = 1;
    public static var ballpath_doit : Bool;
    
    public static var prevBallPath_dx : Float;
    public static var prevBallPath_dy : Float;
    public static var prevBallPath_x : Float;
    public static var prevBallPath_y : Float;
    public static var prevBallPath_doIt : Bool;
    
    public static function InitBallPathForLevel()
    {
        prevBallPath_doIt = false;
    }
    
    public static function RenderPreviousBallPath(bd : BitmapData)
    {
        if (prevBallPath_doIt == false)
        {
            return;
        }
        var _x = prevBallPath_x - camera.x;
        var _y = prevBallPath_y - camera.y;
        var _dx = prevBallPath_dx;
        var _dy = prevBallPath_dy;
        
        var g : Graphics = fillScreenMC.graphics;
        g.clear();
        g.lineStyle(1, 0xffffff, 0.1);
        
        renderBallPathTimer -= 1;
        
        var x : Float = _x;
        var y : Float = _y;
        var grav : Float = ballpath_grav;
        
        var dx : Float = _dx * ballpath_mult;
        var dy : Float = _dy * ballpath_mult;
        
        var ox : Float = x;
        var oy : Float = y;
        var d2 : Float = 3 * 3;
        
        g.moveTo(x, y);
        
        var i : Int = 0;        var count : Int = 0;
        for (i in 0...1700)
        {
            count--;
            if (count <= 0)
            {
                if (Utils.Dist2BetweenPoints(x, y, ox, oy) > (d2))
                {
                    var alpha : Float = 0.2;
                    var alphaOffset = Utils.ScaleToPreLimit(0, 0.2, 0, GameVars.ballLineLength, i);
                    
                    alpha -= alphaOffset;
                    if (alpha <= 0)
                    {
                        alpha = 0;
                    }
                    
                    g.lineStyle(1, 0xffffff, alpha);
                    g.lineTo(x, y);
                    ox = x;
                    oy = y;
                }
                count = 10;
            }
            
            x += dx;
            y += dy;
            dy += grav;
            if (x < -10)
            {
                break;
            }
            if (x > Defs.displayarea_w + 10)
            {
                break;
            }
            if (y > Defs.displayarea_h)
            {
                break;
            }
        }
        
        
        bd.draw(fillScreenMC, null, null, null, null, false);
    }
    
    public static var positions : Array<Dynamic> = [];
    public static function RenderBallPath_calcPositions(_x : Float, _y : Float)
    {
        positions = [];
        
        
        var v1 : Point = new Point(0, 0);
        var p1 : Point = new Point(0, 0);
        var x : Point = new Point(_x, _y);
        var v : Point = new Point(ballpath_dx / ballpath_mass * ballpath_scaler, ballpath_dy / ballpath_mass * ballpath_scaler);
        var a : Point = new Point(0, PhysicsBase.nape_Gravity);
        var d : Float = PhysicsBase.GetNapeSpace().worldLinearDrag;
        var h : Float = 1 / 60;
        
        
        var totalTime : Int = as3hx.Compat.parseInt(60 * 0.7);
        for (i in 0...totalTime)
        {
            positions.push(x.clone());
            
            var z : Float = Math.pow(1 - d, h);
            var a1 : Point = new Point(a.x * h, a.y * h);
            a1.x += v.x;
            a1.y += v.y;
            v1.x = a1.x * z;
            v1.y = a1.y * z;
            
            x.x += v1.x * h;
            x.y += v1.y * h;
            
            v.x = v1.x;
            v.y = v1.y;
        }
    }
    public static function RenderBallPath(bd : BitmapData, _x : Float, _y : Float, _dx : Float, _dy : Float)
    {
        if (ballpath_doit == false)
        {
            return;
        }
        
        
        RenderBallPath_calcPositions(_x, _y);
        
        var g : Graphics = fillScreenMC.graphics;
        g.clear();
        g.lineStyle(1, 0xffffff, 0.5);
        
        
        for (i in 0...positions.length - 1)
        {
            var alpha : Float = Utils.ScaleTo(1, 0, 0, positions.length, i);
            var p : Point = positions[i];
            var p1 : Point = positions[i + 1];
            g.lineStyle(2, 0xffffff, alpha);
            g.moveTo(p.x, p.y);
            g.lineTo(p1.x, p1.y);
        }
        
        
        bd.draw(fillScreenMC, null, null, null, null, false);
    }
    
    public static function RenderBallPathOld(bd : BitmapData, _x : Float, _y : Float, _dx : Float, _dy : Float)
    {
        if (ballpath_doit == false)
        {
            return;
        }
        
        var g : Graphics = fillScreenMC.graphics;
        g.clear();
        g.lineStyle(1, 0xffffff, 0.5);
        
        renderBallPathTimer -= 1;
        
        var bpt : Float = renderBallPathTimer;
        
        
        
        if (usedebug)
        {
            if (KeyReader.Down(KeyReader.KEY_NUM_1))
            {
                ballpath_grav -= 0.001;
            }
            if (KeyReader.Down(KeyReader.KEY_NUM_2))
            {
                ballpath_grav += 0.001;
            }
            if (KeyReader.Down(KeyReader.KEY_NUM_4))
            {
                ballpath_mult -= 0.0001;
            }
            if (KeyReader.Down(KeyReader.KEY_NUM_5))
            {
                ballpath_mult += 0.0001;
            }
        }
        ballpath_grav = Vars.GetVarAsNumber("gravity") * Vars.GetVarAsNumber("ballpath_gravity_multiplier");
        
        var x : Float = _x;
        var y : Float = _y;
        var grav : Float = ballpath_grav;
        
        var dx : Float = _dx * ballpath_mult;
        var dy : Float = _dy * ballpath_mult;
        
        var ox : Float = x;
        var oy : Float = y;
        var d2 : Float = 3 * 3;
        
        g.moveTo(x, y);
        
        var max : Int = 1000;
        
        var i : Int = 0;        var count : Int = 0;
        for (i in 0...max)
        {
            count--;
            if (count <= 0)
            {
                if (Utils.Dist2BetweenPoints(x, y, ox, oy) > (d2))
                {
                    var alpha : Float = 0.5;
                    var alphaOffset = Utils.ScaleToPreLimit(0, 0.7, 0, GameVars.ballLineLength, i);
                    
                    alpha -= alphaOffset;
                    if (alpha <= 0)
                    {
                        alpha = 0;
                    }
                    bpt += 1;
                    g.lineStyle(1, 0xffffff, alpha);
                    g.lineTo(x, y);
                    ox = x;
                    oy = y;
                }
                count = 5;
            }
            
            x += dx;
            y += dy;
            dy += grav;
            if (x < -10)
            {
                break;
            }
            if (x > Defs.displayarea_w + 10)
            {
                break;
            }
            if (y > Defs.displayarea_h)
            {
                break;
            }
        }
        
        
        bd.draw(fillScreenMC, null, null, null, null, false);
    }

    public function new()
    {
    }
    public static var Game_static_initializer = {
        if (false)
        {
            doWalkthrough = true;
            recordWalkthrough = false;
            playbackWalkthrough = true;
            usedebug = false;
            soundon = false;
            load_vars_data = false;
        };
        if (true)
        {
            recordWalkthrough = false;
            playbackWalkthrough = false;
            usedebug = false;
            soundon = true;
            load_vars_data = false;
        };
        if (false)
        {
            controlMode = 1;
            load_vars_data = false;
        };
        true;
    }

}

