package uIPackage;

import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIWalkthroughScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        Utils.print("removing level " + Levels.currentIndex);
        
        var w : WalkthroughScreen = Walkthrough.walkthroughScreens[Levels.currentIndex];
        w.StopPlayback();
        
        Game.gameState = Game.gameState_Play;
        
        UI.RemoveAllButtons();
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        
        titleMC = new ScreenWalkthrough();
        titleMC.gotoAndStop(1);
        
        Lic.MainLogoButton((untyped titleMC).mainLogo);
        
        TextStrings.ReplaceTextFieldText((untyped titleMC).textTitle);
        
        
        
        UI.AddAnimatedMCButton((untyped titleMC).buttonBack, backClicked);
        
        
        
        (untyped titleMC).textLevelName.text = Levels.GetCurrent().name;
        
        var w : WalkthroughScreen = Walkthrough.walkthroughScreens[Levels.currentIndex];
        w.InitPlayback(titleMC);
        
        
        LicDef.GetStage().stage.frameRate = Defs.fps;
    }
    
    
    public function backClicked(e : MouseEvent)
    {
        var w : WalkthroughScreen = Walkthrough.walkthroughScreens[Levels.currentIndex];
        w.StopPlayback();
        UI.StartTransition("walkthrough");
    }
}


