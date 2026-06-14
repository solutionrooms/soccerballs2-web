package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import licPackage.AdHolder;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;
import licPackage.LicSku;
import licPackage.OtherGames;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIArcade extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        titleMC.removeChild(MiniGame.GetBitmap());
        titleMC.removeEventListener(Event.ENTER_FRAME, OnEnterFrame);
        MiniGame.Exit();
        UI.RemoveAllButtons();
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        
        Audio.PlayMusic("menus_music");
        
        titleMC = new MovieClip();  // arcade();  
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.buttonQuit, buttonBackPressed, null, true);
        UI.AddAnimatedMCButton(titleMC.overlay.buttonStart, buttonStartPressed, null, true);
        
        MiniGame.Init(titleMC);
        
        titleMC.addChild(MiniGame.GetBitmap());
        titleMC.setChildIndex(MiniGame.GetBitmap(), 0);  // titleMC.numChildren - 1);  
        
        
        titleMC.addEventListener(Event.ENTER_FRAME, OnEnterFrame);
        
        
        Lic.AnimatedMCMoreGamesButton(titleMC.overlay.buttonMoreGames, "minigame");
        
        titleMC.overlay.textBestScore.text = "Your Best Score: " + MiniGame.highscore;
    }
    
    private function OnEnterFrame(e : Event)
    {
        MiniGame.Update();
        MiniGame.Render();
    }
    
    
    public function buttonStartPressed(e : MouseEvent)
    {
        MiniGame.Start();
    }
    public function buttonBackPressed(e : MouseEvent)
    {
        UI.StartTransition("levelselect");
    }
}

