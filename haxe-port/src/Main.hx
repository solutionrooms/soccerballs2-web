import audioPackage.Audio;
import editorPackage.GameLayers;
import flash.display.BitmapDataChannel;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Stage;
import flash.display.StageQuality;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.filters.ConvolutionFilter;
import flash.filters.DisplacementMapFilter;
import flash.system.System;
import flash.text.*;
import flash.net.URLRequest;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;
import flash.net.*;
import flash.ui.*;
import flash.display.StageDisplayState;
import flash.utils.Timer;
import licPackage.Lic;
import uIPackage.UI;

@:meta(Frame(factoryClass="Preloader"))

class Main extends MovieClip
{
    public var ftime : Float;
    public var currentTime : Float = 0;
    
    public var screenBD : BitmapData;
    public var screenB : Bitmap;
    
    
    public static var theRoot : MovieClip;
    public static var theStage : Stage;

    // DEBUG hook (exposed to JS as window.sb2LoadLevel) so a level can be started without clicking
    // through the menu — used to reproduce/diagnose the gamescreen transition headlessly.
    @:expose("sb2LoadLevel")
    public static function sb2LoadLevel(i : Int) : Void
    {
        Levels.currentIndex = i;
        UI.StartTransition("gamescreen", null, "");
    }

    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, added_to_stage, false, 0, true);
    }
    
    public function added_to_stage(e : Event)
    {
        removeEventListener(Event.ADDED_TO_STAGE, added_to_stage);
        Lic.InitFromMain();
        Lic.Playtomic_Log();
        Lic.ShowIntro(NewInit4);
    }
    public function NewInit4()
    {
        // Force the generated SWF symbol classes to be compiled+kept (they are otherwise only resolved
        // dynamically by name and stripped by DCE). Referencing the array makes Haxe load KeepSymbols.
        if (KeepSymbols.symbols == null) return;
        theRoot = this;
        theStage = this.root.stage;
        // In the original SWF the Preloader (the [Frame(factoryClass="Preloader")] document factory)
        // set LicDef.stg via InitFromPreloader. OpenFL ignores that metadata and runs Main directly,
        // so wire the on-stage root here instead — LicDef.GetStage() is used pervasively by the UI.
        licPackage.LicDef.stg = this;
        SetEverythingUpOnce();
    }
    
    
    public function InitDrawScreen() : Void
    {
        if (false)
        {
            return;
        }
        screenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        screenB = new Bitmap(screenBD);
    }
    
    
    public function SetEverythingUpOnce() : Void
    {
        SetEverythingUpOnce2();
    }
    
    public function SetEverythingUpOnce2() : Void
    {
        MobileSpecific.Init();
        
        
        TexturePages.InitOnce();
        
        GraphicObjects.InitOnce();
        
        
        EngineDebug.InitOnce();
        KeyReader.InitOnce(theStage);
        MouseControl.InitOnce(theStage);
        Audio.InitOnce();
        PauseMenu.InitOnce();
        Particles.InitOnce(Defs.maxParticles);
        GameObjects.InitOnce(Defs.maxGameObjects);
        UI.InitOnce();
        InitDrawScreen();
        ExternalData.Load(SetEverythingUpOnce4);
    }
    
    public function SetEverythingUpOnce4()
    {
        ClearStage();
        Game.InitOnce(this);
        addEventListener(Event.ENTER_FRAME, MainLoop);
    }
    
    public function ClearStage()
    {
        var i : Int = 0;        i = as3hx.Compat.parseInt(this.numChildren - 1);
        while (i >= 0)
        {
            removeChildAt(i);
            i--;
        }
    }
    
    
    public function DisplayStageNames()
    {
        var i : Int = 0;        i = as3hx.Compat.parseInt(this.numChildren - 1);
        while (i >= 0)
        {
            var dob : DisplayObject = getChildAt(i);
            Utils.print(dob.name);
            i--;
        }
    }
    
    
    
    public function Render(bd : BitmapData)
    {
        this.x = 0;
        this.y = 0;
        Game.Render(bd);
    }
    
    public var timeForFrame : Float;
    public function calcFrameTime()
    {
        var oldTime : Float = currentTime;
        currentTime = Math.round(haxe.Timer.stamp() * 1000);
        
        timeForFrame = currentTime - oldTime;
        
        if (currentTime < oldTime)
        {
            oldTime = currentTime - 100;
        }
        if (currentTime > oldTime + (100 * 10))
        {
            oldTime = 100 * 10;
        }
        
        ftime = 1 / (1000 / Defs.fps) * (currentTime - oldTime);
        
        framecounter++;
        secondCounter += (currentTime - oldTime);
        
        if (secondCounter > 1000)
        {
            fps = (as3hx.Compat.parseFloat(framecounter) / secondCounter) * 1000;
            framecounter = 0;
            secondCounter = 0;
        }
    }
    public var fps : Float;
    public var framecounter : Int = 0;
    public var secondCounter : Float = 0.0;
    
    
    
    
    public var renderCount : Int = 0;
    public var frameSkipCount : Int = 0;
    
    public var timeForUpdate : Float = 0;
    public var renderSkip : Bool = false;
    
    public function RunLevel()
    {
        var oldTime : Float = Math.round(haxe.Timer.stamp() * 1000);
        
        if (Game.doWalkthrough)
        {
            return;
        }
        
        Game.UpdateGameplay();
        
        var maxTime : Float = 1000 / Defs.fps;
        
        
        if (false)
        {
            if (timeForUpdate > maxTime && frameSkipCount < 3)
            {
                screenBD.copyPixels(Game.backgroundScreenBD, screenBD.rect, Defs.pointZero);
                
                
                frameSkipCount++;
            }
            else
            {
                Render(Game.backgroundScreenBD);
                
                screenBD.copyPixels(Game.backgroundScreenBD, screenBD.rect, Defs.pointZero);
                
                frameSkipCount = 0;
            }
        }
        else
        {
            if (false)
            {
                useFrameSkip = false;
            }
            
            if (useFrameSkip)
            {
                if (timeForUpdate > (1000 / Defs.fps))
                {
                }
                else
                {
                    Render(screenBD);
                }
            }
            else if (true)
            {
                Render(screenBD);
            }
            else if (renderSkip == true)
            {
                renderSkip = false;
            }
            else
            {
                Render(screenBD);
                renderSkip = true;
            }
        }
        
        
        timeForUpdate = Math.round(haxe.Timer.stamp() * 1000) - oldTime;
    }
    
    public var useFrameSkip : Bool = true;
    
    public static var debugLoopCount : Int = 0;
    @:expose("sb2LoopCount") public static function sb2LoopCount() : Int { return debugLoopCount; }

    // Fixed-timestep gate. openfl HTML5 dispatches ENTER_FRAME on every requestAnimationFrame and does
    // NOT honour stage.frameRate, so the loop (and thus game speed) would run at the display refresh
    // rate — far too fast on high-refresh / vsync-off machines. Gate the loop to Defs.fps so one update
    // = 1/60 s of real time, matching the original Flash frame rate, independent of how fast rAF fires.
    public static var __loopStamp : Float = -1;

    public function MainLoop(e : Event) : Void
    {
        var step : Float = 1.0 / Defs.fps;
        var now : Float = haxe.Timer.stamp();
        if (__loopStamp < 0) __loopStamp = now - step;
        if ((now - __loopStamp) < step)
        {
            return; // too soon since the last update -> cap at Defs.fps
        }
        __loopStamp += step;
        if ((now - __loopStamp) > step)
        {
            __loopStamp = now; // fell behind (rAF slower than Defs.fps, or a stall) -> resync, no catch-up spiral
        }

        debugLoopCount++;
        KeyReader.UpdateOncePerFrame();
        Audio.UpdateOncePerFrame();

        GameVars.InitForFrame();

        RunLevel();
        GameVars.ExitForFrame();

        calcFrameTime();
    }
}

