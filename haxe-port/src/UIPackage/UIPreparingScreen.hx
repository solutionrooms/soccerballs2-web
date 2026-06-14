package uIPackage;

import flash.display.MovieClip;
import flash.events.Event;
import flash.system.System;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIPreparingScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
    }
    override public function InitScreen()
    {
        mem1 = System.totalMemory / 1024;
        
        titleMC = new ScreenPreparing();
        ScreenSize.ScaleMovieClip(titleMC);
        
        Preparing.Modify();
        
        titleMC.addEventListener(Event.ENTER_FRAME, UpdatePreparingScreen, false, 0, true);
        
        Lic.PlayWithScoresButton(titleMC.btn_PlayWithHighcores);
        
        if (Game.doWalkthrough)
        {
            titleMC.btn_PlayWithHighcores.visible = false;
        }
        
        
        
        preparingGraphicsTimer = 0;
        preparingGraphicsIndex = 0;
        PreparingScreenSetBar();
    }
    private var preparingScreenDone : Bool = false;
    private var preparingGraphicsTimer : Int;
    
    private var preparingGraphicsIndex : Int;
    
    private function UpdatePreparingScreen(e : Event)
    {
        if (titleMC == null)
        {
            return;
        }
        preparingGraphicsTimer--;
        if (preparingGraphicsTimer > 0)
        {
            return;
        }
        PreparingScreenSetBar();
        
        
        var po : PreparingObject = Preparing.GetPreparingList()[preparingGraphicsIndex];
        Preparing.DoPreparingObject(po);
        
        PreparingScreenSetBar();
        preparingGraphicsIndex++;
        if (preparingGraphicsIndex >= Preparing.GetPreparingList().length)
        {
            preparingScreenDone = true;
            titleMC.removeEventListener(Event.ENTER_FRAME, UpdatePreparingScreen);
            
            var mem2 : Int = as3hx.Compat.parseInt(System.totalMemory / 1024);
            var memused : Int = as3hx.Compat.parseInt(mem2 - mem1);
            Utils.print("memory used for gfx: " + memused + "k");
            
            if (Game.doWalkthrough)
            {
                UI.StartTransition("walkthrough");
            }
            else
            {
                UI.StartTransition("title");
            }
        }
    }
    private function PreparingScreenSetBar()
    {
        if (titleMC == null)
        {
            return;
        }
        var pc : Float = Utils.ScaleTo(0, 1, 0, Preparing.GetPreparingList().length - 1, preparingGraphicsIndex);
        titleMC.loaderBar.loadBar.scaleX = pc;
    }
    private static var mem1 : Int;
}


