package licPackage;

import flash.errors.Error;
import haxe.Constraints.Function;
import cPMStar.*;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.AsyncErrorEvent;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.NetStatusEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;
import flash.utils.ByteArray;
import flash.xml.XMLDocument;
import licPackage.LicDef;
import mx.utils.LoaderUtil;

/**
	 * ...
	 * @author ...
	 */
class AdHolder
{
    
    private static var items : Array<AdItem> = null;
    private static var pread_items : Array<AdItem> = null;
    
    public static var adIndex : Int = 0;
    private static var currentAd : MovieClip;
    private static var currentPreAd : MovieClip;
    
    private static var AD_URL : String = "http://ads.turbonuke.com/Ads_SoccerBalls2.php";
    private static var prequelLink : String = "http://www.kongregate.com/games/LongAnimals/bubble-guinea-pop" + LicDef.referralString;
    
    public function new()
    {
    }
    
    public static function IsLoadedPreAdAvailable() : Bool
    {
        if (pread_items.length == 0)
        {
            return false;
        }
        if (pread_items[0].urlLoaded == false)
        {
            return false;
        }
        return true;
    }
    
    private static function MakeIntersitialItemAndTestAdFilters() : AdItem
    {
        var ad : AdItem = new AdItem("Intersitial", "intersitial", "", "");
        
        if (LicDef.GetCurrentSku().adtype != LicDef.ADTYPE_CPMSTAR)
        {
            ad = new AdItem("OtherGames", "othergames", "", "");
        }
        
        if (LicAds.FilterAdForSites())
        {
            ad = new AdItem("OtherGames", "othergames", "", "");
        }
        return ad;
    }
    
    
    
    private static var initOnceCompleteCallback : Function;
    public static function InitOnce(_callback : Function)
    {
        initOnceCompleteCallback = _callback;
        items = new Array<AdItem>();
        pread_items = new Array<AdItem>();
        
        adIndex = -1;
        currentAd = null;
        currentPreAd = null;
        
        if (LicDef.IsAtKongregate())
        {
            items.push(new AdItem("OtherGames", "othergames", "", ""));
            items.push(new AdItem("OtherGames", "othergames", "", ""));
            items.push(new AdItem("OtherGames", "othergames", "", ""));
            DoCompletedCallback();
        }
        else if (LicAds.IsAtKiba())
        {
            items.push(new AdItem("OtherGamesText", "othergamestext", "", ""));
            DoCompletedCallback();
        }
        else
        {
            items.push(new AdItem("OtherGames", "othergames", "", ""));
            items.push(new AdItem("OtherGames", "othergames", "", ""));
            items.push(new AdItem("OtherGamesText", "othergamestext", "", ""));
            
            if (LoadCustomAdXML() == false)
            {
                DoCompletedCallback();
            }
        }
    }
    
    private static var urlXMLLoader : URLLoader;
    private static var urlLoader : Loader;
    private static var loadList : Array<Dynamic>;
    private static var loadIndex : Int;
    
    private static function GetAdItemByName(_name : String) : AdItem
    {
        for (ad in items)
        {
            if (ad.name == _name)
            {
                return ad;
            }
        }
        return null;
    }
    
    private static function AddLoadedAdsFromXML(xml : FastXML)
    {
        loadList = new Array<Dynamic>();
        var adItem : AdItem;
        
        items = new Array<AdItem>();
        
        var num : Int = xml.nodes.ad.length();
        for (i in 0...num)
        {
            var x : FastXML = xml.nodes.ad.get(i);
            var name : String = XmlHelper.GetAttrString(x.att.id, "");
            var active : Bool = true;
            
            
            
            if (name == "OtherGames")
            {
                items.push(new AdItem("OtherGames", "othergames", "", ""));
            }
            else if (name == "OtherGames")
            {
                items.push(new AdItem("OtherGamesText", "othergamestext", "", ""));
            }
            else if (name == "Intersitial")
            {
                items.push(MakeIntersitialItemAndTestAdFilters());
            }
            else if (name == "Prequel")
            {
                items.push(new AdItem("Prequel", "prequel", "http://www.kongregate.com/games/LongAnimals/bubble-guinea-pop", ""));
            }
            else if (name == "CycloRacers")
            {
                items.push(new AdItem("CycloRacers", "cycloracers", "http://www.turbonuke.com/cyclomaniacsracers.php", ""));
            }
            else
            {
                var swfurl : String = XmlHelper.GetAttrString(x.att.swfurl, "");
                var clickurl : String = XmlHelper.GetAttrString(x.att.clickurl, "");
                var fullscreen : Bool = XmlHelper.GetAttrBoolean(x.att.fullscreen, false);
                
                if (swfurl == "")
                {
                }
                else
                {
                    adItem = new AdItem(name, "othergames", clickurl, swfurl);
                    adItem.url = "";  // overwritten when the swf is loaded  
                    items.push(adItem);
                    loadList.push(adItem);
                }
            }
        }
        
        var num : Int = xml.nodes.pread.length();
        for (i in 0...num)
        {
            var x : FastXML = xml.nodes.pread.get(i);
            var name : String = XmlHelper.GetAttrString(x.att.id, "");
            var active : Bool = true;
            
            var swfurl : String = XmlHelper.GetAttrString(x.att.swfurl, "");
            var clickurl : String = XmlHelper.GetAttrString(x.att.clickurl, "");
            var fullscreen : Bool = XmlHelper.GetAttrBoolean(x.att.fullscreen, false);
            
            if (swfurl == "")
            {
            }
            else
            {
                adItem = new AdItem(name, "othergames", clickurl, swfurl);
                adItem.fullScreen = fullscreen;
                adItem.url = "";  // overwritten when the swf is loaded  
                pread_items.push(adItem);
                loadList.push(adItem);
            }
        }
        
        
        if (loadList != null && loadList.length >= 1)
        {
            LoadNextCustomAd();
        }
        else
        {
            DoCompletedCallback();
        }
    }
    
    public static function LoadCustomAdXML() : Bool
    {
        if (LicDef.IsRemoteAdLoadingAllowed() == false)
        {
            return false;
        }
        if (LicAds.ShouldTryLoadAdXML() == false)
        {
            return false;
        }
        
        var url : String = AD_URL;
        var request : URLRequest = new URLRequest(url);
        try
        {
            urlXMLLoader = new URLLoader();
            urlXMLLoader.addEventListener(Event.COMPLETE, LoadCustomAdXMLa_Complete);
            urlXMLLoader.addEventListener(ErrorEvent.ERROR, LoadCustomAdXMLa_Error);
            urlXMLLoader.addEventListener(AsyncErrorEvent.ASYNC_ERROR, CustomAdXML_onError1);
            urlXMLLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, CustomAdXML_onError2);
            urlXMLLoader.addEventListener(IOErrorEvent.IO_ERROR, CustomAdXML_onError3);
            urlXMLLoader.load(request);
        }
        catch (e : ErrorEvent)
        {
            trace("caught error " + e);
            return false;
        }
        return true;
    }
    
    private static function LoadCustomAdXMLa_Error(e : Error)
    {
        trace("LoadCustomAdXMLa_Error " + e.message);
        DoCompletedCallback();
    }
    
    private static function LoadCustomAdXMLa_Complete(e : Event)
    {
        var s : String = urlXMLLoader.data;
        FastXML.ignoreWhitespace = true;
        
        var xml : FastXML = null;
        
        try
        {
            xml = new FastXML(s);
        }
        catch (e : Error)
        {
            trace("XML error: " + e.message);
            xml = null;
        }
        
        if (xml != null)
        {
            cast((xml), AddLoadedAdsFromXML);
        }
        else
        {
            DoCompletedCallback();
        }
        
        
        urlXMLLoader.removeEventListener(Event.COMPLETE, LoadCustomAdXMLa_Complete);
        urlXMLLoader.removeEventListener(ErrorEvent.ERROR, LoadCustomAdXMLa_Error);
        urlXMLLoader.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, CustomAdXML_onError1);
        urlXMLLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, CustomAdXML_onError2);
        urlXMLLoader.removeEventListener(IOErrorEvent.IO_ERROR, CustomAdXML_onError3);
        urlXMLLoader = null;
    }
    
    private static function DoCompletedCallback()
    {
        var fn : Function = initOnceCompleteCallback;
        initOnceCompleteCallback = null;
        if (fn != null)
        {
            fn();
        }
    }
    
    private static function CustomAdXML_onError(e : Error)
    {
        trace("ACustom Ad XML Loading Error: " + e.message);
        DoCompletedCallback();
    }
    private static function CustomAdXML_onError1(e : AsyncErrorEvent)
    {
        trace("BCustom Ad XML Loading Error: " + e.error.message);
        DoCompletedCallback();
    }
    private static function CustomAdXML_onError2(e : SecurityErrorEvent)
    {
        trace("CCustom Ad XML Loading Error: " + e);
        DoCompletedCallback();
    }
    private static function CustomAdXML_onError3(e : IOErrorEvent)
    {
        trace("DCustom Ad XML Loading Error: " + e.text);
        DoCompletedCallback();
    }
    
    
    private static function IsAdADuplicate(loadIndex : Int) : AdItem
    {
        if (loadIndex == 0)
        {
            return null;
        }
        var adItem : AdItem = loadList[loadIndex];
        if (adItem == null)
        {
            return null;
        }
        
        for (i in 0...loadIndex)
        {
            var adItem1 : AdItem = loadList[i];
            if (adItem.CompareSwfUrlWith(adItem1))
            {
                return adItem1;
            }
        }
        return null;
    }
    
    public static function LoadNextCustomAd()
    {
        var adItem : AdItem = loadList[loadIndex];
        if (adItem != null)
        {
            if (cast((loadIndex), IsAdADuplicate) != null)
            {
                var adItem1 : AdItem = cast((loadIndex), IsAdADuplicate);
                adItem.urlLoaded = true;
                trace("ad is duplicate: " + adItem.swfurl);
                adItem.type = "custom";
                adItem.url = adItem.original_url;
                adItem.loader = adItem1.loader;
                
                loadIndex++;
                if (loadIndex < loadList.length)
                {
                    LoadNextCustomAd();
                }
                else
                {
                    DoCompletedCallback();
                }
            }
            else if (adItem.swfurl != "")
            {
                var loaderContext : LoaderContext = new LoaderContext();
                Security.allowDomain("*");
                Security.allowInsecureDomain("*");
                loaderContext.checkPolicyFile = true;
                loaderContext.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
                
                adItem.loader = new Loader();
                adItem.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, LoadNextCustomAd_Complete);
                adItem.loader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, onError);
                adItem.loader.contentLoaderInfo.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
                adItem.loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
                adItem.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
                var url : String = adItem.swfurl;
                adItem.loader.load(new URLRequest(url), loaderContext);
                
                trace("loading ad " + url);
            }
        }
    }
    private static function LoadNextCustomAd_Complete(e : Event)
    {
        var adItem : AdItem = loadList[loadIndex];
        
        adItem.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, LoadNextCustomAd_Complete);
        adItem.loader.contentLoaderInfo.removeEventListener(ErrorEvent.ERROR, onError);
        adItem.loader.contentLoaderInfo.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
        adItem.loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        adItem.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        
        adItem.urlLoaded = true;
        trace("ad loaded: " + adItem.swfurl);
        
        
        adItem.type = "custom";
        adItem.url = adItem.original_url;
        
        loadIndex++;
        if (loadIndex < loadList.length)
        {
            LoadNextCustomAd();
        }
        else
        {
            DoCompletedCallback();
        }
    }
    
    
    private static function onError(e : IOErrorEvent)
    {
        DoCompletedCallback();
    }
    
    
    public static function RemoveAd(parent : MovieClip)
    {
        if (currentAd != null)
        {
            var adItem : AdItem = items[adIndex];
            if (adItem.type == "othergames")
            {
                parent.removeChild(currentAd);
            }
            else if (adItem.type == "othergamestext")
            {
                parent.removeChild(currentAd);
            }
            else if (adItem.type == "intersitial")
            {
                RemoveIntersitialMC();
                parent.removeChild(currentAd);
            }
            else if (adItem.type == "custom")
            {
                if (adItem.urlLoaded == false)
                {
                    parent.removeChild(currentAd);
                }
                else
                {
                    cast((parent), RemoveCustomMC);
                }
            }
            else if (adItem.type == "cycloracers")
            {
                parent.removeChild(currentAd);
            }
            else if (adItem.type == "prequel")
            {
                parent.removeChild(currentAd);
            }
            else if (adItem.type == "blank")
            {
                parent.removeChild(currentAd);
            }
            
            if (adItem.url != "")
            {
                currentAd.removeEventListener(MouseEvent.CLICK, AdClicked);
            }
            
            currentAd = null;
        }
    }
    
    
    private static function getVisibleBounds(source : DisplayObject) : Rectangle
    {
        var matrix : Matrix = new Matrix();
        matrix.tx = -source.getBounds(null).x;
        matrix.ty = -source.getBounds(null).y;
        
        var data : BitmapData = new BitmapData(source.width, source.height, true, 0x00000000);
        data.draw(source, matrix);
        var bounds : Rectangle = data.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);
        data.dispose();
        return bounds;
    }
    
    
    public static function AddAd(parent : MovieClip)
    {
        currentAd = GetAd();
        if (currentAd != null)
        {
            parent.addChild(currentAd);
        }
    }
    public static function GetAd() : MovieClip
    {
        var mc : MovieClip;
        
        if (items.length == 0)
        
        // final failsafe{
            
            {
                items.push(new AdItem("OtherGames", "othergames", "", ""));
            }
        }
        
        adIndex++;
        if (adIndex >= items.length)
        {
            adIndex = 0;
        }
        
        var adItem : AdItem = items[adIndex];
        
        if (adItem.type == "othergames")
        {
            mc = OtherGames.GetOtherGamesMC();
        }
        if (adItem.type == "othergamestext")
        {
            mc = OtherGames.GetOtherGamesMC(4, 2);
        }
        if (adItem.type == "intersitial")
        {
            mc = GetIntersitialMC();
        }
        if (adItem.type == "cycloracers")
        {
            mc = GetCycloRacersMC();
        }
        if (adItem.type == "prequel")
        {
            mc = GetPrequelMC();
        }
        if (adItem.type == "custom")
        {
            mc = GetCustomMC();
        }
        if (adItem.type == "blank")
        {
            mc = GetBlankMC();
        }
        
        if (adItem.url != "")
        {
            mc.addEventListener(MouseEvent.CLICK, AdClicked);
            mc.buttonMode = true;
            mc.useHandCursor = true;
        }
        
        return mc;
    }
    
    public static function AdClicked(e : MouseEvent)
    {
        var adItem : AdItem = items[adIndex];
        if (adItem != null)
        {
            if (adItem.url != "")
            {
                flash.Lib.getURL(new URLRequest(adItem.url), "_blank");
            }
        }
    }
    
    public static function PreAdClicked(e : MouseEvent)
    {
        var adItem : AdItem = pread_items[0];
        if (adItem != null)
        {
            if (adItem.url != "")
            {
                flash.Lib.getURL(new URLRequest(adItem.url), "_blank");
            }
        }
    }
    
    
    private static function GetPrequelMC() : MovieClip
    {
        var classRef_PrequelAd : Class<Dynamic> = Type.getClass(Type.resolveClass("PrequelAd"));
        var mc : MovieClip = try cast(Type.createInstance(classRef_PrequelAd, []), MovieClip) catch(e:Dynamic) null;
        return mc;
    }
    private static function GetCycloRacersMC() : MovieClip
    {
        var mc : MovieClip = new MovieClip();  // ad_banner_cycloracers();  
        return mc;
    }
    private static function GetBlankMC() : MovieClip
    {
        return new MovieClip();
    }
    
    
    
    
    private static function RemoveCustomMC(parent : MovieClip)
    {
        parent.removeChild(currentAd);
    }
    private static function GetCustomMC() : MovieClip
    {
        var adItem : AdItem = items[adIndex];
        if (adItem.urlLoaded == false)
        {
            return GetBlankMC();
        }
        
        var mc : MovieClip = try cast(adItem.loader.content, MovieClip) catch(e:Dynamic) null;
        return mc;
    }
    
    private static function GetPreAdItem() : AdItem
    {
        if (pread_items == null)
        {
            return null;
        }
        if (pread_items.length == 0)
        {
            return null;
        }
        return pread_items[0];
    }
    private static function GetPreAdCustomMC(_parentMC : MovieClip = null) : MovieClip
    {
        var adItem : AdItem = pread_items[0];
        if (adItem.urlLoaded == false)
        {
            return GetBlankMC();
        }
        
        var mc : MovieClip = try cast(adItem.loader.content, MovieClip) catch(e:Dynamic) null;
        
        var fullScreen : Bool = adItem.fullScreen;
        
        if (fullScreen && (_parentMC != null))
        {
            mc.x = -_parentMC.x;
            mc.y = -_parentMC.y;
            
            var yGap : Int = 45;
            
            var sw : Float = Defs.displayarea_w;
            var sh : Float = Defs.displayarea_h - (yGap * 2);
            
            var adw : Float = 300;
            var adh : Float = 250;
            
            
            var dx : Float = sw / adw;
            var dy : Float = sh / adh;
            
            var r : Rectangle = mc.getBounds(null);
            
            
            if (dx > dy)
            {
                mc.scaleX = dy;
                mc.scaleY = dy;
                
                mc.x += (sw - (adw * dy)) * 0.5;
                mc.y += yGap;
            }
            else
            {
                mc.scaleX = dx;
                mc.scaleY = dx;
            }
        }
        return mc;
    }
    
    
    private static function RemoveIntersitialMC()
    {
        if (ad != null)
        {
            currentAd.removeChild(ad);
        }
        ad = null;
    }
    
    private static function GetIntersitialMC() : MovieClip
    {
        return GetIntersitialMC_CPMStar();
    }
    
    
    private static function GetIntersitialMC_CPMStar() : MovieClip
    {
        var clip : MovieClip;
        var id : String;
        var num : Int = LicDef.CPMStarIntersitialsSpotIDs.length;
        if (num == 1)
        {
            id = LicDef.CPMStarIntersitialsSpotIDs[0];
        }
        if (num == 2)
        {
            var r : Int = RandBetweenInt(0, 1000);
            if (r < 500)
            {
                id = LicDef.CPMStarIntersitialsSpotIDs[0];
            }
            else
            {
                id = LicDef.CPMStarIntersitialsSpotIDs[1];
            }
        }
        
        clip = new MovieClip();
        
        ad = new cPMStar.AdLoader(id);
        clip.addChild(ad);
        ad.x = 0;
        ad.y = 0;
        trace("showing intersitial ");
        return clip;
    }
    
    private static var ad : DisplayObject;
    
    public static function RandBetweenInt(r0 : Int, r1 : Int) : Int
    {
        var r : Int = as3hx.Compat.parseInt(Math.random() * ((r1 - r0) + 1));
        r += r0;
        return r;
    }
    
    public static function XML_GetAttrString(x : Dynamic, defaultvalue : String = "") : String
    {
        var val : String = defaultvalue;
        if (x != null)
        {
            val = Std.string(x);
        }
        return val;
    }
    public static function XML_GetAttrNumber(x : Dynamic, defaultvalue : Float = 0) : Float
    {
        var val : Float = defaultvalue;
        if (x != null)
        {
            var s : String = Std.string(x);
            val = as3hx.Compat.parseFloat(x);
        }
        return val;
    }
    
    public static function XML_GetAttrInt(x : Dynamic, defaultvalue : Int = 0) : Int
    {
        var val : Int = defaultvalue;
        if (x != null)
        {
            val = as3hx.Compat.parseInt(x);
        }
        return val;
    }
    public static function XML_GetAttrBoolean(x : Dynamic, defaultvalue : Bool = false) : Bool
    {
        var val : Bool = defaultvalue;
        if (x != null && x != null)
        {
            val = false;
            var s : String = Std.string(x);
            s = s.toLowerCase();
            if (x == "true")
            {
                val = true;
            }
        }
        return val;
    }
}

