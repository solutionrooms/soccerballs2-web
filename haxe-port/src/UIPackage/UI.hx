package uIPackage;

import haxe.Constraints.Function;
import audioPackage.Audio;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.StageQuality;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.system.System;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Mouse;
import licPackage.Lic;
import licPackage.LicDef;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UI
{
    private static var muteButtonReverse : Bool = true;
    
    private static var onTransitionCompleteFunction : Function = null;
    private static var returnScreenName : String = "";
    
    private static var screenTemplates : Array<Dynamic>;
    
    public function new()
    {
        InitOnce();
    }
    
    private static var screenA : MovieClip = null;
    private static var screenB : MovieClip = null;
    
    private static var globalMC_help : MovieClip;
    private static var globalMC_areYouSure : MovieClip;
    
    
    public static var lastCreatedScreen : MovieClip;
    
    private static function AddScreen(mc : MovieClip) : MovieClip
    {
        lastCreatedScreen = mc;
        return mc;
    }
    private static function RemoveScreen(mc : MovieClip) : MovieClip
    {
        lastCreatedScreen = null;
        return mc;
    }
    public static function InitOnce()
    {
        screenA = null;
        screenB = null;
        lastCreatedScreen = null;
        trans_screenA = null;
        trans_screenB = null;
        
        
        currentScreen = null;
        
        screenTemplates = new Array<Dynamic>();
        screenTemplates.push(new UIScreen("title", false, UITitleScreen, null));
        screenTemplates.push(new UIScreen("achievements", false, UIAchievements, null));
        screenTemplates.push(new UIScreen("levelselect", false, UILevelSelect, null));
        screenTemplates.push(new UIScreen("levelcomplete", false, UILevelComplete, null));
        screenTemplates.push(new UIScreen("gamecomplete", false, UIGameCompleteScreen, null));
        screenTemplates.push(new UIScreen("areyousure_cleardata", false, UIAreYouSureClearData, null));
        screenTemplates.push(new UIScreen("levelfailed", false, UILevelFailedScreen, null));
        screenTemplates.push(new UIScreen("preparingscreen", false, UIPreparingScreen, null));
        screenTemplates.push(new UIScreen("gamescreen", false, UIGameScreen, null));
        screenTemplates.push(new UIScreen("credits", false, UICredits, null));
        screenTemplates.push(new UIScreen("kitscreen", false, UIKitSelect, null));
        screenTemplates.push(new UIScreen("matchselect", false, UIMatchSelect, null));
        screenTemplates.push(new UIScreen("pickateam", false, UIPickATeam, null));
        screenTemplates.push(new UIScreen("walkthrough", false, UIWalkthrough, null));
        screenTemplates.push(new UIScreen("walkthrough_screen", false, UIWalkthroughScreen, null));
        screenTemplates.push(new UIScreen("language", false, UILanguageSelect, null));
    }
    
    private static var titleMC : MovieClip;
    
    
    
    
    
    
    public static function RemoveGeneric()
    {
        if (genericMC == null)
        {
            return;
        }
        
        
        genericMC = null;
    }
    
    public static function Generic_OptionsClicked(e : MouseEvent)
    {
        Utils.print("options clicked");
    }
    public static var genericMC : MovieClip = null;
    public static function UpdateGeneric()
    {
        if (genericMC == null)
        {
            return;
        }
        
        genericMC.textScore.text = Game.currentScore;
    }
    public static function AddGeneric(parent : MovieClip, removeStuff : Bool = false)
    {
        if (parent == null)
        {
            return;
        }
        
        
        
        
        genericMC = new UiHud();
        parent.addChild(genericMC);
        
        TextStrings.ReplaceTextFieldText(genericMC.textTitle);
        AddAnimatedSFXMuteButton(genericMC.btn_sfxMute);
        AddAnimatedMusicMuteButton(genericMC.btn_musicMute);
        
        
        
        
        
        
        
        
        
        UpdateGeneric();
    }
    
    
    
    
    private static var addButtonList : Array<Dynamic> = null;
    public static function ReorderButtonList(topMost : MovieClip)
    {
        if (addButtonList == null)
        {
            return;
        }
        var parent : MovieClip = try cast(topMost.parent, MovieClip) catch(e:Dynamic) null;
        parent.setChildIndex(topMost, parent.numChildren - 1);
    }
    public static function AddToButtonList(mc : MovieClip, removeFunc : Function)
    {
        if (addButtonList == null)
        {
            return;
        }
        var o : Dynamic = {};
        o.mc = mc;
        o.removeFunc = removeFunc;
        addButtonList.push(o);
    }
    public static function RemoveAllButtons()
    {
        for (o in addButtonList)
        {
            var mc : MovieClip = o.mc;
            var f : Function = o.removeFunc;
            f(mc);
        }
        addButtonList = null;
    }
    public static function StartAddButtons()
    {
        addButtonList = new Array<Dynamic>();
    }
    
    
    
    
    
    
    
    
    
    public static var currentScreen : UIScreenInstance;
    public static var nextScreen : UIScreenInstance;
    
    
    private static function GetUIScreenTemplateByName(_name : String)
    {
        for (template in screenTemplates)
        {
            if (template.name == _name)
            {
                return template;
            }
        }
        return null;
    }
    
    
    private static function TransitionMakeInstance(_name : String) : UIScreenInstance
    {
        var template : UIScreen = GetUIScreenTemplateByName(_name);
        var inst : UIScreenInstance = new template.TheClass();
        inst.active = true;
        inst.template = template;
        inst.Start();
        return inst;
    }
    
    private static var overlay_parent : UIScreenInstance;
    private static function RemoveOverlay()
    {
        nextScreen.Stop();
        Game.main.removeChild(nextScreen.titleMC);
        nextScreen = null;
    }
    public static function StartOverlay(_toScreen : String)
    {
        nextScreen = TransitionMakeInstance(_toScreen);
        Game.main.addChild(nextScreen.titleMC);
    }
    
    public static function StartTransitionImmediate(_toScreen : String, _completeFunction : Function = null, _returnScreenName : String = "")
    {
        LicDef.GetStage().stage.frameRate = Defs.ui_fps;
        LicDef.GetStage().stage.quality = StageQuality.HIGH;
        
        
        returnScreenName = _returnScreenName;
        trans_completeFunction = _completeFunction;
        if (currentScreen != null)
        {
            currentScreen.Stop();
            if (currentScreen.titleMC.parent != null)
            {
                currentScreen.titleMC.parent.removeChild(currentScreen.titleMC);
                currentScreen.titleMC = null;
            }
            currentScreen = null;
        }
        if (_toScreen == null)
        {
            trans_completeFunction();
        }
        else
        {
            nextScreen = TransitionMakeInstance(_toScreen);
            currentScreen = nextScreen;
            nextScreen = null;
            Game.main.addChild(currentScreen.titleMC);
            
            currentScreen.OnComplete();
        }
    }
    
    public static var isInTransition : Bool = false;
    
    private static var exitScreenMC : MovieClip = null;
    private static var exitScreenTimer : Int = 0;
    private static var exitScreenLocation : String = "";
    public static function WaitAndExitScreenEnterFrame(e : Event)
    {
        exitScreenTimer++;
        if (exitScreenTimer >= 4)
        {
            exitScreenTimer = 0;
            exitScreenMC.removeEventListener(Event.ENTER_FRAME, WaitAndExitScreenEnterFrame);
            StartTransition(exitScreenLocation);
        }
    }
    public static function WaitAndStartTransition(_mc : MovieClip, _exitScreenLocation : String)
    {
        if (exitScreenTimer != 0)
        {
            return;
        }
        exitScreenMC = _mc;
        exitScreenLocation = _exitScreenLocation;
        exitScreenMC.addEventListener(Event.ENTER_FRAME, WaitAndExitScreenEnterFrame, false, 0, true);
    }
    
    public static function StartTransition(_toScreen : String, _completeFunction : Function = null, _returnScreenName : String = "")
    {
        LicDef.GetStage().stage.frameRate = Defs.ui_fps;
        LicDef.GetStage().stage.quality = StageQuality.HIGH;
        
        returnScreenName = _returnScreenName;
        trans_completeFunction = _completeFunction;
        
        
        if (useFullTransition == false)
        {
            if (currentScreen != null)
            {
                currentScreen.Stop();
                if (currentScreen.titleMC.parent != null)
                {
                    currentScreen.titleMC.parent.removeChild(currentScreen.titleMC);
                    currentScreen.titleMC = null;
                }
                currentScreen = null;
            }
            if (_toScreen == null)
            {
                trans_completeFunction();
            }
            else
            {
                nextScreen = TransitionMakeInstance(_toScreen);
                currentScreen = nextScreen;
                nextScreen = null;
                Game.main.addChild(currentScreen.titleMC);
                
                currentScreen.OnComplete();
            }
        }
        else
        {
            Audio.OneShot("sfx_transition");
            isInTransition = true;
            
            
            transScreenA_BD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, false, 0);
            transScreenB_BD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, false, 0);
            transScreenA_B = new Bitmap(transScreenA_BD);
            transScreenB_B = new Bitmap(transScreenB_BD);
            
            
            if (currentScreen != null)
            {
                currentScreen.Stop();
                
                currentScreen.RenderForTransition(transScreenA_BD);
                
                
                if (currentScreen.titleMC.parent != null)
                {
                    currentScreen.titleMC.parent.removeChild(currentScreen.titleMC);
                    currentScreen.titleMC = null;
                }
                
                currentScreen = null;
            }
            
            
            if (_toScreen != null)
            {
                nextScreen = TransitionMakeInstance(_toScreen);
                transScreenB_BD.draw(nextScreen.titleMC);
            }
            else
            {
                nextScreen = null;
            }
            
            
            globalMC_transition = new Transition();
            globalMC_transition.visible = true;
            Game.main.addChild(globalMC_transition);
            globalMC_transition.addEventListener(Event.ENTER_FRAME, TransitionEnterFrame, false, 0, true);
            globalMC_transition.gotoAndPlay(1);
            globalMC_transition.cacheAsBitmap = true;
            
            globalMC_transition.screenA.addChild(transScreenA_B);
            globalMC_transition.screenB.addChild(transScreenB_B);
        }
    }
    
    private static function TransitionEnterFrame(e : Event)
    {
        if (globalMC_transition == null)
        {
            return;
        }
        if (globalMC_transition.currentFrame == globalMC_transition.totalFrames)
        {
            e.stopImmediatePropagation();
            e.stopPropagation();
            globalMC_transition.removeEventListener(Event.ENTER_FRAME, TransitionEnterFrame);
            globalMC_transition.stop();
            globalMC_transition.visible = false;
            
            if (trans_screenA != null)
            {
                globalMC_transition.screenA.removeChild(transScreenA_B);
                trans_screenA = null;
            }
            if (trans_screenB != null)
            {
                globalMC_transition.screenB.removeChild(transScreenB_B);
                Game.main.addChild(trans_screenB);
            }
            
            Game.main.removeChild(globalMC_transition);
            globalMC_transition = null;
            
            
            if (nextScreen != null)
            {
                Game.main.addChild(nextScreen.titleMC);
                currentScreen = nextScreen;
            }
            else if (trans_completeFunction != null)
            {
                trans_completeFunction();
            }
            
            if (currentScreen != null)
            {
                currentScreen.OnComplete();
            }
            
            isInTransition = false;
        }
    }
    
    
    
    private static var globalMC_transition : MovieClip;
    private static var trans_screenA : MovieClip;
    private static var trans_screenB : MovieClip;
    private static var trans_completeFunction : Function;
    
    private static var transScreenA_BD : BitmapData;
    private static var transScreenB_BD : BitmapData;
    private static var transScreenA_B : Bitmap;
    private static var transScreenB_B : Bitmap;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    public static function SetupAnimatedSFXMuteButton(mc : MovieClip)
    {
        mc.toggleIcon.visible = true;
        if (Audio.IsMuteSFX())
        {
            mc.toggleIcon.visible = false;
        }
        
        if (muteButtonReverse)
        {
            mc.toggleIcon.visible = (mc.toggleIcon.visible == false);
        }
    }
    
    public static function AddAnimatedSFXMuteButton(btn : MovieClip, text : String = null)
    {
        if (btn == null)
        {
            Utils.print("add MCbutton button = null");
        }
        
        btn.helpText = text;
        
        SetupAnimatedSFXMuteButton(btn);
        
        btn.gotoAndStop(1);
        btn.addEventListener(MouseEvent.ROLL_OVER, AnimatedSFXMuteButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, AnimatedSFXMuteButton_Out, false, 0, true);
        
        btn.useHandCursor = true;
        btn.buttonMode = true;
        
        btn.addEventListener(MouseEvent.CLICK, AnimatedSFXMuteButton_Click, false, 0, true);
    }
    
    
    public static function RemoveAnimatedSFXMuteButton(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.ROLL_OVER, AnimatedSFXMuteButton_Over);
        btn.removeEventListener(MouseEvent.ROLL_OUT, AnimatedSFXMuteButton_Out);
        
        btn.removeEventListener(MouseEvent.CLICK, AnimatedSFXMuteButton_Click);
    }
    public static function AnimatedSFXMuteButton_Click(e : MouseEvent)
    {
        e.currentTarget.buttonAnimation.gotoAndPlay("clicked");
        
        Audio.ToggleMuteSFX();
        SetupAnimatedSFXMuteButton(try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null);
    }
    public static function AnimatedSFXMuteButton_Over(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.buttonAnimation.gotoAndPlay("over");
        if (e.currentTarget.helpText != null)
        {
        }
    }
    public static function AnimatedSFXMuteButton_Out(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.buttonAnimation.gotoAndPlay("out");
        if (e.currentTarget.helpText != null)
        {
        }
    }
    
    
    
    
    
    public static function SetupAnimatedMusicMuteButton(mc : MovieClip)
    {
        mc.toggleIcon.visible = true;
        if (Audio.IsMuteMusic())
        {
            mc.toggleIcon.visible = false;
        }
        if (muteButtonReverse)
        {
            mc.toggleIcon.visible = (mc.toggleIcon.visible == false);
        }
    }
    
    public static function AddAnimatedMusicMuteButton(btn : MovieClip, text : String = null)
    {
        if (btn == null)
        {
            Utils.print("add MCbutton button = null");
        }
        
        btn.helpText = text;
        
        SetupAnimatedMusicMuteButton(btn);
        
        btn.gotoAndStop(1);
        btn.addEventListener(MouseEvent.ROLL_OVER, AnimatedMusicMuteButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, AnimatedMusicMuteButton_Out, false, 0, true);
        
        btn.useHandCursor = true;
        btn.buttonMode = true;
        
        btn.addEventListener(MouseEvent.CLICK, AnimatedMusicMuteButton_Click, false, 0, true);
    }
    
    
    public static function RemoveAnimatedMusicMuteButton(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.ROLL_OVER, AnimatedMusicMuteButton_Over);
        btn.removeEventListener(MouseEvent.ROLL_OUT, AnimatedMusicMuteButton_Out);
        
        btn.removeEventListener(MouseEvent.CLICK, AnimatedMusicMuteButton_Click);
    }
    public static function AnimatedMusicMuteButton_Click(e : MouseEvent)
    {
        e.currentTarget.buttonAnimation.gotoAndPlay("clicked");
        
        Audio.ToggleMuteMusic();
        SetupAnimatedMusicMuteButton(try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null);
    }
    public static function AnimatedMusicMuteButton_Over(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.buttonAnimation.gotoAndPlay("over");
        if (e.currentTarget.helpText != null)
        {
        }
    }
    public static function AnimatedMusicMuteButton_Out(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.buttonAnimation.gotoAndPlay("out");
        if (e.currentTarget.helpText != null)
        {
        }
    }
    
    
    
    
    
    public static function StopPropagation(e : MouseEvent)
    {
        e.stopPropagation();
        e.stopImmediatePropagation();
    }
    public static function SetNonPropagateMouse(btn : MovieClip)
    {
        btn.addEventListener(MouseEvent.MOUSE_DOWN, nonPropagate);
        btn.addEventListener(MouseEvent.MOUSE_UP, nonPropagate);
        btn.addEventListener(MouseEvent.MOUSE_MOVE, nonPropagate);
    }
    private static function nonPropagate(e : MouseEvent)
    {
        StopPropagation(e);
    }
    
    
    
    
    public static function AddBarebonesMCButton(btn : MovieClip, clickCallback : Function, _overCB : Function = null, _outCB : Function = null, _text : String = null)
    {
        btn._clickCB = clickCallback;
        btn._overCB = _overCB;
        btn._outCB = _outCB;
        btn.addEventListener(MouseEvent.CLICK, BarebonesMCButton_Click, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OVER, BarebonesMCButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, BarebonesMCButton_Out, false, 0, true);
        btn.useHandCursor = true;
        btn.buttonMode = true;
        AddToButtonList(btn, RemoveBarebonesMCButton);
    }
    public static function RemoveBarebonesMCButton(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.ROLL_OVER, BarebonesMCButton_Over);
        btn.removeEventListener(MouseEvent.ROLL_OUT, BarebonesMCButton_Out);
        btn.removeEventListener(MouseEvent.CLICK, BarebonesMCButton_Click);
    }
    private static function BarebonesMCButton_Click(e : MouseEvent)
    {
        Audio.OneShot("sfx_click", 0, 0.2);
        if (e.currentTarget._clickCB != null)
        {
            e.currentTarget._clickCB(e);
        }
    }
    private static function BarebonesMCButton_Over(e : MouseEvent)
    {
        if (e.currentTarget._overCB != null)
        {
            e.currentTarget._overCB(e);
        }
    }
    private static function BarebonesMCButton_Out(e : MouseEvent)
    {
        if (e.currentTarget._outCB != null)
        {
            e.currentTarget._outCB(e);
        }
    }
    
    
    
    
    public static function AddAnimatedMCButton_Mobile(btn : MovieClip, clickCallback : Function, text : String = null, reorderWhenOver : Bool = false, _hoverCallback)
    {
        if (btn == null)
        {
            Utils.print("add MCbutton button = null");
        }
        if (clickCallback == null)
        {
            Utils.print("add MCbutton clickCallback = null");
        }
        
        
        
        btn.reorderWhenOver = false;
        btn.helpText = text;
        if (text != null)
        {
            btn.buttonName.text = text;
        }
        
        
        btn.clickCallback = clickCallback;
        btn.hoverCallback = _hoverCallback;
        
        btn.buttonAnimation.gotoAndStop(1);
        
        if (false)
        {
            btn.buttonAnimation.buttonText.buttonName.text = btn.buttonName.text;
            btn.buttonName.visible = false;
            btn.buttonAnimation.buttonText.visible = true;
            btn.buttonAnimation.buttonText.mouseEnabled = false;
            btn.buttonName.mouseEnabled = false;
        }
        if (btn.buttonName != null)
        {
            btn.buttonName.mouseEnabled = false;
        }
        
        
        btn.addEventListener(MouseEvent.MOUSE_DOWN, AnimatedMCButton_Mobile_Down, false, 0, true);
        
        
        
        
        if (Game.use_localisation)
        {
            TextStrings.SetAnimatedButtonText(btn);
        }
        
        AddToButtonList(btn, RemoveAnimatedMCButton_Mobile);
    }
    
    public static function RemoveAnimatedMCButton_Mobile(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.MOUSE_DOWN, AnimatedMCButton_Mobile_Down);
    }
    
    
    public static function AnimatedMCButton_Mobile_Down(e : MouseEvent)
    {
        e.currentTarget.buttonAnimation.gotoAndPlay("clicked");
        Audio.OneShot("sfx_click", 0, 0.2);
        
        
        if (e.currentTarget.clickCallback != null)
        {
            e.currentTarget.clickCallback(e);
        }
    }
    
    
    
    
    
    public static function AddInfoButton(btn : MovieClip, text : String)
    {
        btn.popup.visible = false;
        btn.addEventListener(MouseEvent.ROLL_OVER, InfoButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, InfoButton_Out, false, 0, true);
        btn.popup.infoText.text = TextStrings.GetLocalisedText(text);
    }
    public static function InfoButton_Over(e : MouseEvent)
    {
        var btn : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        btn.popup.visible = true;
    }
    public static function InfoButton_Out(e : MouseEvent)
    {
        var btn : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        btn.popup.visible = false;
    }
    
    
    
    
    
    public static function GetAnimatedMCTickState(btn : MovieClip) : Bool
    {
        return btn.tickState;
    }
    public static function AnimatedMCTickButtonSetCanPress(btn : MovieClip, b : Bool)
    {
        btn.canClick = b;
    }
    public static function AddAnimatedMCTickButton(btn : MovieClip, clickCallback : Function, text : String = null, reorderWhenOver : Bool = false, _hoverCallback : Dynamic = null, _initialTickState : Bool = false)
    {
        AddAnimatedMCButton(btn, clickCallback, text, reorderWhenOver, _hoverCallback);
        btn.useTick = true;
        btn.tickState = _initialTickState;
        btn.tick.visible = btn.tickState;
    }
    
    public static function AddAnimatedMCButton(btn : MovieClip, clickCallback : Function, text : String = null, reorderWhenOver : Bool = false, _hoverCallback)
    {
        if (false)
        {
            return AddAnimatedMCButton_Mobile(btn, clickCallback, text, reorderWhenOver, _hoverCallback);
        }
        
        if (btn == null)
        {
            Utils.print("add MCbutton button = null");
        }
        if (clickCallback == null)
        {
            Utils.print("add MCbutton clickCallback = null");
        }
        
        SetNonPropagateMouse(btn);
        
        if (Game.use_localisation)
        {
            TextStrings.SetAnimatedButtonText(btn);
        }
        
        btn.mouseChildren = false;
        
        btn.canClick = true;
        
        btn.reorderWhenOver = false;
        btn.helpText = text;
        if (text != null)
        {
            if (Game.use_localisation)
            {
                text = TextStrings.GetLocalisedText(text);
            }
            btn.buttonName.text = text;
        }
        
        
        btn.clickCallback = clickCallback;
        btn.hoverCallback = _hoverCallback;
        
        btn.buttonAnimation.gotoAndStop(1);
        
        if (btn.buttonName != null)
        {
            TextStrings.ReplaceTextFieldText(btn.buttonName);
            
            if (btn.buttonAnimation.buttonText != null)
            {
                btn.buttonAnimation.buttonText.buttonName.text = btn.buttonName.text;
                btn.buttonName.visible = false;
                btn.buttonAnimation.buttonText.visible = true;
                btn.buttonAnimation.buttonText.mouseEnabled = false;
                btn.buttonName.mouseEnabled = false;
                btn.buttonAnimation.buttonText.buttonName.setTextFormat(btn.buttonName.getTextFormat());
            }
        }
        if (btn.buttonName != null)
        {
            btn.buttonName.mouseEnabled = false;
        }
        
        
        btn.addEventListener(MouseEvent.ROLL_OVER, AnimatedMCButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, AnimatedMCButton_Out, false, 0, true);
        
        
        btn.useHandCursor = true;
        btn.buttonMode = true;
        btn.addEventListener(MouseEvent.CLICK, AnimatedMCButton_Click, false, 0, true);
        
        
        AddToButtonList(btn, RemoveAnimatedMCButton);
    }
    
    
    public static function RemoveAnimatedMCButton(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.ROLL_OVER, AnimatedMCButton_Over);
        btn.removeEventListener(MouseEvent.ROLL_OUT, AnimatedMCButton_Out);
        btn.removeEventListener(MouseEvent.CLICK, AnimatedMCButton_Click);
    }
    public static function AnimatedMCButton_Click(e : MouseEvent)
    {
        if (e.currentTarget.useTick)
        {
            if (e.currentTarget.canClick)
            {
                e.currentTarget.tickState = (e.currentTarget.tickState == false);
                e.currentTarget.tick.visible = e.currentTarget.tickState;
            }
        }
        
        e.currentTarget.buttonAnimation.gotoAndPlay("clicked");
        Audio.OneShot("sfx_click", 0, 0.2);
        if (e.currentTarget.clickCallback != null)
        {
            e.currentTarget.clickCallback(e);
        }
    }
    public static function AnimatedMCButton_Over(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        
        if (e.currentTarget.reorderWhenOver)
        {
            ReorderButtonList(try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null);
        }
        
        if (e.currentTarget.hoverCallback != null)
        {
            e.currentTarget.descendants("hoverCallback")(e);
        }
        
        e.currentTarget.buttonAnimation.gotoAndPlay("over");
    }
    public static function AnimatedMCButton_Out(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.buttonAnimation.gotoAndPlay("out");
        if (e.currentTarget.helpText != null)
        {
        }
    }
    
    
    
    
    
    
    public static function EnableMCButton(mc : MovieClip)
    {
        mc.filters = [];
        mc.mouseEnabled = true;
    }
    public static function DisableMCButton(mc : MovieClip)
    {
        mc.filters = [greyFilter];
        mc.mouseEnabled = false;
    }
    public static var greyFilter : ColorMatrixFilter = new ColorMatrixFilter([0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0, 0, 0, 1, 0]);
    public static var blackFilter : ColorMatrixFilter = new ColorMatrixFilter([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]);
    
    
    public static function AddButton(btn : SimpleButton, clickCallback : Function)
    {
        if (btn == null)
        {
            Utils.print("add button button = null");
        }
        if (clickCallback == null)
        {
            Utils.print("add button clickCallback = null");
        }
        btn.addEventListener(MouseEvent.CLICK, clickCallback, false, 0, true);
    }
    public static function AddMCButton(btn : MovieClip, clickCallback : Function, text : String = null, hoverCallback : Function = null, outCallback : Function = null)
    {
        if (btn == null)
        {
            Utils.print("add MCbutton button = null");
        }
        if (clickCallback == null)
        {
            Utils.print("add MCbutton clickCallback = null");
        }
        
        btn.helpText = text;
        
        btn.gotoAndStop(1);
        btn.addEventListener(MouseEvent.ROLL_OVER, MCButton_Over, false, 0, true);
        btn.addEventListener(MouseEvent.ROLL_OUT, MCButton_Out, false, 0, true);
        btn.addEventListener(MouseEvent.MOUSE_DOWN, MCButton_Down, false, 0, true);
        
        btn.useHandCursor = true;
        btn.buttonMode = true;
        
        btn.clickCallback = clickCallback;
        btn.hoverCallback = hoverCallback;
        btn.outCallback = outCallback;
        
        btn.addEventListener(MouseEvent.MOUSE_UP, MCButton_Click, false, 0, true);
        AddToButtonList(btn, RemoveMCButton);
    }
    public static function RemoveMCButton(btn : MovieClip)
    {
        btn.removeEventListener(MouseEvent.ROLL_OVER, MCButton_Over);
        btn.removeEventListener(MouseEvent.ROLL_OUT, MCButton_Out);
        btn.removeEventListener(MouseEvent.MOUSE_DOWN, MCButton_Down);
        btn.removeEventListener(MouseEvent.MOUSE_UP, MCButton_Click);
    }
    public static function MCButton_Click(e : MouseEvent)
    {
        Audio.OneShot("sfx_click", 0, 0.2);
        e.currentTarget.gotoAndStop(1);
        e.currentTarget.clickCallback(e);
    }
    public static function MCButton_Over(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        
        if (e.currentTarget.hoverCallback != null)
        {
            e.currentTarget.hoverCallback(e);
        }
        
        if (e.currentTarget.currentFrame != 3)
        {
            e.currentTarget.gotoAndStop(2);
        }
        if (e.currentTarget.helpText != null)
        {
        }
    }
    public static function MCButton_Out(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        if (e.currentTarget.outCallback != null)
        {
            e.currentTarget.outCallback(e);
        }
        e.currentTarget.gotoAndStop(1);
        if (e.currentTarget.helpText != null)
        {
        }
    }
    public static function MCButton_Down(e : MouseEvent)
    {
        if (e.currentTarget == null)
        {
            return;
        }
        e.currentTarget.gotoAndStop(3);
    }
    
    
    
    
    
    public static function KeypressSFXMuteButton(mc : MovieClip)
    {
        mc.gotoAndStop(3);
        Audio.ToggleMuteSFX();
        SetupSFXMuteButton(mc);
    }
    public static function SetupSFXMuteButton(mc : MovieClip)
    {
        mc.toggleIcon.visible = false;
        if (Audio.IsMuteSFX())
        {
            mc.toggleIcon.visible = true;
        }
    }
    public static function InitSFXMuteButton(mc : MovieClip)
    {
        mc.gotoAndStop(1);
        mc.addEventListener(MouseEvent.MOUSE_OVER, SFXMuteButton_Over, false, 0, true);
        mc.addEventListener(MouseEvent.MOUSE_OUT, SFXMuteButton_Out, false, 0, true);
        mc.addEventListener(MouseEvent.MOUSE_DOWN, SFXMuteButton_Down, false, 0, true);
        
        SetNonPropagateMouse(mc);
        SetupSFXMuteButton(mc);
        
        mc.useHandCursor = true;
        mc.buttonMode = true;
    }
    public static function SFXMuteButton_Over(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(2);
    }
    public static function SFXMuteButton_Out(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(1);
    }
    public static function SFXMuteButton_Down(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(3);
        Audio.ToggleMuteSFX();
        SetupSFXMuteButton(try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null);
    }
    
    
    public static function KeypressMusicMuteButton(mc : MovieClip)
    {
        mc.gotoAndStop(3);
        Audio.ToggleMuteMusic();
        SetupSFXMuteButton(mc);
    }
    public static function SetupMusicMuteButton(mc : MovieClip)
    {
        mc.toggleIcon.visible = false;
        if (Audio.IsMuteMusic())
        {
            mc.toggleIcon.visible = true;
        }
    }
    public static function InitMusicMuteButton(mc : MovieClip)
    {
        mc.gotoAndStop(1);
        mc.addEventListener(MouseEvent.MOUSE_OVER, MusicMuteButton_Over, false, 0, true);
        mc.addEventListener(MouseEvent.MOUSE_OUT, MusicMuteButton_Out, false, 0, true);
        mc.addEventListener(MouseEvent.MOUSE_DOWN, MusicMuteButton_Down, false, 0, true);
        
        SetNonPropagateMouse(mc);
        SetupMusicMuteButton(mc);
        
        mc.useHandCursor = true;
        mc.buttonMode = true;
    }
    public static function MusicMuteButton_Over(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(2);
    }
    public static function MusicMuteButton_Out(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(1);
    }
    public static function MusicMuteButton_Down(e : MouseEvent)
    {
        e.currentTarget.gotoAndStop(3);
        Audio.ToggleMuteMusic();
        SetupSFXMuteButton(try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null);
    }
    
    
    
    
    
    
    
    
    
    
    private static var debugSkipMovies : Bool = false;
    private static var playMovieMC : MovieClip = null;
    private static var playMovieCallback : Function;
    private static var playMovieButtonSkip : Bool;
    private static var playMovieLoop : Bool;
    private static function PlayMovie_Click(e : Event)
    {
        PlayMovie_Close();
    }
    private static function PlayMovie_Close()
    {
        playMovieMC.stop();
        if (playMovieButtonSkip)
        {
            playMovieMC.removeEventListener(MouseEvent.CLICK, PlayMovie_Click);
        }
        playMovieMC.removeEventListener(Event.ENTER_FRAME, PlayMovie_EnterFrame);
        Game.main.removeChild(playMovieMC);
        playMovieMC = null;
        if (playMovieCallback != null)
        {
            playMovieCallback();
        }
    }
    
    public static function StopMovie()
    {
        if (playMovieMC == null)
        {
            return;
        }
        PlayMovie_Close();
    }
    
    private static function PlayMovie_EnterFrame(e : Event)
    {
        if (playMovieLoop)
        {
            return;
        }
        if (playMovieMC == null)
        {
            return;
        }
        if (playMovieMC.currentFrame == playMovieMC.totalFrames)
        {
        }
    }
    private static function PlayMovie(movie : Dynamic, _cb : Function, _buttonSkip : Bool = false, _loop : Bool = false)
    {
        playMovieButtonSkip = _buttonSkip;
        playMovieLoop = _loop;
        playMovieCallback = _cb;
        if (debugSkipMovies)
        {
            if (playMovieCallback != null)
            {
                playMovieCallback();
            }
            return;
        }
        
        if (Std.is(movie, String))
        {
            var movieName = Std.string(movie);
            var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass(movieName));
            playMovieMC = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        }
        else if (Std.is(movie, MovieClip))
        {
            var mc = try cast(movie, MovieClip) catch(e:Dynamic) null;
            playMovieMC = mc;
        }
        
        playMovieMC.addEventListener(Event.ENTER_FRAME, PlayMovie_EnterFrame, false, 0, true);
        if (playMovieButtonSkip)
        {
            playMovieMC.addEventListener(MouseEvent.CLICK, PlayMovie_Click, false, 0, true);
        }
        Game.main.addChild(playMovieMC);
        playMovieMC.gotoAndPlay(1);
    }
    
    
    
    
    private static var areYouSureDialog : MovieClip;
    private static var areYouSureDialogParent : MovieClip;
    private static var areYouSureDialogCallback : Function;
    
    public static function AddAreYouSureDialog_Yes(e : MouseEvent)
    {
        RemoveAreYouSureDialog();
        areYouSureDialogCallback(true);
    }
    public static function AddAreYouSureDialog_No(e : MouseEvent)
    {
        RemoveAreYouSureDialog();
        areYouSureDialogCallback(false);
    }
    public static function RemoveAreYouSureDialog()
    {
        areYouSureDialogParent.removeChild(areYouSureDialog);
        areYouSureDialog = null;
    }
    public static function AddAreYouSureDialog(parent : MovieClip, title : String, cb : Function)
    {
        areYouSureDialogParent = parent;
        areYouSureDialog = new MovieClip();
        parent.addChild(areYouSureDialog);
        
        parent.setChildIndex(areYouSureDialog, parent.numChildren - 1);
        
        areYouSureDialogCallback = cb;
        
        areYouSureDialog.textQuestion.text = title;
        AddAnimatedMCButton(areYouSureDialog.btn_yes, AddAreYouSureDialog_Yes);
        AddAnimatedMCButton(areYouSureDialog.btn_no, AddAreYouSureDialog_No);
    }
    
    
    private static var helpPage : Int;
    private static var numHelpPages : Int;
    private static var helpOverlay : MovieClip;
    private static var helpOverlayParent : MovieClip;
    public static function InitHelp(parent : MovieClip)
    {
        helpOverlayParent = parent;
        helpOverlay = new MovieClip();
        helpOverlayParent.addChild(helpOverlay);
        AddAnimatedMCButton(helpOverlay.buttonPrevious, Help_PrevPressed);
        AddAnimatedMCButton(helpOverlay.buttonNext, Help_NextPressed);
        AddAnimatedMCButton(helpOverlay.buttonCancel, Help_CancelPressed);
        numHelpPages = helpOverlay.totalFrames;
        helpPage = 0;
        
        InitHelp_Update();
    }
    private static function InitHelp_Update()
    {
        helpOverlay.gotoAndStop(helpPage + 1);
        
        
        helpOverlay.buttonPrevious.visible = true;
        if (helpPage == 0)
        {
            helpOverlay.buttonPrevious.visible = false;
        }
        helpOverlay.buttonNext.visible = true;
        if (helpPage == numHelpPages - 1)
        {
            helpOverlay.buttonNext.visible = false;
        }
    }
    
    
    
    private static function Help_CancelPressed(e : MouseEvent)
    {
        helpOverlayParent.removeChild(helpOverlay);
        helpOverlay = null;
        Game.pause = false;
    }
    
    private static function Help_NextPressed(e : MouseEvent)
    {
        helpPage++;
        helpPage = Utils.LimitNumber(0, numHelpPages - 1, helpPage);
        InitHelp_Update();
    }
    private static function Help_PrevPressed(e : MouseEvent)
    {
        helpPage--;
        helpPage = Utils.LimitNumber(0, numHelpPages - 1, helpPage);
        InitHelp_Update();
    }
    
    
    public static function StartColorLines()
    {
        colors0 = new Array<Dynamic>();
        colors1 = new Array<Dynamic>();
        str0 = "";
        str1 = "";
        lineColCount = 0;
    }
    
    private static var str0 : String;
    private static var str1 : String;
    private static var lineColCount : Int;
    private static var colors0 : Array<Dynamic>;
    private static var colors1 : Array<Dynamic>;
    public static function AddLine(s0 : String, newline : Bool = true)
    {
        var a : Int;
        var b : Int;
        
        a = str0.length;
        str0 += s0;
        b = str0.length;
        if (newline)
        {
            str0 += "\n";
        }
        var o : Dynamic = {};
        o.a = a;
        o.b = b;
        o.lineColCount = lineColCount;
        colors0.push(o);
        
        
        lineColCount++;
        if (lineColCount >= 2)
        {
            lineColCount = 0;
        }
    }
    
    public static function SetColorLines(tf : TextField)
    {
        tf.text = str0;
        var statsColor0 : TextFormat = new TextFormat(null, null, 0xc0c0c0);
        var statsColor1 : TextFormat = new TextFormat(null, null, 0xe0e0e0);
        for (o in colors0)
        {
            if (o.lineColCount == 0)
            {
                tf.setTextFormat(statsColor0, o.a, o.b);
            }
            if (o.lineColCount == 1)
            {
                tf.setTextFormat(statsColor1, o.a, o.b);
            }
        }
    }
    private static var useFullTransition : Bool = true;

}

