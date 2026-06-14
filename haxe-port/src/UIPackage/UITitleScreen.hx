package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.URLRequest;
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
class UITitleScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        UI.RemoveAllButtons();
        UI.RemoveGeneric();
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        
        Audio.PlayMusic("menus_music");
        
        titleMC = new ScreenMainMenu();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.btn_playgame, buttonContinuePressed, null, true);
        UI.AddAnimatedMCButton(titleMC.btn_credits, buttonCreditsPressed, null, true);
        UI.AddAnimatedMCButton(titleMC.btn_clearSaveGame, buttonClearDataPopupPressed, null, true);
        UI.AddMCButton(titleMC.btn_language, buttonLanguageSelectPressed);
        
        
        titleMC.logo_soccerballs.gotoAndStop(1);
        if (LicDef.GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            titleMC.logo_soccerballs.gotoAndStop(2);
            titleMC.btn_prequel.buttonName.text = "Red Card 1";
        }
        
        UI.AddAnimatedMCButton(titleMC.btn_clearSaveGame, buttonClearDataPopupPressed, null, true);
        
        Lic.AnimatedMCPrequelButton(titleMC.btn_prequel);
        
        
        UI.AddGeneric(titleMC);
        
        Lic.AnimatedMCMoreGamesButton(titleMC.btn_moregames, "title");
        Lic.MainLogoButton(titleMC.mainLogo);
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KIZI)
        {
            titleMC.btn_credits.visible = false;
            titleMC.mainLogo.visible = false;
            KiziStuff.AddLogoAt(titleMC, 230, 190, 0.6);
        }
        if (LicDef.GetLicensor() == LicDef.LICENSOR_BEGAMER)
        {
            titleMC.btn_credits.visible = false;
        }
        
        
        Lic.AuthorButton(titleMC.turboBtn);
        
        
        Lic.AnimatedMCFacebookButton(titleMC.btn_facebook);
        Lic.Y8LogoButton(titleMC.btn_y8);
        Lic.AnimatedMCDownloadForYourSiteButton(titleMC.btn_download);
        
        
        if (false)
        {
            UI.AddAnimatedMCButton(titleMC.btn_facebook, MobileTwitterPressed);
        }
    }
    
    private var endMovieAvailable : Bool;
    
    
    public function buttonDownloadGamePressed(e : MouseEvent)
    {
        var url : String = "http://www.guineapop.com/Downloads/TokyoGuineaPop.zip";
        flash.Lib.getURL(new URLRequest(url), "_blank");
    }
    
    public function buttonIntroPressed(e : MouseEvent)
    {
        GameVars.introGoToLevelSelect = false;
        UI.StartTransitionImmediate("moviescreen");
    }
    
    public function buttonUseLocalMusic(e : MouseEvent)
    {
        titleMC.btn_localMusic.visible = false;
        Utils.print("Play your own MP3 pressed");
        Audio.PlayLocalFile(ButtonPlayLocalMp3_Complete);
    }
    
    public function ButtonPlayLocalMp3_Complete()
    {
        titleMC.btn_localMusic.visible = true;
    }
    
    public function buttonUseGameMusic(e : MouseEvent)
    {
        Utils.print("buttonUseGameMusic Pressed");
        if (Audio.playingLocalFile == false)
        {
            return;
        }
        Audio.DontPlayLocalAnyMore();
        Audio.StopAllMusic();
        Audio.PlayMusic("menus_music");
    }
    public function buttonClearDataPopupPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "areyousure_cleardata");
    }
    public function buttonAchievementsPressed(e : MouseEvent)
    {
        UI.StartTransition("achievements", null, "title");
    }
    public function buttonLanguageSelectPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "language");
    }
    public function buttonCreditsPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "credits");
    }
    public function buttonContinuePressed(e : MouseEvent)
    {
        GameVars.gameMode = 0;
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    
    public function MobileTwitterPressed(e : MouseEvent)
    {
        MobileSpecific.PostTwitter();
    }
}

