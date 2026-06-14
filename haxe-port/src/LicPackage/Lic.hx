package licPackage;

import haxe.Constraints.Function;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.media.SoundMixer;
import flash.media.SoundTransform;
import flash.net.SendToURL;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.System;
import flash.text.TextField;
import flash.utils.Timer;
import cPMStar.*;
import mx.core.MovieClipLoaderAsset;
import uIPackage.UI;
import mochi.as3.*;

/**
	 * ...
	 * @author ...
	 */
class Lic
{
    
    public function new()
    {
    }
    
    public static var intro : MovieClip;
    
    
    public static function Playtomic_Log() : Void
    {
        Tracking.InitOnce();
        Tracking.LogView();
    }
    public static function Playtomic_Link(_url : String, _name : String, _group : String = "") : Void
    {
        flash.Lib.getURL(new URLRequest(_url), "_blank");
        Tracking.LogLink(_url, _name);
    }
    
    
    
    private static function AuthorLinkPressed(e : MouseEvent) : Void
    {
        if (LicDef.authorLinks.length == 0)
        {
            return;
        }
        
        var r : Int = Utils.RandBetweenInt(0, LicDef.authorLinks.length - 1);
        r = Utils.LimitNumber(0, LicDef.authorLinks.length - 1, r);
        cast((LicDef.authorLinks[r]), DoLink);
    }
    
    
    public static function GetLicensor() : Int
    {
        return LicDef.licensor;
    }
    
    
    public static function InitFromMain() : Void
    {
        InitHighscores();
    }
    
    
    public static function GetCurrentSku() : LicSku
    {
        return LicDef.GetSku(LicDef.GetLicensor());
    }
    
    
    private static var showSecondaryIntroCallback : Function;
    private static var showIntroCallback : Function;
    public static function ShowIntro(_showIntroCallback : Function) : Void
    {
        showIntroCallback = _showIntroCallback;
        if (GetCurrentSku().secondaryIntroName != "")
        {
            showSecondaryIntroCallback = showIntroCallback;
            showIntroCallback = ShowSecondaryIntro;
        }
        
        if (LicDef.IsOnCorrectSite() == false)
        {
            ShowSitelockedScreen();
            return;
        }
        
        if (GetCurrentSku().introName != "")
        {
            AddIntro(GetCurrentSku().introName, GetCurrentSku().introFPS);
        }
        else
        {
            showIntroCallback();
        }
    }
    
    public static function ShowSecondaryIntro() : Void
    {
        if (GetCurrentSku().secondaryIntroName != "")
        {
            cast((GetCurrentSku().secondaryIntroName), AddSecondaryIntro);
        }
        else
        {
            showIntroCallback();
        }
    }
    
    
    
    
    private static var oldFrameRate : Int;
    private static function AddIntro(mcName : String, _framerate : Int = 0)
    {
        var sku : LicSku = GetCurrentSku();
        
        var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass(mcName));
        var mc : MovieClip = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        
        
        oldFrameRate = LicDef.GetStage().stage.frameRate;
        if (_framerate != 0)
        {
            LicDef.GetStage().stage.frameRate = _framerate;
        }
        
        
        intro = mc;
        LicDef.GetStage().addChild(intro);
        intro.x = Defs.displayarea_w / 2;
        intro.y = Defs.displayarea_h / 2;
        
        intro.useHandCursor = true;
        intro.buttonMode = true;
        
        
        intro.addEventListener(Event.ENTER_FRAME, AddIntro_EnterFrame, false, 0, true);
        
        if (sku.linkURL != "")
        {
            intro.addEventListener(MouseEvent.CLICK, ClickedLinkURL, false, 0, true);
        }
        
        if (sku.scaleIntroToStage)
        {
            if (Defs.displayarea_w < 640)
            {
                intro.scaleX = intro.scaleY = (640 / intro.width);
            }
        }
        
        intro.gotoAndPlay(1);
    }
    
    private static function ClickedLinkURL(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        cast((sku.linkURL), DoLink);
    }
    private static function ClickedMainLogoURL(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        cast((sku.mainLogoLinkURL), DoLink);
    }
    
    private static function AddIntro_EnterFrame(e : Event)
    {
        if (intro == null)
        {
            return;
        }
        if (intro.totalFrames == intro.currentFrame)
        {
            LicDef.GetStage().stage.frameRate = oldFrameRate;
            
            var sku : LicSku = GetCurrentSku();
            if (sku.linkURL != "")
            {
                intro.removeEventListener(MouseEvent.CLICK, ClickedLinkURL);
            }
            intro.stop();
            intro.removeEventListener(Event.ENTER_FRAME, AddIntro_EnterFrame);
            LicDef.GetStage().removeChild(intro);
            intro = null;
            if (showIntroCallback != null)
            {
                showIntroCallback();
            }
        }
    }
    
    private static function AddSecondaryIntro(mcName : String)
    {
        var sku : LicSku = GetCurrentSku();
        
        var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass(mcName));
        intro = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        
        
        LicDef.GetStage().addChild(intro);
        intro.x = Defs.displayarea_w / 2;
        intro.y = Defs.displayarea_h / 2;
        
        intro.useHandCursor = true;
        intro.buttonMode = true;
        intro.mouseEnabled = true;
        
        intro.addEventListener(Event.ENTER_FRAME, AddSecondaryIntro_EnterFrame, false, 0, true);
        
        if (sku.secondaryIntroLinkURL != "")
        {
            intro.addEventListener(MouseEvent.CLICK, SecondaryIntro_Clicked, false, 0, true);
        }
        intro.gotoAndPlay(1);
    }
    
    private static function SecondaryIntro_Clicked(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        cast((sku.secondaryIntroLinkURL), DoLink);
    }
    
    public static function DoLink(linkStr : String, _extra : String = "")
    {
        var s : String = linkStr;
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE || LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            s += LicDef.referralString;
        }
        Playtomic_Link(s, _extra);
    }
    
    public static function DoLinkKongExtra(linkStr : String, _extra : String = "")
    {
        Tracking.LogLink(linkStr, _extra);
        
        var s : String = linkStr;
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE || LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            s += LicDef.referralString;
        }
        
        if (_extra != "")
        {
            s += _extra;
        }
        
        Utils.print("linking to " + s);
        
        flash.Lib.getURL(new URLRequest(s), "_blank");
    }
    
    private static function AddSecondaryIntro_EnterFrame(e : Event)
    {
        if (intro.totalFrames == intro.currentFrame)
        {
            var sku : LicSku = GetCurrentSku();
            if (sku.secondaryIntroLinkURL != "")
            {
                intro.removeEventListener(MouseEvent.CLICK, SecondaryIntro_Clicked);
            }
            intro.stop();
            intro.removeEventListener(Event.ENTER_FRAME, AddSecondaryIntro_EnterFrame);
            LicDef.GetStage().removeChild(intro);
            intro = null;
            if (showSecondaryIntroCallback != null)
            {
                showSecondaryIntroCallback();
            }
        }
    }
    
    
    
    private static function ShowSitelockedScreen()
    {
        intro = new MovieClip();  // SitelockedScreen();  
        intro.x = 0;
        intro.y = 0;
        LicDef.GetStage().addChild(intro);
        intro.addEventListener(MouseEvent.CLICK, SitelockScreen_Clicked);
    }
    private static function SitelockScreen_Clicked(e : MouseEvent)
    {
    }
    
    
    
    public static function Link_Walkthrough(e : MouseEvent, buttonString : String = "intro")
    {
    }
    
    
    public static function Link_TurboNukeRegister(e : MouseEvent, buttonString : String = "intro")
    {
        flash.Lib.getURL(new URLRequest("http://www.turbonuke.com/login.php"), "_self");
    }
    public static function Link_TurboNuke(e : MouseEvent, buttonString : String = "intro")
    {
        flash.Lib.getURL(new URLRequest("http://www.turbonuke.com?gamereferral=" + LicDef.referralName), "_blank");
    }
    
    
    
    
    
    
    
    
    
    public static function AuthorButton(mc : SimpleButton) : Void
    {
        if (mc == null)
        {
            return;
        }
        var sku : LicSku = GetCurrentSku();
        if (sku.allowAuthorLink == false)
        {
            mc.visible = false;
            return;
        }
        mc.addEventListener(MouseEvent.CLICK, AuthorLinkPressed, false, 0, true);
    }
    
    
    public static function PlayWithScoresButton(btn : SimpleButton)
    {
        if (btn == null)
        {
            return;
        }
        var sku : LicSku = GetCurrentSku();
        btn.visible = false;
        
        if (LicDef.GetDomain() == "notdoppler.com")
        {
            return;
        }
        if (LicDef.GetDomain() == "kaisergames.de")
        {
            return;
        }
        if (sku.playWithScoresURL == null)
        {
            return;
        }
        if (sku.playWithScoresURL == "")
        {
            return;
        }
        
        btn.visible = true;
        UI.AddButton(btn, PlayWithScoresButton_Clicked);
    }
    public static function PlayWithScoresButton_Clicked(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        DoLink(sku.playWithScoresURL, "play_with_scores");
    }
    
    public static function HasPrequelButton() : Bool
    {
        var sku : LicSku = GetCurrentSku();
        return sku.prequelLinkURL != "";
    }
    
    public static function AnimatedMCPrequelButton(mc : MovieClip)
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        if (LicDef.GetDomain() == "kaisergames.de")
        {
            return;
        }
        if (HasPrequelButton() == false)
        {
            return;
        }
        mc.visible = true;
        
        UI.AddAnimatedMCButton(mc, ClickedAnimatedMCPrequelButton);
    }
    private static function ClickedAnimatedMCPrequelButton(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        if (sku.prequelLinkURL != "")
        {
            cast((sku.prequelLinkURL), DoLink);
        }
    }
    public static function BarebonesMCPrequelButton(mc : MovieClip)
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        if (HasPrequelButton() == false)
        {
            return;
        }
        mc.visible = true;
        
        UI.AddBarebonesMCButton(mc, ClickedAnimatedMCPrequelButton);
    }
    
    
    
    public static function HasFacebookButton() : Bool
    {
        var sku : LicSku = GetCurrentSku();
        return sku.facebookLinkURL != "";
    }
    
    public static function AnimatedMCFacebookButton(mc : MovieClip)
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        if (HasFacebookButton() == false)
        {
            return;
        }
        mc.visible = true;
        
        UI.AddAnimatedMCButton(mc, ClickedAnimatedMCFacebookButton);
    }
    private static function ClickedAnimatedMCFacebookButton(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        if (sku.facebookLinkURL != "")
        {
            Playtomic_Link(sku.facebookLinkURL, "facebook");
        }
    }
    
    
    public static function Y8LogoButtonClicked(e : MouseEvent)
    {
        flash.Lib.getURL(new URLRequest("http://www.y8.com"), "_blank");
    }
    public static function Y8LogoButton(b : SimpleButton)
    {
        if (b == null)
        {
            return;
        }
        b.visible = false;
        if (LicDef.GetDomain() == "y8.com")
        {
            b.visible = true;
            UI.AddButton(b, Y8LogoButtonClicked);
        }
    }
    
    public static function HasDownloadForYourSiteButton() : Bool
    {
        if (LicAds.IsAtKiba())
        {
            return false;
        }
        var sku : LicSku = GetCurrentSku();
        return sku.downloadLinkURL != "";
    }
    
    public static function AnimatedMCDownloadForYourSiteButton(mc : MovieClip)
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        if (HasDownloadForYourSiteButton() == false)
        {
            return;
        }
        mc.visible = true;
        
        UI.AddAnimatedMCButton(mc, ClickedAnimatedMCDownloadForYourSiteButton);
    }
    private static function ClickedAnimatedMCDownloadForYourSiteButton(e : MouseEvent)
    {
        var sku : LicSku = GetCurrentSku();
        if (sku.downloadLinkURL != "")
        {
            DoLink(sku.downloadLinkURL, "download");
        }
    }
    
    
    
    
    
    
    private static function HasMoreGamesButton() : Bool
    {
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            return false;
        }
        
        var sku : LicSku = GetCurrentSku();
        return sku.showMoreGamesButton;
    }
    
    
    private static var moreGamesText : Array<Dynamic> = new Array<Dynamic>(
        "More Games", 
        "Free Games", 
        "Other Games", 
        "Great Games", 
        "Play More", 
        "Sport Games");
    
    private static var moreGamesTextLinks : Array<Dynamic> = new Array<Dynamic>(
        "http://www.kongregate.com", 
        "http://www.kongregate.com", 
        "http://www.kongregate.com", 
        "http://www.kongregate.com", 
        "http://www.kongregate.com", 
        "http://www.kongregate.com/sports-games");
    
    
    public static function ResetAnimatedMCMoreGamesButton(btn : MovieClip) : Void
    {
        if (btn == null)
        {
            return;
        }
        if (HasMoreGamesButton() == false)
        {
            btn.visible = false;
            return;
        }
        var sku : LicSku = GetCurrentSku();
        if (sku.linkURL == "")
        {
            btn.visible = false;
            return;
        }
        btn.moreGamesOverrideIndex = Utils.RandBetweenInt(0, moreGamesText.length - 1);
        btn.buttonName.text = moreGamesText[btn.moreGamesOverrideIndex];
    }
    public static function AnimatedMCMoreGamesButton(btn : MovieClip, _from : String) : Void
    {
        if (btn == null)
        {
            return;
        }
        if (HasMoreGamesButton() == false)
        {
            btn.visible = false;
            return;
        }
        var sku : LicSku = GetCurrentSku();
        if (sku.linkURL == "")
        {
            btn.visible = false;
            return;
        }
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE || LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            btn.moreGamesOverrideIndex = Utils.RandBetweenInt(0, moreGamesText.length - 1);
            btn.buttonName.text = moreGamesText[btn.moreGamesOverrideIndex];
            UI.AddAnimatedMCButton(btn, MoreGamesButtonMCPressed);
        }
        else if (LicDef.GetLicensor() == LicDef.LICENSOR_ANDKON)
        {
            btn.buttonName.text = "ANDKON";
            UI.AddAnimatedMCButton(btn, MoreGamesButtonMCPressedSimple);
        }
        else
        {
            UI.AddAnimatedMCButton(btn, MoreGamesButtonMCPressedSimple);
        }
    }
    
    
    
    private static function MoreGamesButtonMCPressedSimple(e : MouseEvent) : Void
    {
        var sku : LicSku = LicDef.GetCurrentSku();
        if (sku.linkURL != "")
        {
            cast((sku.linkURL), DoLink);
        }
    }
    private static function MoreGamesButtonMCPressed(e : MouseEvent) : Void
    {
        var btn : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        
        if (btn.moreGamesOverrideIndex == -1)
        {
            cast((e), ClickedLinkURL);
        }
        else if (btn.moreGamesOverrideIndex < 0 || btn.moreGamesOverrideIndex >= moreGamesTextLinks.length)
        {
            cast((e), ClickedLinkURL);
        }
        else
        {
            var str : String = moreGamesTextLinks[btn.moreGamesOverrideIndex];
            if (str == "")
            {
                var s : String = moreGamesText[btn.moreGamesOverrideIndex];
                s = "&from=" + StringTools.replace(s, " ", "_");
                DoLinkKongExtra(str, s);
            }
            else
            {
                var s : String = moreGamesText[btn.moreGamesOverrideIndex];
                s = "&from=" + StringTools.replace(s, " ", "_");
                DoLinkKongExtra(str, s);
            }
        }
    }
    
    public static function MCMoreGamesButton(btn : MovieClip, _from : String, noChange : Bool = false) : Void
    {
        if (btn == null)
        {
            return;
        }
        if (HasMoreGamesButton() == false)
        {
            btn.visible = false;
            return;
        }
        var sku : LicSku = GetCurrentSku();
        if (sku.linkURL == "")
        {
            btn.visible = false;
            return;
        }
        btn.moreGamesOverrideIndex = -1;
        if (noChange == false)
        {
            btn.moreGamesOverrideIndex = Utils.RandBetweenInt(0, moreGamesText.length - 1);
            btn.buttonName.text = moreGamesText[btn.moreGamesOverrideIndex];
        }
        
        if (btn.buttonName != null)
        {
            btn.buttonName.mouseEnabled = false;
        }
        
        UI.AddMCButton(btn, MoreGamesButtonMCPressed);
    }
    
    
    public static function MoreGamesButton(btn : SimpleButton, _from : String) : Void
    {
        if (btn == null)
        {
            return;
        }
        if (HasMoreGamesButton() == false)
        {
            btn.visible = false;
            return;
        }
        var sku : LicSku = GetCurrentSku();
        if (sku.linkURL == "")
        {
            btn.visible = false;
            return;
        }
        
        var mc : MovieClip = new MovieClip();
        btn.parent.addChild(mc);
        mc.x = btn.x;
        mc.y = btn.y;
        btn.parent.removeChild(btn);
        mc.addChild(btn);
        btn.x = 0;
        btn.y = 0;
        
        
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_ANDKON)
        {
            var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass("buttonMoreGamesAndkon"));
            var mc1 : SimpleButton = try cast(Type.createInstance(classRef, []), SimpleButton) catch(e:Dynamic) null;
            btn.parent.addChild(mc1);
            mc1.x = btn.x;
            mc1.y = btn.y;
            mc1.scaleX = btn.scaleX;
            mc1.scaleY = btn.scaleY;
            btn.parent.removeChild(btn);
            btn = mc1;
        }
        mc.moreGamesOverrideIndex = -1;
        mc.addEventListener(MouseEvent.CLICK, MoreGamesButtonMCPressed, false, 0, true);
        mc._from = _from;
    }
    
    
    
    
    
    private static function RemoveMainLogoButton(mc : MovieClip) : Void
    {
        if (mc == null)
        {
            return;
        }
        var sku : LicSku = GetCurrentSku();
        var logo : SimpleButton;
        var num : Int = mc.numChildren;
        for (i in 0...num)
        {
            logo = try cast(mc.getChildAt(i), SimpleButton) catch(e:Dynamic) null;
            if (logo != null)
            {
                logo.visible = false;
            }
            else
            {
                Utils.print("Lic: MainLogo Error. Null child found. (not a button?)");
            }
        }
    }
    
    public static function MainLogoButton(mc : MovieClip) : Void
    {
        if (mc == null)
        {
            return;
        }
        var sku : LicSku = GetCurrentSku();
        var logo : SimpleButton;
        var num : Int = mc.numChildren;
        for (i in 0...num)
        {
            logo = try cast(mc.getChildAt(i), SimpleButton) catch(e:Dynamic) null;
            if (logo != null)
            {
                logo.visible = false;
            }
            else
            {
                Utils.print("Lic: MainLogo Error. Null child found. (not a button?)");
            }
        }
        if (sku.mainLogoName != "")
        {
            logo = try cast(mc.getChildByName(sku.mainLogoName), SimpleButton) catch(e:Dynamic) null;
            if (logo != null)
            {
                logo.visible = true;
                if (sku.linkURL != "")
                {
                    if (sku.mainLogoLinkURL != "")
                    {
                        logo.addEventListener(MouseEvent.CLICK, ClickedMainLogoURL, false, 0, true);
                    }
                    else
                    {
                        logo.addEventListener(MouseEvent.CLICK, ClickedLinkURL, false, 0, true);
                    }
                }
                else
                {
                    logo.useHandCursor = false;
                }
            }
            else
            {
                Utils.print("Lic: MainLogo Error. Can't find logo: " + sku.mainLogoName);
            }
        }
    }
    
    
    /*
		static var facebookString:String;
		static function FacebookButton(mc:SimpleButton,str:String=""):void
		{
			if (mc == null) return;
			mc.visible = false;
			facebookString = str;
			mc.addEventListener(MouseEvent.CLICK, FacebookButtonPressed, false, 0, true);
		}
		public static function FacebookButtonPressed(e:MouseEvent)
		{
			var s:String = "http://www.facebook.com/sharer.php?u='http://www.turbonuke.com&referral=soccerballs'&t=Great game of CycloManiacs Racers";
			navigateToURL(new URLRequest(s), "_blank");
		}
		*/
    
    
    
    public static function AnimatedMCWalkthroughButton(mc : MovieClip) : Void
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        var sku : LicSku = GetCurrentSku();
        if (sku.walkthroughURL == "")
        {
            return;
        }
        
        UI.AddAnimatedMCButton(mc, WalkthroughButtonPressed, "walkthrough");
        mc.visible = true;
    }
    
    
    public static function WalkthroughButton(mc : SimpleButton) : Void
    {
        if (mc == null)
        {
            return;
        }
        mc.visible = false;
        var sku : LicSku = GetCurrentSku();
        if (sku.walkthroughURL == "")
        {
            return;
        }
        mc.visible = true;
        mc.addEventListener(MouseEvent.CLICK, WalkthroughButtonPressed, false, 0, true);
    }
    
    private static function WalkthroughButtonPressed(e : MouseEvent) : Void
    {
        var sku : LicSku = GetCurrentSku();
        cast((sku.walkthroughURL), DoLink);
    }
    
    
    
    
    /*
		static var twitterString:String;
		static function TwitterButton(mc:SimpleButton,str:String=""):void
		{
			if (mc == null) return;
			mc.visible = false;
			var sku:LicSku = GetCurrentSku();
			if (sku.twitterFunction == null) return;
			twitterString = str;
			mc.visible = true;
			mc.addEventListener(MouseEvent.CLICK, sku.twitterFunction, false, 0, true);
		}
		public static function TwitterButtonPressed(e:MouseEvent)
		{
			TwitterPost();
		}
		
		static var tinyLoader:URLLoader;
		static function TwitterPost():void
		{
			tinyLoader = new URLLoader();
			tinyLoader.dataFormat = URLLoaderDataFormat.TEXT;

			tinyLoader.addEventListener(Event.COMPLETE,TwitterPost_gotTinyURL);
			tinyLoader.load(new URLRequest('http://tinyurl.com/api-create.php?url=http://www.turbonuke.com&referral=twitter' ));
		}


		static function TwitterPost_gotTinyURL(event:Event):void
		{
			var reqString:String =  'http://twitter.com/home?status=Look out for Turbo Nuke' +  encodeURIComponent(tinyLoader.data);
			navigateToURL(new URLRequest(reqString), "_blank");
		}
		*/
    
    
    
    private static function RetrieveHighScore(mode : Int)
    {
        Game.CalculateScore();
        return Game.currentScore;
    }
    
    private static var submitScoreName : String = "Your Name";
    private static var submitScoreCallback : Function;
    private static var getHighScoreFunction : Function;
    private static var highScore_Textfield : TextField;
    private static var highScore_Button : MovieClip;
    
    public static function SubmitScoreButton(b : MovieClip, textField : TextField, _cb : Function = null) : Void
    {
        getHighScoreFunction = RetrieveHighScore;
        highScore_Textfield = textField;
        highScore_Button = b;
        
        submitScoreCallback = _cb;
        highScore_Button.visible = false;
        highScore_Textfield.visible = false;
        
        if (LicDef.GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            highScore_Button.visible = true;
            highScore_Textfield.visible = true;
            highScore_Textfield.text = submitScoreName;
            UI.AddAnimatedMCButton(highScore_Button, SubmitScore_Clicked_Callback);
        }
    }
    private static function SubmitScore_Clicked_Callback(e : MouseEvent)
    {
        highScore_Button.visible = false;
        highScore_Textfield.visible = false;
        
        var sc : Int = cast((0), RetrieveHighScore);
        submitScoreName = highScore_Textfield.text;
        if (GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            SubmitScore_MouseBreaker(sc, highScore_Textfield.text, SubmitScore_Complete_Callback);
        }
        if (GetLicensor() == LicDef.LICENSOR_ARMORGAMES)
        {
            SubmitScore_ArmorGames(sc, SubmitScore_Complete_Callback);
        }
    }
    private static function SubmitScore_Complete_Callback(e : MouseEvent)
    {
        if (submitScoreCallback != null)
        {
            submitScoreCallback();
        }
    }
    
    
    private static function ScoreSubmitted()
    {
    }
    
    
    public static function InitHighscores()
    {
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            InitHighScores_Kongregate();
        }
    }
    
    private static function InitHighScores_ArmorGames() : Void
    {
        var agi_url : String = "http://agi.armorgames.com/assets/agi/AGI.swf";
        Security.allowDomain(agi_url);
        Security.allowInsecureDomain(agi_url);
        
        
        
        var urlRequest : URLRequest = new URLRequest(agi_url);
        var loader : Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, InitHighScores_ArmorGames_LoadComplete);
        loader.load(urlRequest);
    }
    
    private static var agi : Dynamic;
    private static function InitHighScores_ArmorGames_LoadComplete(e : Event) : Void
    {
        agi = e.currentTarget.content;
        LicDef.GetStage().addChild(agi);
        
        agi.init(LicDef.armorHighScore_devKey, LicDef.armorHighScore_gameKey);
    }
    
    private static var highscore_callback : Function;
    private static function SubmitScore_ArmorGames(score : Int, _cb : Function = null)
    {
        highscore_callback = _cb;
        LicDef.GetStage().addChild(agi);
        agi.initAGUI({
                    onClose : SubmitHighscore_ArmorGames_CloseHandler
                });
        
        
        /* Parameters:
				score - The score the player achieved
				playerName - Name of the player. (optional)
				scoreType - Type of score you are submitting (Ex: "easy", "medium", "hard") (optional)
			*/
        agi.showScoreboardSubmit(score);
    }
    private static function ViewScore_ArmorGames(_cb : Function = null)
    {
        highscore_callback = _cb;
        LicDef.GetStage().addChild(agi);
        agi.initAGUI({
                    onClose : SubmitHighscore_ArmorGames_CloseHandler
                });
        
        agi.showScoreboardList();
    }
    private static function SubmitHighscore_ArmorGames_CloseHandler() : Void
    {
        LicDef.GetStage().removeChild(agi);
        if (highscore_callback != null)
        {
            highscore_callback(null);
        }
    }
    
    
    private static var kong_isLoaded : Bool = false;
    private static function InitHighScores_Kongregate()
    {
        var mochiLoader : Dynamic = LicDef.GetStage().stage.loaderInfo.loader;
        var paramObj : Dynamic = cast((LicDef.GetStage().stage.loaderInfo), LoaderInfo).parameters;
        
        var api_url : String = paramObj.api_path || "http://www.kongregate.com/flash/API_AS3_Local.swf";
        
        
        kong_isLoaded = false;
        
        var request : URLRequest = new URLRequest(api_url);
        var loader : Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, kong_loadComplete);
        loader.load(request);
        LicDef.GetStage().stage.addChild(loader);
    }
    
    private static var kongregate : Dynamic;
    
    /**
		* Called when API swf finishes loading
		*/
    private static function kong_loadComplete(event : Event) : Void
    {
        kongregate = event.target.content;
        
        kongregate.services.connect();
        
        trace("\n" + kongregate.services);
        trace("\n" + kongregate.user);
        trace("\n" + kongregate.scores);
        trace("\n" + kongregate.stats);
        kong_isLoaded = true;
    }
    
    
    public static function Kongregate_IsGuest() : Bool
    {
        if (LicDef.IsAtKongregate() == false)
        {
            return true;
        }
        if (kong_isLoaded == false)
        {
            return true;
        }
        return kongregate.stats.isGuest();
    }
    public static function Kongregate_GetUserName(def : String = "UserName") : String
    {
        if (LicDef.IsAtKongregate() == false)
        {
            return def;
        }
        if (kong_isLoaded == false)
        {
            return def;
        }
        return kongregate.services.getUsername();
    }
    public static function Kongregate_SubmitStat(value : Float, type : String)
    {
        if (LicDef.IsAtKongregate() == false)
        {
            return;
        }
        if (kong_isLoaded == false)
        {
            return;
        }
        Utils.print("Kong Stat: " + type + "  " + value);
        kongregate.stats.submit(type, value);
    }
    
    
    
    
    
    
    
    private static var callback : Function;
    public static function SubmitScore_MouseBreaker(score : Int, name : String, _cb : Function = null) : Void
    {
        callback = _cb;
        Utils.print("calling SubmitScore_MouseBreaker with score " + score + " and name: " + name);
        
        
        var url : String = LicDef.mouseBreaker_hiscore_url + "?" + as3hx.Compat.parseInt(Math.random() * 100000);
        var reqURL : URLRequest = new URLRequest(url);
        var variables : URLVariables = new URLVariables();
        
        variables.score = score;
        variables.username = name;
        
        reqURL.data = variables;
        
        reqURL.method = URLRequestMethod.POST;
        var loader : URLLoader = new URLLoader(reqURL);
        loader.addEventListener(Event.COMPLETE, SubmitScore_MouseBreaker_Complete);
        loader.dataFormat = URLLoaderDataFormat.VARIABLES;
    }
    
    private static function SubmitScore_MouseBreaker_Complete(e : Event)
    {
        callback(null);
    }
}






