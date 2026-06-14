package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.ui.Mouse;
import licPackage.AdHolder;
import licPackage.Lic;
import licPackage.LicDef;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UILevelComplete extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
        GameVars.useFeature1 = UI.GetAnimatedMCTickState(titleMC.btn_feature1);
        GameVars.useFeature2 = UI.GetAnimatedMCTickState(titleMC.btn_feature2);
        GameVars.useFeature3 = UI.GetAnimatedMCTickState(titleMC.btn_feature3);
        GameVars.useFeature4 = UI.GetAnimatedMCTickState(titleMC.btn_feature4);
        
        UI.RemoveAllButtons();
        UI.RemoveGeneric();
        
        if (AreOtherGamesAdsAllowed())
        {
            AdHolder.RemoveAd(titleMC.adBox.adloader);
        }
    }
    
    private function AreOtherGamesAdsAllowed() : Bool
    {
        if (LicDef.GetDomain() == "kaisergames.de")
        {
            if (Levels.currentIndex < 20)
            {
                return false;
            }
        }
        return LicDef.AreOtherGamesAdsAllowed();
    }
    
    private var b : Bitmap;
    
    override public function RenderForTransition(renderBD : BitmapData) : Void
    {
        b = new Bitmap(Game.copyScreenBD);
        titleMC.addChildAt(b, 0);
        renderBD.draw(titleMC);
    }
    
    override public function InitScreen()
    {
        Audio.PlayMusic("menus_music");
        
        UI.StartAddButtons();
        onTransitionCompleteFunction = TransitionComplete;
        Mouse.show();
        
        var l : Level = Levels.GetCurrent();
        
        titleMC = new ScreenLevelComplete();
        ScreenSize.ScaleMovieClip(titleMC);
        
        UI.AddGeneric(titleMC);
        
        if (AreOtherGamesAdsAllowed())
        {
            titleMC.adBox.adloader.addChild(AdHolder.GetAd());
        }
        else
        {
            titleMC.adBox.visible = false;
        }
        
        
        
        
        UI.AddAnimatedMCButton(titleMC.buttonLevelSelect, buttonMenuPressed);
        UI.AddAnimatedMCButton(titleMC.levelComplete.btn_continue, buttonNextPressed);
        UI.AddAnimatedMCButton(titleMC.levelComplete.btn_tryagain, buttonRetryPressed);
        
        Lic.AnimatedMCWalkthroughButton(titleMC.btn_walkthrough);
        
        Lic.PlayWithScoresButton(titleMC.buttonPlayWithHighcores);
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            titleMC.btn_prequel.buttonName.text = "Red Card 1";
        }
        
        Lic.AnimatedMCPrequelButton(titleMC.btn_prequel);
        
        Lic.AnimatedMCMoreGamesButton(titleMC.btn_moregames, "levelcomplete");
        
        Lic.SubmitScoreButton(titleMC.highscore.buttonSubmitScore, titleMC.highscore.buttonSubmitScoreName);
        
        if ((Levels.currentIndex & 1) == 0)
        {
            titleMC.buttonPlayWithHighcores.visible = false;
        }
        else
        {
            titleMC.btn_prequel.visible = false;
        }
        
        
        
        
        titleMC.gotoAndStop(1);
        
        TextStrings.ReplaceTextFieldText(titleMC.levelComplete.title);
        GameVars.InitTrophiesClip(titleMC.trophies);
        GameVars.InitCoinBoxClip(titleMC.coinBox);
        
        titleMC.levelName.textDescription.text = l.name;
        titleMC.scoreText1.textDescription.text = "";
        titleMC.scoreText1.textValue.text = "";
        titleMC.scoreText1.textAll.text = TextStrings.GetLocalisedText("Kicks") + ": " + GameVars.numKicks;
        
        
        
        titleMC.scoreText2.textDescription.text = "";
        titleMC.scoreText2.textValue.text = "";
        titleMC.scoreText2.textAll.text = TextStrings.GetLocalisedText("Gold") + ": " + GameVars.goldKicks;
        
        titleMC.levelrating.title.text = TextStrings.GetLocalisedText("Your Best") + ": " + l.bestShots;
        titleMC.levelrating.star.visible = false;
        if (l.rating != 0)
        {
            titleMC.levelrating.star.visible = true;
        }
        
        
        
        
        UI.AddAnimatedMCTickButton(titleMC.btn_feature1, null, "", false, null, GameVars.useFeature1);
        UI.AddAnimatedMCTickButton(titleMC.btn_feature2, null, "", false, null, GameVars.useFeature2);
        UI.AddAnimatedMCTickButton(titleMC.btn_feature3, null, "", false, null, GameVars.useFeature3);
        UI.AddAnimatedMCTickButton(titleMC.btn_feature4, null, "", false, null, GameVars.useFeature4);
        
        
        UI.AddInfoButton(titleMC.info1, "info1");
        UI.AddInfoButton(titleMC.info2, "info2");
        UI.AddInfoButton(titleMC.info3, "info3");
        UI.AddInfoButton(titleMC.info4, "info4");
        
        UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature1, false);
        UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature2, false);
        UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature3, false);
        UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature4, false);
        titleMC.btn_feature1.filters = [UI.greyFilter];
        titleMC.btn_feature2.filters = [UI.greyFilter];
        titleMC.btn_feature3.filters = [UI.greyFilter];
        titleMC.btn_feature4.filters = [UI.greyFilter];
        
        if (GameVars.IsFeatureUnlocked(0))
        {
            UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature1, true);
            titleMC.btn_feature1.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(1))
        {
            UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature2, true);
            titleMC.btn_feature2.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(2))
        {
            UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature3, true);
            titleMC.btn_feature3.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(3))
        {
            UI.AnimatedMCTickButtonSetCanPress(titleMC.btn_feature4, true);
            titleMC.btn_feature4.filters = [];
        }
    }
    
    
    private function buttonSubmitPressed(e : MouseEvent)
    {
        titleMC.btn_submit.visible = false;
    }
    private function buttonNextPressed(e : MouseEvent)
    {
        var l : Int = as3hx.Compat.parseInt(Levels.currentIndex + 1);
        
        if (l == 36)
        {
            UI.WaitAndStartTransition(titleMC, "gamecomplete");
        }
        else
        {
            Levels.IncrementLevel();
            UI.WaitAndStartTransition(titleMC, "gamescreen");
        }
    }
    private function buttonRetryPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "gamescreen");
    }
    private function buttonMenuPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "levelselect");
    }
    
    private function TransitionComplete()
    {
        titleMC.gotoAndPlay(1);
        
        onTransitionCompleteFunction = null;
    }
}


