import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import flash.geom.Rectangle;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import kizi.KiziAPI;
import kizi.KiziLogger;
import licPackage.AdHolder;
import licPackage.LicAds;
import licPackage.LicDef;

/**
	 * ...
	 * @author LongAnimals
	 */
class Preloader extends MovieClip
{
    
    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, added_to_stage, false, 0, true);
    }
    
    private function added_to_stage(e : Event)
    {
        removeEventListener(Event.ADDED_TO_STAGE, added_to_stage);
        
        LicDef.InitFromPreloader(this);
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KIZI)
        {
            addEventListener(Event.ENTER_FRAME, updateProgress_Kizi);
            
            
            if (ExternalInterface.available)
            {
                ExternalInterface.addCallback("startGame", startGame_Kizi);
            }
        }
        
        
        if (stage != null)
        {
            if (false)
            {
                stage.align = StageAlign.TOP_LEFT;
            }
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.displayState = StageDisplayState.NORMAL;
            Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
            Multitouch.inputMode = MultitouchInputMode.NONE;
            stage.quality = StageQuality.HIGH;
            
            ScreenSize.Calculate(stage);
            if (false)
            {
                Defs.fps = 30;
            }
        }
        
        if (false)
        
        //false){
            
            {
                LicDef.InitFromPreloader(this);
                LicAdsShowAdCB();
            }
        }
        else
        {
            LicDef.InitFromPreloader(this);
            AdHolder.InitOnce(AdHolderInitOnceCB);
        }
    }
    
    private function AdHolderInitOnceCB()
    {
        LicAds.ShowAd(LicAdsShowAdCB);
    }
    private function LicAdsShowAdCB()
    {
        addEventListener(Event.ENTER_FRAME, checkFrame);
        loaderInfo.addEventListener(ProgressEvent.PROGRESS, progress);
        loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioError);
    }
    
    private function ioError(e : IOErrorEvent) : Void
    {
    }
    
    private function progress(e : ProgressEvent) : Void
    {
    }
    
    private function checkFrame(e : Event) : Void
    {
        if (currentFrame == totalFrames)
        {
            stop();
            loadingFinished1();
        }
    }
    
    private function loadingFinished1() : Void
    {
        removeEventListener(Event.ENTER_FRAME, checkFrame);
        loaderInfo.removeEventListener(ProgressEvent.PROGRESS, progress);
        loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioError);
        loadingFinished2();
    }
    private function loadingFinished2() : Void
    {
        startup();
    }
    
    private function startup() : Void
    {
        var mainClass : Class<Dynamic> = Type.getClass(Type.resolveClass("Main"));
        addChild(try cast(Type.createInstance(mainClass, []), DisplayObject) catch(e:Dynamic) null);
    }
    
    private function startGame_Kizi() : Void
    {
        KiziStuff.InitFromPreloader();
        
        var mainClass : Class<Dynamic> = Type.getClass(Type.resolveClass("Main"));
        addChildAt(try cast(Type.createInstance(mainClass, []), DisplayObject) catch(e:Dynamic) null, 0);
    }
    
    private function updateProgress_Kizi(e : Event) : Void
    {
        var total : Float = stage.loaderInfo.bytesTotal;
        var loaded : Float = stage.loaderInfo.bytesLoaded;
        var pct : Int = as3hx.Compat.parseInt(loaded / total * 100);
        var apiLoaded : Bool = KiziAPI.apiLoaded;
        
        if (apiLoaded)
        {
            if (ExternalInterface.available)
            {
                ExternalInterface.call("apiLoaded");
            }
        }
        
        if (ExternalInterface.available)
        {
            ExternalInterface.call("setPreloaderProgress", pct);
        }
        else if (pct == 100 && apiLoaded)
        {
            as3hx.Compat.setTimeout(startGame_Kizi, 1000);
        }
        
        if (pct == 100 && apiLoaded)
        {
            removeEventListener(Event.ENTER_FRAME, updateProgress_Kizi);
        }
    }
}

