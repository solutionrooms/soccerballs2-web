package licPackage;

import mochi.as3.*;

import haxe.Constraints.Function;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.net.URLRequest;
import flash.system.Security;
import flash.utils.Timer;
import cPMStar.*;
import uIPackage.UI;

/**
	 * ...
	 * @author Julian
	 */
class LicAds
{
    
    
    
    public static var intro : MovieClip;
    public static var cx : Int;
    public static var cy : Int;
    private static var oldFrameRate : Int = 0;
    
    
    public static function GetLicensor() : Int
    {
        return LicDef.GetLicensor();
    }
    
    public static function GetSku(skuID : Int) : LicSku
    {
        return LicDef.GetSku(skuID);
    }
    
    public static function GetCurrentSku() : LicSku
    {
        return LicDef.GetSku(LicDef.GetLicensor());
    }
    
    
    
    public static function IsAtGames1() : Bool
    {
        var domain : String = LicDef.GetDomain();
        if (domain == "games1.com")
        {
            return true;
        }
        return false;
    }
    public static function IsAtNotDoppler() : Bool
    {
        var domain : String = LicDef.GetDomain();
        if (domain == "notdoppler.com")
        {
            return true;
        }
        return false;
    }
    
    public static function ShouldTryLoadAdXML() : Bool
    {
        var domain : String = LicDef.GetDomain();
        if (domain == "kongregate.com")
        {
            return false;
        }
        if (domain == "3366.com")
        {
            return false;
        }
        if (domain == "3366img.com")
        {
            return false;
        }
        if (domain == "7k7k.com")
        {
            return false;
        }
        if (domain == "4399.com")
        {
            return false;
        }
        if (domain == "qq.com")
        {
            return false;
        }
        if (domain == "kaisergames.de")
        {
            return false;
        }
        if (domain == "gamezhero.com")
        {
            return false;
        }
        return true;
    }
    public static function FilterAdForSites() : Bool
    {
        var domain : String = LicDef.GetDomain();
        
        if (domain == "kongregate.com")
        {
            return true;
        }
        if (domain == "agame.com")
        {
            return true;
        }
        if (domain == "armorgames.com")
        {
            return true;
        }
        if (domain == "flashgamelicense.com")
        {
            return true;
        }
        if (domain == "gamesheep.com")
        {
            return true;
        }
        if (domain == "ejocuri.ro")
        {
            return true;
        }
        if (domain == "ejocurigratis.ro")
        {
            return true;
        }
        if (domain == "jaludo.com")
        {
            return true;
        }
        if (domain == "gamezhero.com")
        {
            return true;
        }
        
        if (IsAtKiba())
        {
            return true;
        }
        if (IsAtGames1())
        {
            return true;
        }
        return false;
    }
    
    private static var showAdFinishedCallback : Function;
    public static function ShowAd(_showAdFinishedCallback : Function)
    {
        oldFrameRate = 0;
        intro = null;
        cx = as3hx.Compat.parseInt(Defs.displayarea_w / 2);
        cy = as3hx.Compat.parseInt(Defs.displayarea_h / 2);
        
        
        showAdFinishedCallback = _showAdFinishedCallback;
        var adtype : Int = GetCurrentSku().adtype;
        
        if (AdHolder.IsLoadedPreAdAvailable() && adtype != LicDef.ADTYPE_NONE)
        {
            ShowTurboNukeAd();
        }
        else if (adtype == LicDef.ADTYPE_NONE)
        {
            ShowNoAd();
        }
        else if (adtype == LicDef.ADTYPE_MOCHI_VC)
        {
            ShowNoAd();
        }
        else if (adtype == LicDef.ADTYPE_MOCHI)
        {
            ShowMochiAd_Preload();
        }
        else if (adtype == LicDef.ADTYPE_CPMSTAR)
        {
            if (FilterAdForSites() == false)
            {
                ShowCPMStarAd();
            }
            else
            {
                ShowNoAd();
            }
        }
        else if (adtype == LicDef.ADTYPE_EPICGAMEADS)
        {
            if (FilterAdForSites() == false)
            {
                ShowEpicGameAd();
            }
            else
            {
                ShowNoAd();
            }
        }
    }
    
    
    
    private static function CPMStarLoadingEventCallback(event : Event) : Void
    {
        var bytestotal = LicDef.GetStage().stage.loaderInfo.bytesTotal;
        var bytesloaded = LicDef.GetStage().stage.loaderInfo.bytesLoaded;
        
        var val : Float = 1 / bytestotal * bytesloaded;
        cast((val), RenderLoaderBar);
        if (bytesloaded >= bytestotal)
        {
            LicDef.GetStage().removeEventListener(Event.ENTER_FRAME, CPMStarLoadingEventCallback);
            cpmStarLoaderCounter++;
            CPMStarCompleteCallback();
        }
    }
    
    private static function CPMStarCompleteCallback() : Void
    {
        if (cpmStarLoaderCounter >= 2)
        {
            if (intro.loaderBar != null)
            {
                intro.loaderBar.visible = false;
            }
            intro.buttonSkipCPMStarAd.visible = true;
            
            if (LicDef.GetCurrentSku().skipPreloaderContinueButton)
            {
                buttonSkipCPMStarAdPressed(null);
            }
        }
    }
    
    
    private static function CPMStarTimerCallback(e : TimerEvent) : Void
    {
        cpmStarLoadTimer++;
        if (cpmStarLoadTimer >= LicDef.CPMStarFixedTime)
        {
            cpmStarLoaderCounter++;
            cpmStarTimer.stop();
            CPMStarCompleteCallback();
        }
        else
        {
            cpmStarTimer.start();
        }
    }
    private static var cpmStarLoadTimer : Int;
    private static var cpmStarLoaderCounter : Int;
    private static var cpmStarTimer : Timer;
    private static var ad : DisplayObject = null;
    
    private static function RenderLoaderBar(val : Float) : Void
    {
        if (intro == null)
        {
            return;
        }
        if (intro.loaderBar != null)
        {
            var newVal : Int = ScaleTo(1, intro.loaderBar.totalFrames, 0, 1, val);
            intro.loaderBar.gotoAndStop(newVal);
        }
    }
    public static function ScaleTo(f0 : Float, f1 : Float, o0 : Float, o1 : Float, val : Float) : Float
    {
        var od : Float = o1 - o0;
        var fd : Float = f1 - f0;
        
        var d : Float = 1.0 / od * (val - o0);
        d = (fd * d) + f0;
        
        return d;
    }
    
    public static function RandBetweenInt(r0 : Int, r1 : Int) : Int
    {
        var r : Int = as3hx.Compat.parseInt(Math.random() * ((r1 - r0) + 1));
        r += r0;
        return r;
    }
    
    
    private static function AddIntroScreenAndSetUpButtons()
    {
        intro = new Preloader();
        intro.x = 0;  // cx;  
        intro.y = 0;  // cy;  
        ScreenSize.ScaleMovieClip(intro);
        
        
        LicDef.GetStage().addChild(intro);
        
        cast((intro.mainLogo), MainLogoButton);
        
        intro.logo_soccerballs.gotoAndStop(1);
        if (LicDef.GetLicensor() == LicDef.LICENSOR_MOUSEBREAKER)
        {
            intro.logo_soccerballs.gotoAndStop(2);
        }
        
        
        UI.AddAnimatedMCButton(intro.buttonSkipCPMStarAd, buttonSkipCPMStarAdPressed);
        cast((intro.turboBtn), AuthorButton);
        intro.buttonSkipCPMStarAd.visible = false;
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
    private static function AuthorLinkPressed(e : MouseEvent) : Void
    {
        if (LicDef.authorLinks.length == 0)
        {
            return;
        }
        
        var r : Int = RandBetweenInt(0, LicDef.authorLinks.length - 1);
        r = LimitNumber(0, LicDef.authorLinks.length - 1, r);
        cast((LicDef.authorLinks[r]), DoLink);
    }
    public static function LimitNumber(f0 : Float, f1 : Float, n : Float) : Float
    {
        if (n < f0)
        {
            n = f0;
        }
        if (n > f1)
        {
            n = f1;
        }
        return n;
    }
    
    
    public static function ShowTurboNukeAd() : Void
    {
        AddIntroScreenAndSetUpButtons();
        
        var adItem : AdItem = AdHolder.GetPreAdItem();
        if (adItem != null)
        {
            ad = AdHolder.GetPreAdCustomMC(intro.adBox);
            intro.adBox.addChild(ad);
            
            if (adItem.url != "")
            {
                intro.adBox.addEventListener(MouseEvent.CLICK, AdHolder.PreAdClicked);
                intro.adBox.buttonMode = true;
                intro.adBox.useHandCursor = true;
            }
        }
        
        cpmStarLoaderCounter = 0;
        LicDef.GetStage().addEventListener(Event.ENTER_FRAME, CPMStarLoadingEventCallback);
        cpmStarTimer = new Timer(1000);
        cpmStarTimer.addEventListener(TimerEvent.TIMER, CPMStarTimerCallback);
        cpmStarTimer.start();
    }
    
    
    
    /*
var myEpicGameAdsPublisherCode:String="3run02qoxt";
var myEpicGameAdsGameID:String="1";
var myEpicGameAdsBgSolid:int=0; // 1 = enabled (show the ad background filled with color), 0 = disabled
var myEpicGameAdsBgColor:uint=0x000000; // background hex RGB color if background is solid
var myEpicGameAdsFadeIn:int=1; // 1 = enabled, 2 = disabled (no fade in)
var myEpicGameAdsFadeFrames:int=24; // how many frames in fadeIn default 24

var epicXPos:int=0;
var epicYPos:int=0;
setRegPoint(this,epicXPos,epicYPos);
var sEpicRefURL:String=loaderInfo.loaderURL;
var oEpicUserInfo:Object={publisherCode:myEpicGameAdsPublisherCode,gameId:myEpicGameAdsGameID,refURL:sEpicRefURL,bgSolid:myEpicGameAdsBgSolid,bgColor:myEpicGameAdsBgColor,fadeIN:myEpicGameAdsFadeIn,fadeFrames:myEpicGameAdsFadeFrames};
var oEpicContent:Object;
var oEpicDisplay:DisplayObject;
var epicGameAds:Loader; // holds reference to loader, used to unload ad later

Security.allowDomain("http://www.epicgameads.com","http://epicgameads.com");
  if(Security.sandboxType != "remote")
  {
  trace("Notice:Running EpicGameAds InGameAd in local security sandbox (domain)");
  trace("Ads may not be visible when in local sandbox");
  trace("Publish the SWF and run it in a REMOTE security sandbox (from a internet URL)");
  }

var i:int = this.numChildren;
while( i -- )
{
    this.removeChildAt( i );
}
epicInit();

function epicInit():void
{
var swfUrl:String="http://www.epicgameads.com/epicgameads-as3-v2.swf";
var request:URLRequest=new URLRequest(swfUrl);
var loader:Loader=new Loader();
epicGameAds=loader;
loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onEpicConIOError);
loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, epicLoadProgress,false,0,true);
loader.contentLoaderInfo.addEventListener(Event.COMPLETE, epicLoadComplete,false,0,true);
loader.load(request);
oEpicDisplay=this.addChild(loader);
}

function unloadEpicGameAds()
{
epicGameAds.unloadAndStop();
}

function onEpicConIOError(e:IOErrorEvent)
{
trace(e.text);
}

function epicLoadProgress(e:ProgressEvent):void
{
var percentLoaded:Number=e.bytesLoaded/e.bytesTotal;
percentLoaded=Math.round(percentLoaded*100);
}

function epicLoadComplete(e:Event):void
{
oEpicDisplay.x=epicXPos;
oEpicDisplay.y=epicYPos;
oEpicContent=Object(e.target.content);
oEpicContent.adServerConnect(oEpicUserInfo);
}

function setRegPoint(obj:DisplayObjectContainer, newX:Number, newY:Number):void {
	var bounds:Rectangle = obj.getBounds(obj.parent);
	var currentRegX:Number = obj.x - bounds.left;
	var currentRegY:Number = obj.y - bounds.top;

	var xOffset:Number = newX - currentRegX;
	var yOffset:Number = newY - currentRegY;
	obj.x += xOffset;
	obj.y += yOffset;

	for(var i:int = 0; i < obj.numChildren; i++) {
		obj.getChildAt(i).x -= xOffset;
		obj.getChildAt(i).y -= yOffset;
	}
}
stop();
*/
    
    private static var myEpicGameAdsPublisherCode : String = "3run02qoxt";
    private static var myEpicGameAdsGameID : String = "1";
    private static var myEpicGameAdsBgSolid : Int = 0;  // 1 = enabled (show the ad background filled with color), 0 = disabled  
    private static var myEpicGameAdsBgColor : Int = 0x000000;  // background hex RGB color if background is solid  
    private static var myEpicGameAdsFadeIn : Int = 1;  // 1 = enabled, 2 = disabled (no fade in)  
    private static var myEpicGameAdsFadeFrames : Int = 24;  // how many frames in fadeIn default 24  
    private static var epicGameAds : Loader;  // holds reference to loader, used to unload ad later  
    private static var oEpicContent : Dynamic;
    private static var oEpicDisplay : DisplayObject;
    private static var oEpicUserInfo : Dynamic;
    
    public static function ShowEpicGameAd() : Void
    {
        AddIntroScreenAndSetUpButtons();
        
        var sEpicRefURL : String = LicDef.GetStage().stage.loaderInfo.loaderURL;
        oEpicUserInfo = {
                    publisherCode : myEpicGameAdsPublisherCode,
                    gameId : myEpicGameAdsGameID,
                    refURL : sEpicRefURL,
                    bgSolid : myEpicGameAdsBgSolid,
                    bgColor : myEpicGameAdsBgColor,
                    fadeIN : myEpicGameAdsFadeIn,
                    fadeFrames : myEpicGameAdsFadeFrames
                };
        
        Security.allowDomain("http://www.epicgameads.com", "http://epicgameads.com");
        if (Security.sandboxType != "remote")
        {
            trace("Notice:Running EpicGameAds InGameAd in local security sandbox (domain)");
            trace("Ads may not be visible when in local sandbox");
            trace("Publish the SWF and run it in a REMOTE security sandbox (from a internet URL)");
        }
        
        var swfUrl : String = "http://www.epicgameads.com/epicgameads-as3-v2.swf";
        var request : URLRequest = new URLRequest(swfUrl);
        var loader : Loader = new Loader();
        epicGameAds = loader;
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onEpicConIOError);
        loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, epicLoadProgress, false, 0, true);
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, epicLoadComplete, false, 0, true);
        loader.load(request);
        
        oEpicDisplay = intro.adBox.addChild(loader);
        
        cpmStarLoaderCounter = 0;
        LicDef.GetStage().addEventListener(Event.ENTER_FRAME, CPMStarLoadingEventCallback);
        cpmStarTimer = new Timer(1000);
        cpmStarTimer.addEventListener(TimerEvent.TIMER, CPMStarTimerCallback);
        cpmStarTimer.start();
    }
    
    private static function unloadEpicGameAds()
    {
        epicGameAds.unloadAndStop();
    }
    
    private static function onEpicConIOError(e : IOErrorEvent)
    {
        trace(e.text);
    }
    
    private static function epicLoadProgress(e : ProgressEvent) : Void
    {
        var percentLoaded : Float = e.bytesLoaded / e.bytesTotal;
        percentLoaded = Math.round(percentLoaded * 100);
    }
    
    private static function epicLoadComplete(e : Event) : Void
    {
        oEpicDisplay.x = 0;  // epicXPos;  
        oEpicDisplay.y = 0;  // epicYPos;  
        oEpicContent = cast((e.target.content), Object);
        oEpicContent.adServerConnect(oEpicUserInfo);
    }
    
    
    
    public static function ShowCPMStarAd() : Void
    {
        AddIntroScreenAndSetUpButtons();
        
        var id : String;
        var num : Int = LicDef.CPMStarContentSpotIDs.length;
        if (num == 1)
        {
            id = LicDef.CPMStarContentSpotIDs[0];
        }
        if (num == 2)
        {
            var r : Int = RandBetweenInt(0, 1000);
            if (r < 500)
            {
                id = LicDef.CPMStarContentSpotIDs[0];
            }
            else
            {
                id = LicDef.CPMStarContentSpotIDs[1];
            }
        }
        ad = new cPMStar.AdLoader(id);
        intro.adBox.addChild(ad);
        
        
        cpmStarLoadTimer = 0;
        cpmStarLoaderCounter = 0;
        LicDef.GetStage().addEventListener(Event.ENTER_FRAME, CPMStarLoadingEventCallback);
        cpmStarTimer = new Timer(1000);
        cpmStarTimer.addEventListener(TimerEvent.TIMER, CPMStarTimerCallback);
        cpmStarTimer.start();
    }
    
    
    public static function ShowMochiAd_Preload()  // but preload the game please  
    {
        LicDef.GetStage().stop();
        
        AddIntroScreenAndSetUpButtons();
        
        cpmStarLoadTimer = 0;
        cpmStarLoaderCounter = 1;
        
        ShowMochiAd();
    }
    
    
    private static function ShowMochiAd_Preload_LoadingEventCallback(event : Event)
    {
        var bytestotal = LicDef.GetStage().stage.loaderInfo.bytesTotal;
        var bytesloaded = LicDef.GetStage().stage.loaderInfo.bytesLoaded;
        
        var val : Float = 1 / bytestotal * bytesloaded;
        cast((val), RenderLoaderBar);
        if (bytesloaded >= bytestotal)
        {
            LicDef.GetStage().removeEventListener(Event.ENTER_FRAME, ShowMochiAd_Preload_LoadingEventCallback);
            LicDef.GetStage().play();
            if (showAdFinishedCallback != null)
            {
                showAdFinishedCallback();
            }
        }
    }
    
    public static function ShowMochiAd()
    {
        MochiAd.showPreGameAd({
                    clip : LicDef.GetStage(),
                    id : LicDef.MochiAdID,
                    res : LicDef.MochiAdRes,
                    ad_finished : MochiAdFinished
                });
    }
    
    public static function MochiAdFinished()
    {
        LicDef.GetStage().removeChild(intro);
        intro = null;
        if (showAdFinishedCallback != null)
        {
            showAdFinishedCallback();
        }
        LicDef.GetStage().play();
    }
    
    
    public static function ShowNoAd() : Void  // but preload the game please  
    {
        AddIntroScreenAndSetUpButtons();
        
        
        intro.adBox.visible = false;
        
        cpmStarLoadTimer = 0;
        cpmStarLoaderCounter = 1;
        LicDef.GetStage().addEventListener(Event.ENTER_FRAME, CPMStarLoadingEventCallback);
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
                trace("Lic: MainLogo Error. Null child found. (not a button?)");
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
                trace("Lic: MainLogo Error. Null child found. (not a button?)");
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
                trace("Lic: MainLogo Error. Can't find logo: " + sku.mainLogoName);
            }
        }
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
    
    public static function DoLink(linkStr : String)
    {
        var s : String = linkStr + LicDef.referralString;
        flash.Lib.getURL(new URLRequest(s), "_blank");
    }
    
    public static function Link_TurboNuke(e : MouseEvent, buttonString : String = "intro")
    {
        flash.Lib.getURL(new URLRequest("http://www.turbonuke.com?gamereferral=" + LicDef.referralName), "_blank");
    }
    
    
    public static function AddButton(btn : SimpleButton, clickCallback : Function)
    {
        if (btn == null)
        {
            trace("add button button = null");
        }
        if (clickCallback == null)
        {
            trace("add button clickCallback = null");
        }
        btn.addEventListener(MouseEvent.CLICK, clickCallback, false, 0, true);
    }
    
    private static function buttonSkipCPMStarAdPressed(e : MouseEvent) : Void
    {
        if (ad != null)
        {
            intro.adBox.removeChild(ad);
        }
        
        LicDef.GetStage().removeChild(intro);
        intro = null;
        
        if (showAdFinishedCallback != null)
        {
            showAdFinishedCallback();
        }
    }
    
    
    
    
    public static function IsAtKiba() : Bool
    {
        var domain : String = LicDef.GetDomain();
        if (domain == "kaisergames.de")
        {
            return true;
        }
        return false;
    }

    public function new()
    {
    }
}

