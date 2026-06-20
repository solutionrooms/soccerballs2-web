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
        GameVars.useFeature1 = UI.GetAnimatedMCTickState((untyped titleMC).btn_feature1);
        GameVars.useFeature2 = UI.GetAnimatedMCTickState((untyped titleMC).btn_feature2);
        GameVars.useFeature3 = UI.GetAnimatedMCTickState((untyped titleMC).btn_feature3);
        GameVars.useFeature4 = UI.GetAnimatedMCTickState((untyped titleMC).btn_feature4);
        
        UI.RemoveAllButtons();
        UI.RemoveGeneric();
        
        if (AreOtherGamesAdsAllowed())
        {
            AdHolder.RemoveAd((untyped titleMC).adBox.adloader);
        }
    }
    
    public function AreOtherGamesAdsAllowed() : Bool
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
    
    public var b : Bitmap;
    
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
            (untyped titleMC).adBox.adloader.addChild(AdHolder.GetAd());
        }
        else
        {
            (untyped titleMC).adBox.visible = false;
        }
        
        
        
        
        UI.AddAnimatedMCButton((untyped titleMC).buttonLevelSelect, buttonMenuPressed);
        UI.AddAnimatedMCButton((untyped titleMC.levelComplete).btn_continue, buttonNextPressed);
        UI.AddAnimatedMCButton((untyped titleMC).levelComplete.btn_tryagain, buttonRetryPressed);
        
        Lic.AnimatedMCWalkthroughButton((untyped titleMC).btn_walkthrough);
        
        Lic.PlayWithScoresButton((untyped titleMC).buttonPlayWithHighcores);
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            (untyped titleMC.btn_prequel).buttonName.text = "Red Card 1";
        }
        
        Lic.AnimatedMCPrequelButton((untyped titleMC).btn_prequel);
        
        Lic.AnimatedMCMoreGamesButton((untyped titleMC).btn_moregames, "levelcomplete");
        
        Lic.SubmitScoreButton((untyped titleMC).highscore.buttonSubmitScore, (untyped titleMC).highscore.buttonSubmitScoreName);
        
        if ((Levels.currentIndex & 1) == 0)
        {
            (untyped titleMC).buttonPlayWithHighcores.visible = false;
        }
        else
        {
            (untyped titleMC).btn_prequel.visible = false;
        }
        
        
        
        
        titleMC.gotoAndStop(1);
        
        TextStrings.ReplaceTextFieldText((untyped titleMC.levelComplete).title);
        GameVars.InitTrophiesClip((untyped titleMC).trophies);
        GameVars.InitCoinBoxClip((untyped titleMC).coinBox);
        
        (untyped titleMC.levelName).textDescription.text = Std.string(l.name);
        (untyped titleMC.scoreText1).textDescription.text = "";
        (untyped titleMC).scoreText1.textValue.text = "";
        (untyped titleMC).scoreText1.textAll.text = TextStrings.GetLocalisedText("Kicks") + ": " + GameVars.numKicks;
        
        
        
        (untyped titleMC.scoreText2).textDescription.text = "";
        (untyped titleMC).scoreText2.textValue.text = "";
        (untyped titleMC).scoreText2.textAll.text = TextStrings.GetLocalisedText("Gold") + ": " + GameVars.goldKicks;
        
        (untyped titleMC.levelrating).title.text = TextStrings.GetLocalisedText("Your Best") + ": " + l.bestShots;
        (untyped titleMC).levelrating.star.visible = false;
        if (l.rating != 0)
        {
            (untyped titleMC).levelrating.star.visible = true;
        }
        // Our font metrics differ from the original Flash font, so the star's fixed
        // symbol x no longer sits snug after "YOUR BEST: n" (it floats off to the
        // right). Anchor it to the rendered text width instead. The title field is
        // left-aligned with the standard ~2px TextField gutter.
        (untyped titleMC).levelrating.star.x =
            (untyped titleMC).levelrating.title.x + (untyped titleMC).levelrating.title.textWidth + 8;
        
        
        
        
        UI.AddAnimatedMCTickButton((untyped titleMC).btn_feature1, null, "", false, null, GameVars.useFeature1);
        UI.AddAnimatedMCTickButton((untyped titleMC).btn_feature2, null, "", false, null, GameVars.useFeature2);
        UI.AddAnimatedMCTickButton((untyped titleMC).btn_feature3, null, "", false, null, GameVars.useFeature3);
        UI.AddAnimatedMCTickButton((untyped titleMC).btn_feature4, null, "", false, null, GameVars.useFeature4);
        
        
        UI.AddInfoButton((untyped titleMC).info1, "info1");
        UI.AddInfoButton((untyped titleMC).info2, "info2");
        UI.AddInfoButton((untyped titleMC).info3, "info3");
        UI.AddInfoButton((untyped titleMC).info4, "info4");
        
        UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature1, false);
        UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature2, false);
        UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature3, false);
        UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature4, false);
        (untyped titleMC).btn_feature1.filters = [UI.greyFilter];
        (untyped titleMC).btn_feature2.filters = [UI.greyFilter];
        (untyped titleMC).btn_feature3.filters = [UI.greyFilter];
        (untyped titleMC).btn_feature4.filters = [UI.greyFilter];
        
        if (GameVars.IsFeatureUnlocked(0))
        {
            UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature1, true);
            (untyped titleMC).btn_feature1.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(1))
        {
            UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature2, true);
            (untyped titleMC).btn_feature2.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(2))
        {
            UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature3, true);
            (untyped titleMC).btn_feature3.filters = [];
        }
        if (GameVars.IsFeatureUnlocked(3))
        {
            UI.AnimatedMCTickButtonSetCanPress((untyped titleMC).btn_feature4, true);
            (untyped titleMC).btn_feature4.filters = [];
        }
    }
    
    
    public function buttonSubmitPressed(e : MouseEvent)
    {
        (untyped titleMC).btn_submit.visible = false;
    }
    public function buttonNextPressed(e : MouseEvent)
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
    public function buttonRetryPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "gamescreen");
    }
    public function buttonMenuPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "levelselect");
    }
    
    public function TransitionComplete()
    {
        titleMC.gotoAndPlay(1);
        
        onTransitionCompleteFunction = null;
    }
}


