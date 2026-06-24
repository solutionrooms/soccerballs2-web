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
        // openfl-swf does NOT reliably apply runtime alignment/autoSize to the embedded SWF text field,
        // so the "Your Best: n" value clipped and the star landed ON the number (getLineMetrics reported
        // a left-aligned layout while the field actually rendered right-aligned). Replace the SWF field
        // with a fresh openfl TextField overlay (device font, LEFT autoSize — metrics we can trust) and
        // anchor the star to the overlay's true right edge. Mirrors the HUD / level-select overlay fix.
        {
            var _lr : Dynamic = (untyped titleMC).levelrating;
            var _swf : Dynamic = _lr.title;
            var _ov : flash.text.TextField = new flash.text.TextField();
            _ov.selectable = false;
            _ov.mouseEnabled = false;
            _ov.embedFonts = false;
            _ov.autoSize = flash.text.TextFieldAutoSize.LEFT;
            var _fmt : flash.text.TextFormat = null;
            try { _fmt = _swf.getTextFormat(); } catch (e : Dynamic) {}
            if (_fmt == null) _fmt = new flash.text.TextFormat();
            _fmt.font = GameFont.FAMILY;
            _fmt.align = flash.text.TextFormatAlign.LEFT;
            _ov.defaultTextFormat = _fmt;
            _ov.text = TextStrings.GetLocalisedText("Your Best") + ": " + l.bestShots;
            _ov.setTextFormat(_fmt);
            try { _ov.x = _swf.x; _ov.y = _swf.y; _swf.visible = false; } catch (e : Dynamic) {}
            try { _lr.addChild(_ov); } catch (e : Dynamic) {}
            (untyped _lr).star.x = _ov.x + _ov.width + 8; // star just after the rendered text
        }
        
        
        
        
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

        // Strip the promo / highscore / extra UI (keep: title, level name, kicks/gold, your-best+star,
        // retry, next, feature toggles + info, trophies, coin box).
        UI.Hide((untyped titleMC).btn_submit);              // SUBMIT SCORE
        UI.Hide((untyped titleMC).buttonPlayWithHighcores); // Play with Highscores
        UI.Hide((untyped titleMC).highscore);               // highscore display
        UI.Hide((untyped titleMC).buttonLevelSelect);       // Level Select  (see note: removes menu link)
        UI.Hide((untyped titleMC).btn_walkthrough);         // WALKTHROUGH
        UI.Hide((untyped titleMC).btn_moregames);           // MORE GAMES
        UI.Hide((untyped titleMC).btn_prequel);             // prequel link
        UI.Hide((untyped titleMC).adBox);                   // ad box
    }
    
    
    public function buttonSubmitPressed(e : MouseEvent)
    {
        (untyped titleMC).btn_submit.visible = false;
    }
    public function buttonNextPressed(e : MouseEvent)
    {
        GD.ShowAd(); // mid-roll on the level-complete "next" button (SDK throttles real frequency)
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
        GD.ShowAd(); // mid-roll on the level-complete "replay" button
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


