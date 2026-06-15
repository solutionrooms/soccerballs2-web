package kizi;

import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.system.Security;
import flash.utils.Timer;

/**
	 * ...
	 * @author
	 */
class KiziAPI
{
    public static var apiLoaded(get, never) : Bool;
    public static var showingOverlay(get, never) : Bool;

    public static inline var apiVersion : Float = 0.131;
    public static var ApiSwfUrl : String = "http://kizi.com/api/ooplaAPI.swf";
    public static var ApiGateway : String;
    public static var api : Dynamic;
    public static var gameState : KiziGameState;
    public static var vault : KiziVault;
    public static var apiLoader : Loader;
    public static var loaderTimeout : Timer;
    public static var authtoken : String;
    public static var gid : String;
    public static var _stage : DisplayObjectContainer;
    public static var loaderInfo : LoaderInfo;
    
    /**
		 * Manually sets the API context to a specific game/user. Useful while developing a game.
		 * @param	gameID - A unique game id as provided to you by Kizi
		 * @param	userID - Your development mode user, as provided to you by Kizi
		 */
    public static function setContext(gameID : String, userAuthToken : String) : Void
    {
        authtoken = userAuthToken;
        gid = gameID;
    }
    
    public static function connect(stage : Stage, loaderInfo_ : LoaderInfo, logLevel : Int = 0) : Void
    {
        Security.allowDomain("*");
        Security.allowInsecureDomain("*");
        
        loaderInfo = loaderInfo_;
        
        
        if (loaderInfo.parameters.apiSwfUrl != null)
        {
            ApiSwfUrl = loaderInfo.parameters.apiSwfUrl;
        }
        
        api = null;
        _stage = stage;
        gameState = new KiziGameState();
        vault = new KiziVault();
        KiziLogger.logLevel = logLevel;
        
        
        if (loaderInfo.url != null && loaderInfo.url.slice(0, 4) == "file")
        {
            KiziLogger.debug("Running in development mode, adding a cache busting string to the API swf");
            KiziAPI.ApiSwfUrl += "?" + Math.random();
        }
        
        KiziLogger.debug("API client version:", apiVersion);
        KiziLogger.debug("API load started from", ApiSwfUrl);
        
        var request : URLRequest = new URLRequest(ApiSwfUrl);
        apiLoader = new Loader();
        apiLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
        apiLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        apiLoader.load(request);
        
        loaderTimeout = new Timer(20000, 1);
        loaderTimeout.addEventListener(TimerEvent.TIMER, loadTimedOut);
        loaderTimeout.start();
    }
    
    public static function loadTimedOut(e : TimerEvent) : Void
    {
        KiziLogger.error("API loading has timed out");
        (untyped apiLoader).close();
    }
    
    public static function loadComplete(e : Event) : Void
    {
        loaderTimeout.stop();
        KiziLogger.debug("API swf loaded succesfully");
        api = e.target.content;
        KiziLogger.debug("API initialiation started, loader info " + loaderInfo.url);
        api.init(_stage, loaderInfo, KiziLogger.logLevel, apiVersion, authtoken, gid, ApiGateway, loaderInfo.url);
    }
    
    public static function get_apiLoaded() : Bool
    {
        return (api != null && api.apiReady);
    }
    
    public static function get_showingOverlay() : Bool
    {
        return (api != null && api.showingOverlay);
    }
    
    public static function errorHandler(e : Event) : Void
    {
        KiziLogger.error("Error caught:", e);
    }
    
    public static function getCoinIcon() : MovieClip
    {
        if (KiziAPI.apiLoaded)
        {
            return KiziAPI.api.getCoinIcon();
        }
        else
        {
            return new MovieClip();
        }
    }
    
    public static function showGetCoinsDialog() : Void
    {
        if (KiziAPI.apiLoaded)
        {
            KiziAPI.api.showGetCoinsDialog();
        }
    }
    
    public static function reloadPage() : Void
    {
        if (KiziAPI.apiLoaded)
        {
            KiziAPI.api.reloadPage();
        }
    }

    public function new()
    {
    }
}

