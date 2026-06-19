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
        __hudDumped = false; // re-dump the HUD geometry once for the new level (diagnostic)
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

    // The bottom-left counter fields (kicksText/starText/coinsText) are narrow SWF dynamic fields whose
    // openfl-swf rendering doesn't reflect runtime .text/.x/format changes (5 attempts moved the object
    // per the metadata but never the pixels). So we OWN them: hide the SWF fields and draw our own
    // TextFields on top — sized/placed to each field's box, Komika Axis, centred, white with a black
    // glow for contrast (matching the original's crisp bottom-of-box number). Fresh fields render
    // predictably, unlike the imported ones.
    static var ovCreated : Bool = false;
    static var kicksOv : flash.text.TextField = null;
    static var starOv : flash.text.TextField = null;
    static var coinsOv : flash.text.TextField = null;
    static inline var OV_DY : Float = 5; // nudge digits down to the bottom of the box (matches original)

    static function MakeOverlay(src : Dynamic) : flash.text.TextField
    {
        var tf = new flash.text.TextField();
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.embedFonts = false;
        tf.multiline = false;
        tf.wordWrap = false;
        tf.autoSize = flash.text.TextFieldAutoSize.NONE;
        tf.x = src.x;
        tf.y = src.y + OV_DY;
        tf.width = src.width;
        tf.height = src.height;
        var fmt = new flash.text.TextFormat(GameFont.FAMILY, 12, 0xFFFFFF, true);
        fmt.align = flash.text.TextFormatAlign.CENTER;
        tf.defaultTextFormat = fmt;
        // black halo so the white digit reads over the icon/box (the original has a similar outline)
        tf.filters = [new flash.filters.GlowFilter(0x000000, 1, 3, 3, 5, 1)];
        return tf;
    }

    function CreateCounterOverlays() : Void
    {
        if (ovCreated) return;
        #if (js && html5)
        try
        {
            var ma : Dynamic = (untyped hudMC).mainArea;
            kicksOv = MakeOverlay(ma.kicksText); kicksOv.name = "kicksOv";
            starOv  = MakeOverlay(ma.starText);  starOv.name  = "starOv";
            coinsOv = MakeOverlay(ma.coinsText); coinsOv.name = "coinsOv";
            ma.addChild(kicksOv);
            ma.addChild(starOv);
            ma.addChild(coinsOv);
            ma.kicksText.visible = false; // hide the SWF originals; our overlays replace them
            ma.starText.visible = false;
            ma.coinsText.visible = false;
            ovCreated = true;
        }
        catch (e : Dynamic) {}
        #end
    }

    static function SetOverlay(tf : flash.text.TextField, s : String) : Void
    {
        if (tf == null) return;
        try
        {
            tf.text = s;
            var fmt = tf.getTextFormat();
            fmt.font = GameFont.FAMILY;
            fmt.align = flash.text.TextFormatAlign.CENTER;
            tf.setTextFormat(fmt);
        }
        catch (e : Dynamic) {}
    }

    function UpdateCounterOverlays(kicks : String, star : String, coins : String) : Void
    {
        if (!ovCreated) return;
        SetOverlay(kicksOv, kicks);
        SetOverlay(starOv, star);
        SetOverlay(coinsOv, coins);
    }

    // ---- DIAGNOSTIC (bottom-left counters position) -------------------------------------------
    // Dumps the real on-screen geometry of every element in hudMC.mainArea + detail on the three
    // counter fields, so we can see why kicks/star/coins land wrong. Auto-fires once per level; also
    // callable any time from the JS console as sb2DumpHud(). Tagged [HUD3]. Remove once fixed.
    static var __hudDumped : Bool = false;

    static inline function rnd(v : Float) : Float { return Math.round(v * 10) / 10; }
    static inline function clog(s : String) : Void { #if (js && html5) js.Browser.console.log(s); #end }

    @:expose("sb2DumpHud") public static function sb2DumpHud() : Void
    {
        if (Game.hudController != null) Game.hudController.ForceDumpHud();
    }
    public function ForceDumpHud() : Void { __hudDumped = false; DumpHud(); }

    function dumpField(label : String, tf : Dynamic) : Void
    {
        #if (js && html5)
        if (tf == null) { clog("[HUD3] " + label + " = NULL"); return; }
        try
        {
            var g : flash.geom.Point = tf.localToGlobal(new flash.geom.Point(0, 0));
            var fmt : Dynamic = tf.getTextFormat();
            // actual rendered position of the first glyph (field-local), so we can see where the digit
            // really lands vs the field box — the missing measurement that confirms centre vs left.
            var glyph : String = "n/a";
            try { var cb : Dynamic = tf.getCharBoundaries(0); if (cb != null) glyph = "x=" + rnd(cb.x) + " w=" + rnd(cb.width) + " (glyphCentreGlobal=" + rnd(g.x + cb.x + cb.width / 2) + ")"; }
            catch (ce : Dynamic) {}
            clog("[HUD3] " + label + " text='" + tf.text + "'"
                + " local(x=" + rnd(tf.x) + ",y=" + rnd(tf.y) + ",w=" + rnd(tf.width) + ",h=" + rnd(tf.height) + ")"
                + " global(x=" + rnd(g.x) + ",y=" + rnd(g.y) + ")"
                + " textW=" + rnd(tf.textWidth) + " textH=" + rnd(tf.textHeight)
                + " align=" + fmt.align + " font='" + fmt.font + "' size=" + fmt.size
                + " glyph0[" + glyph + "]");
        }
        catch (e : Dynamic) { clog("[HUD3] " + label + " err " + e); }
        #end
    }

    function DumpHud() : Void
    {
        #if (js && html5)
        if (__hudDumped) return;
        __hudDumped = true;
        try
        {
            var ma : Dynamic = (untyped hudMC).mainArea;
            var hg : flash.geom.Point = hudMC.localToGlobal(new flash.geom.Point(0, 0));
            clog("[HUD3] ===== HUD dump (level " + (Levels.currentIndex + 1) + ") =====");
            clog("[HUD3] stage size " + Main.theStage.stageWidth + "x" + Main.theStage.stageHeight);
            clog("[HUD3] hudMC local(x=" + rnd(hudMC.x) + ",y=" + rnd(hudMC.y) + ") scale(" + rnd(hudMC.scaleX)
                + "," + rnd(hudMC.scaleY) + ") global(x=" + rnd(hg.x) + ",y=" + rnd(hg.y) + ") vis=" + hudMC.visible);
            var mg : flash.geom.Point = ma.localToGlobal(new flash.geom.Point(0, 0));
            clog("[HUD3] mainArea local(x=" + rnd(ma.x) + ",y=" + rnd(ma.y) + ") scale(" + rnd(ma.scaleX)
                + "," + rnd(ma.scaleY) + ") global(x=" + rnd(mg.x) + ",y=" + rnd(mg.y) + ") children=" + ma.numChildren);
            var n : Int = ma.numChildren;
            for (i in 0...n)
            {
                var c : Dynamic = ma.getChildAt(i);
                var cg : flash.geom.Point = c.localToGlobal(new flash.geom.Point(0, 0));
                clog("[HUD3]  [" + i + "] '" + c.name + "' x=" + rnd(c.x) + " y=" + rnd(c.y)
                    + " w=" + rnd(c.width) + " h=" + rnd(c.height)
                    + " gx=" + rnd(cg.x) + " gy=" + rnd(cg.y) + " vis=" + c.visible);
            }
            clog("[HUD3] BUILD=overlays-v1  ovCreated=" + ovCreated + " (expect children=27, kicksText vis=false)");
            dumpField("kicksText", ma.kicksText);
            dumpField("starText", ma.starText);
            dumpField("coinsText", ma.coinsText);
            clog("[HUD3] ===== end =====");
        }
        catch (e : Dynamic) { clog("[HUD3] dump err " + e); }
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
        // openfl-swf won't re-render these imported fields on .text/.x change, so draw our own overlays
        // on top (hiding the SWF originals) and feed them the same values.
        CreateCounterOverlays();
        UpdateCounterOverlays(Std.string(remainingKicks), Std.string(goldRemainingKicks),
            GameVars.numLevelCoinsCollected + "/" + GameVars.totalLevelCoins);
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

        DumpHud(); // one-shot HUD geometry diagnostic (self-gates via __hudDumped); see [HUD3] logs

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


