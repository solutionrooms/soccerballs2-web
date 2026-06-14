import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.filters.BlurFilter;
import licPackage.Lic;
import textPackage.TextStrings;
import uIPackage.UI;

/**
	 * ...
	 * @author LongAnimals
	 */
class HudController
{
    
    private var hudMC : MovieClip;
    
    public function new()
    {
    }
    
    private function UpdateScore()
    {
    }
    private function UpdateCannonPower(frame : Int)
    {
    }
    private function UpdateMultiplier()
    {
    }
    private function UpdateTime()
    {
    }
    
    private function SetupMuteButtons()
    {
        UI.SetupAnimatedSFXMuteButton(hudMC.mainArea.btn_sfxMuteBtn);
        UI.SetupAnimatedMusicMuteButton(hudMC.mainArea.btn_musicMute);
        UI.RemoveAnimatedMCButton(hudMC.mainArea.btn_moregames);
        Lic.AnimatedMCMoreGamesButton(hudMC.mainArea.btn_moregames, "hud");
    }
    private function Hide()
    {
        hudMC.visible = false;
    }
    private function Show()
    {
        hudMC.visible = true;
    }
    private function InitForLevel()
    {
        UI.RemoveAnimatedMCButton(hudMC.mainArea.btn_walkthrough);
        Lic.AnimatedMCWalkthroughButton(hudMC.mainArea.btn_walkthrough);
        
        hudMC.mainArea.LevelNameText.text = as3hx.Compat.parseInt(Levels.currentIndex + 1) + ": " + Levels.GetCurrent().name;
        if (Game.usedebug)
        {
            hudMC.mainArea.LevelNameText.text += " (" + Levels.GetCurrent().creator + ")";
        }
    }
    
    private function InitOnce()
    {
        hudMC = new Hud();
        hudMC.visible = true;
        
        Lic.AnimatedMCMoreGamesButton(hudMC.mainArea.btn_moregames, "hud");
        
        UI.AddAnimatedMCButton(hudMC.mainArea.btn_quit, ButtonPausePressed);
        UI.AddAnimatedMCButton(hudMC.mainArea.btn_restart, ButtonRestartPressed);
        
        UI.AddAnimatedMCButton(hudMC.debugArea.btn_skipLevel, ButtonDebugSkipPressed);
        
        Lic.AnimatedMCWalkthroughButton(hudMC.mainArea.btn_walkthrough);
        
        UI.AddAnimatedSFXMuteButton(hudMC.mainArea.btn_sfxMuteBtn);
        UI.AddAnimatedMusicMuteButton(hudMC.mainArea.btn_musicMute);
        UI.AddAnimatedMCButton(hudMC.mainArea.btn_fastforward, buttonFastForwardPressed);
    }
    
    
    public function ShowFastForward(doit : Bool)
    {
        hudMC.buttonFastForward.visible = doit;
    }
    
    private function buttonFastForwardPressed(e : MouseEvent)
    {
        GameVars.doingFastForward = (GameVars.doingFastForward == false);
        Audio.OneShot("sfx_fastforward");
    }
    private function ButtonMenuPressed(e : MouseEvent)
    {
        if (PauseMenu.IsPaused() == false)
        {
            PauseMenu.Pause();
        }
    }
    
    
    private function ButtonDebugSkipPressed(e : MouseEvent)
    {
        Game.NextLevel();
    }
    private function ButtonRestartPressed(e : MouseEvent)
    {
        Game.RestartLevel();
    }
    
    
    private function UpdateKeyPresses()
    {
        if (UI.isInTransition)
        {
            return;
        }
        if (PauseMenu.IsPaused() == false)
        {
            if (KeyReader.Pressed(KeyReader.KEY_P) || KeyReader.Pressed(KeyReader.KEY_ESCAPE))
            {
                PauseMenu.Pause();
            }
        }
        if (KeyReader.Pressed(KeyReader.KEY_R))
        {
            ButtonRestartPressed(null);
        }
        if (KeyReader.Pressed(KeyReader.KEY_F))
        {
            buttonFastForwardPressed(null);
        }
        if (KeyReader.Pressed(KeyReader.KEY_N))
        {
            UI.KeypressSFXMuteButton(hudMC.mainArea.btn_sfxMuteBtn);
        }
        if (KeyReader.Pressed(KeyReader.KEY_M))
        {
            UI.KeypressMusicMuteButton(hudMC.mainArea.btn_musicMute);
        }
    }
    
    private var debugMode : Int = 0;
    public function CycleDebugModes()
    {
        debugMode++;
        if (debugMode >= 3)
        {
            debugMode = 0;
        }
    }
    private function Update()
    {
        hudMC.mainArea.visible = true;
        hudMC.debugArea.visible = false;
        
        
        
        
        if (Game.doWalkthrough)
        {
            return;
        }
        UpdateKeyPresses();
        
        
        var poo : Bool = false;
        var remainingKicks : Int = as3hx.Compat.parseInt(GameVars.maxKicks - GameVars.numKicks);
        var goldRemainingKicks : Int = as3hx.Compat.parseInt(GameVars.goldKicks - GameVars.numKicks);
        if (goldRemainingKicks < 0)
        {
            poo = true;
            goldRemainingKicks = 0;
        }
        hudMC.mainArea.kicksText.text = remainingKicks;
        hudMC.mainArea.starText.text = goldRemainingKicks;
        hudMC.mainArea.coinsText.text = GameVars.numLevelCoinsCollected + "/" + GameVars.totalLevelCoins;
        hudMC.mainArea.goldKicksFail.visible = false;
        if (poo)
        {
            hudMC.mainArea.goldKicksFail.visible = true;
        }
        
        
        TextStrings.ReplaceTextFieldText(hudMC.mainArea.textScoreName, "score");
        hudMC.mainArea.textScore.text = Game.currentScore;
        
        var ballGO : GameObj = GameVars.footballGO;
        
        if (ballGO != null)
        {
            if (ballGO.state == 2)
            {
                hudMC.mainArea.ballTimer.visible = true;
                hudMC.mainArea.ballTimer.gotoAndStop(as3hx.Compat.parseInt(Utils.ScaleTo(1, hudMC.mainArea.ballTimer.totalFrames, 0, GameVars.ballTimerMax, ballGO.ballTimer)));
            }
            else
            {
                hudMC.mainArea.ballTimer.visible = false;
            }
        }
        
        return;
    }
    
    private function helpPressed(e : MouseEvent)
    {
        Game.pause = true;
    }
    private function logoPressed(e : MouseEvent)
    {
    }
    private function walkthroughPressed(e : MouseEvent)
    {
    }
    private function ButtonPausePressed(e : MouseEvent)
    {
        if (PauseMenu.IsPaused() == false)
        {
            PauseMenu.Pause();
        }
    }
}


