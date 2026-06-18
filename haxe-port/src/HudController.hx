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
    
    public var hudMC : MovieClip;
    
    public function new()
    {
    }
    
    public function UpdateScore()
    {
    }
    public function UpdateCannonPower(frame : Int)
    {
    }
    public function UpdateMultiplier()
    {
    }
    public function UpdateTime()
    {
    }
    
    public function SetupMuteButtons()
    {
        UI.SetupAnimatedSFXMuteButton((untyped hudMC).mainArea.btn_sfxMuteBtn);
        UI.SetupAnimatedMusicMuteButton((untyped hudMC.mainArea).btn_musicMute);
        UI.RemoveAnimatedMCButton((untyped hudMC.mainArea).btn_moregames);
        Lic.AnimatedMCMoreGamesButton((untyped hudMC.mainArea).btn_moregames, "hud");
    }
    public function Hide()
    {
        hudMC.visible = false;
    }
    public function Show()
    {
        hudMC.visible = true;
    }
    public function InitForLevel()
    {
        UI.RemoveAnimatedMCButton((untyped hudMC.mainArea).btn_walkthrough);
        Lic.AnimatedMCWalkthroughButton((untyped hudMC.mainArea).btn_walkthrough);
        
        (untyped hudMC).mainArea.LevelNameText.text = as3hx.Compat.parseInt(Levels.currentIndex + 1) + ": " + Levels.GetCurrent().name;
        if (Game.usedebug)
        {
            (untyped hudMC).mainArea.LevelNameText.text += " (" + Levels.GetCurrent().creator + ")";
        }
        CentreHudText((untyped hudMC).mainArea.LevelNameText);
    }

    // openfl-swf renders the HUD's embedded-font dynamic text shifted left, so leading characters end up
    // hidden under the adjacent panel/icon. Centre the text within the field's box (device-font path via
    // the Komika Axis FontFace) so it sits in the visible middle instead of overflowing the left edge.
    // Safe to call every frame (the per-frame counter fields drop their format when .text is reassigned).
    static function CentreHudText(tf : flash.text.TextField) : Void
    {
        #if (js && html5)
        if (tf == null) return;
        try
        {
            tf.embedFonts = false;
            var fmt : flash.text.TextFormat = tf.getTextFormat();
            fmt.font = GameFont.FAMILY;
            fmt.align = flash.text.TextFormatAlign.CENTER;
            tf.setTextFormat(fmt);
        }
        catch (e : Dynamic) {}
        #end
    }
    
    public function InitOnce()
    {
        hudMC = new Hud();
        hudMC.visible = true;
        
        Lic.AnimatedMCMoreGamesButton((untyped hudMC.mainArea).btn_moregames, "hud");
        
        UI.AddAnimatedMCButton((untyped hudMC).mainArea.btn_quit, ButtonPausePressed);
        UI.AddAnimatedMCButton((untyped hudMC).mainArea.btn_restart, ButtonRestartPressed);
        
        UI.AddAnimatedMCButton((untyped hudMC).debugArea.btn_skipLevel, ButtonDebugSkipPressed);
        
        Lic.AnimatedMCWalkthroughButton((untyped hudMC.mainArea).btn_walkthrough);
        
        UI.AddAnimatedSFXMuteButton((untyped hudMC).mainArea.btn_sfxMuteBtn);
        UI.AddAnimatedMusicMuteButton((untyped hudMC.mainArea).btn_musicMute);
        UI.AddAnimatedMCButton((untyped hudMC).mainArea.btn_fastforward, buttonFastForwardPressed);
    }
    
    
    public function ShowFastForward(doit : Bool)
    {
        (untyped hudMC).buttonFastForward.visible = doit;
    }
    
    public function buttonFastForwardPressed(e : MouseEvent)
    {
        GameVars.doingFastForward = (GameVars.doingFastForward == false);
        Audio.OneShot("sfx_fastforward");
    }
    public function ButtonMenuPressed(e : MouseEvent)
    {
        if (PauseMenu.IsPaused() == false)
        {
            PauseMenu.Pause();
        }
    }
    
    
    public function ButtonDebugSkipPressed(e : MouseEvent)
    {
        Game.NextLevel();
    }
    public function ButtonRestartPressed(e : MouseEvent)
    {
        Game.RestartLevel();
    }
    
    
    public function UpdateKeyPresses()
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
            UI.KeypressSFXMuteButton((untyped hudMC).mainArea.btn_sfxMuteBtn);
        }
        if (KeyReader.Pressed(KeyReader.KEY_M))
        {
            UI.KeypressMusicMuteButton((untyped hudMC.mainArea).btn_musicMute);
        }
    }
    
    public var debugMode : Int = 0;
    public function CycleDebugModes()
    {
        debugMode++;
        if (debugMode >= 3)
        {
            debugMode = 0;
        }
    }
    public function Update()
    {
        (untyped hudMC).mainArea.visible = true;
        (untyped hudMC).debugArea.visible = false;
        
        
        
        
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
        (untyped hudMC).mainArea.kicksText.text = Std.string(remainingKicks);
        (untyped hudMC).mainArea.starText.text = Std.string(goldRemainingKicks);
        (untyped hudMC).mainArea.coinsText.text = GameVars.numLevelCoinsCollected + "/" + GameVars.totalLevelCoins;
        // setting .text each frame drops the format on these HTML fields, so re-centre after assigning.
        // NOTE: openfl-swf does not visually centre these narrow embedded-font fields the way it does the
        // wide score/level-name ones (align IS set, no mask — confirmed); the counters stay slightly
        // left-clipped. Left in place (correct intent); revisit via bitmap rendering. See ISSUES.md #1.
        CentreHudText((untyped hudMC).mainArea.kicksText);
        CentreHudText((untyped hudMC).mainArea.starText);
        CentreHudText((untyped hudMC).mainArea.coinsText);
        (untyped hudMC).mainArea.goldKicksFail.visible = false;
        if (poo)
        {
            (untyped hudMC).mainArea.goldKicksFail.visible = true;
        }
        
        
        TextStrings.ReplaceTextFieldText((untyped hudMC).mainArea.textScoreName, "score");
        (untyped hudMC.mainArea).textScore.text = Std.string(Game.currentScore);
        
        var ballGO : GameObj = GameVars.footballGO;
        
        if (ballGO != null)
        {
            if (ballGO.state == 2)
            {
                (untyped hudMC).mainArea.ballTimer.visible = true;
                (untyped hudMC).mainArea.ballTimer.gotoAndStop(as3hx.Compat.parseInt(Utils.ScaleTo(1, (untyped hudMC).mainArea.ballTimer.totalFrames, 0, GameVars.ballTimerMax, ballGO.ballTimer)));
            }
            else
            {
                (untyped hudMC).mainArea.ballTimer.visible = false;
            }
        }
        
        return;
    }
    
    public function helpPressed(e : MouseEvent)
    {
        Game.pause = true;
    }
    public function logoPressed(e : MouseEvent)
    {
    }
    public function walkthroughPressed(e : MouseEvent)
    {
    }
    public function ButtonPausePressed(e : MouseEvent)
    {
        if (PauseMenu.IsPaused() == false)
        {
            PauseMenu.Pause();
        }
    }
}


