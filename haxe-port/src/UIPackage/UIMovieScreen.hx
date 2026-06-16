package uIPackage;

import audioPackage.Audio;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.system.System;
import flash.utils.Timer;
import licPackage.LicDef;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIMovieScreen extends UIScreenInstance
{
    public var moviePlaying : Bool = false;
    
    public function new()
    {
        super();
    }
    
    
    override public function RenderForTransition(renderBD : BitmapData) : Void
    {
        titleMC.x = Defs.displayarea_w / 2;
        titleMC.y = Defs.displayarea_h / 2;
        renderBD.draw(titleMC);
    }
    
    override public function ExitScreen()
    {
        LicDef.GetStage().stage.frameRate = Defs.fps;
    }
    override public function InitScreen()
    {
        moviePlaying = false;
        Audio.StopAllMusic();
        onTransitionCompleteFunction = StartMovie;
        
        var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass("Intro"));
        titleMC = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        titleMC.x = Defs.displayarea_w / 2;
        titleMC.y = Defs.displayarea_h / 2;
        
        titleMC.stop();
        
        LicDef.GetStage().stage.frameRate = 24;
    }
    
    public var lastFrame : Int = 0;
    
    public function StartMovie()
    {
        lastFrame = -1;
        titleMC.addEventListener(Event.EXIT_FRAME, OnExitFrame, false, 0, true);
        titleMC.addEventListener(MouseEvent.CLICK, OnClick, false, 0, true);
        titleMC.gotoAndPlay(1);
    }
    
    public function OnClick(e : MouseEvent) : Void
    {
        titleMC.removeEventListener(Event.EXIT_FRAME, OnExitFrame);
        titleMC.removeEventListener(MouseEvent.CLICK, OnClick);
        titleMC.stop();
        moviePlaying = false;
        Audio.StopAllSFX();
        Audio.StopAllMusic();
        
        
        if (GameVars.introGoToLevelSelect)
        {
            UI.StartTransitionImmediate("levelselect");
        }
        else if (UI.returnScreenName == "")
        {
            UI.StartTransitionImmediate("title");
        }
        else
        {
            UI.StartTransitionImmediate(UI.returnScreenName);
        }
    }
    
    public function OnExitFrame(e : Event) : Void
    {
        if (titleMC == null)
        {
            return;
        }
        
        
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        
        if (mc.currentFrameLabel != null)
        {
            Audio.Loop(mc.currentFrameLabel, 1);
        }
        
        if (mc.currentFrame == mc.totalFrames)
        {
            titleMC.removeEventListener(Event.EXIT_FRAME, OnExitFrame);
            titleMC.removeEventListener(MouseEvent.CLICK, OnClick);
            titleMC.stop();
            
            if (GameVars.introGoToLevelSelect)
            {
                UI.StartTransitionImmediate("levelselect");
            }
            else if (UI.returnScreenName == "")
            {
                UI.StartTransitionImmediate("title");
            }
            else
            {
                UI.StartTransitionImmediate(UI.returnScreenName);
            }
        }
    }
}


