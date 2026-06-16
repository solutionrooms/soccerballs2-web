/**
* MochiServices
* Connection class for all MochiAds Remote Services
* @author Mochi Media
* @version 3.0
*/

package mochi.as3;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.geom.Rectangle;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.display.MovieClip;
import flash.events.StatusEvent;
import flash.events.TimerEvent;
import flash.system.Security;
import flash.system.Capabilities;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.net.LocalConnection;
import flash.utils.Timer;
import flash.utils.ByteArray;
import flash.utils.Endian;

class MochiServices
{
    public static var id(get, never) : String;
    public static var clip(get, never) : Dynamic;
    public static var childClip(get, never) : Dynamic;
    public static var comChannelName(never, set) : String;
    public static var connected(get, never) : Bool;

    
    public static var _id : String;
    public static var _container : Dynamic;
    public static var _clip : MovieClip;
    public static var _loader : Loader;
    public static var _timer : Timer;
    
    public static var _servicesURL : String = "http://www.mochiads.com/static/lib/services/services.swf";
    
    public static var _swfVersion : String;
    
    public static var _listenChannel : LocalConnection;
    public static var _listenChannelName : String = "__ms_";
    public static var _sendChannel : LocalConnection;
    public static var _sendChannelName : String;
    
    public static var _connecting : Bool = false;
    public static var _connected : Bool = false;
    
    public static var netup : Bool = true;
    public static var netupAttempted : Bool = false;
    
    public static var onError : Dynamic;
    
    public static var widget : Bool = false;
    
    
    public static function get_id() : String
    {
        return _id;
    }
    
    
    public static function get_clip() : Dynamic
    {
        return _container;
    }
    
    
    public static function get_childClip() : Dynamic
    {
        return _clip;
    }
    
    
    
    public static function getVersion() : String
    {
        return "3.0";
    }
    
    
    
    public static function allowDomains(server : String) : String
    {
        if (flash.system.Security.sandboxType != "application")
        {
            flash.system.Security.allowDomain("*");
            flash.system.Security.allowInsecureDomain("*");
        }
        
        if (server.indexOf("http://") != -1)
        {
            var hostname : String = server.split("/")[2].split(":")[0];
            
            if (flash.system.Security.sandboxType != "application")
            {
                flash.system.Security.allowDomain(hostname);
                flash.system.Security.allowInsecureDomain(hostname);
            }
        }
        
        return hostname;
    }
    
    
    
    public static function isNetworkAvailable() : Bool
    {
        return Security.sandboxType != "localWithFile";
    }
    
    
    public static function set_comChannelName(val : String) : String
    {
        if (val != null)
        {
            if (val.length > 3)
            {
                _sendChannelName = val + "_fromgame";
                initComChannels();
            }
        }
        return val;
    }
    
    
    public static function get_connected() : Bool
    {
        return _connected;
    }
    
    /**
     * Method: connect
     * Connects your game to the MochiServices API
     * @param    id the MochiAds ID of your game
     * @param    clip the MovieClip in which to load the API (optional for all but AS3, defaults to _root)
     * @param    onError a function to call upon connection or IO error
     */
    public static function connect(id : String, clip : Dynamic, onError : Dynamic = null) : Void
    {
        if (Std.is(clip, DisplayObject))
        {
            if (!_connected && _clip == null)
            {
                trace("MochiServices Connecting...");
                _connecting = true;
                init(id, clip);
            }
        }
        else
        {
            trace("Error, MochiServices requires a Sprite, Movieclip or instance of the stage.");
        }
        if (onError != null)
        {
            MochiServices.onError = onError;
        }
        else if (MochiServices.onError == null)
        {
            MochiServices.onError = function(errorCode : String) : Void
                    {
                        trace(errorCode);
                    };
        }
    }
    
    public static function disconnect() : Void
    {
        if (_connected || _connecting)
        {
            if (_clip != null)
            {
                if (_clip.parent != null)
                {
                    if (Std.is(_clip.parent, Sprite))
                    {
                        Sprite(_clip.parent).removeChild(_clip);
                        _clip = null;
                    }
                }
            }
            _connecting = _connected = false;
            flush(true);
            try
            {
                (untyped _listenChannel).close();
            }
            catch (error : Error)
            {
            }
        }
        if (_timer != null)
        {
            try
            {
                _timer.stop();
            }
            catch (error : Error)
            {
            }
        }
    }
    
    public static function createEmptyMovieClip(parent : Dynamic, name : String, depth : Float, doAdd : Bool = true) : MovieClip
    {
        var mc : MovieClip = new MovieClip();
        if (doAdd)
        {
            if (false && (depth != 0 && !Math.isNaN(depth)))
            {
                parent.addChildAt(mc, depth);
            }
            else
            {
                parent.addChild(mc);
            }
        }
        try
        {
            Reflect.setField(parent, name, mc);
        }
        catch (e : Error)
        {
            throw new Error("MochiServices requires a clip that is an instance of a dynamic class.  If your class extends Sprite or MovieClip, you must make it dynamic.");
        }
        Reflect.setField(mc, "_name", name);
        return mc;
    }
    
    public static function stayOnTop() : Void
    {
        _container.addEventListener(Event.ENTER_FRAME, MochiServices.bringToTop, false, 0, true);
        if (_clip != null)
        {
            _clip.visible = true;
        }
    }
    
    
    public static function doClose() : Void
    {
        _container.removeEventListener(Event.ENTER_FRAME, MochiServices.bringToTop);
        if (_clip.parent != null)
        {
            Sprite(_clip.parent).removeChild(_clip);
        }
    }
    
    
    public static function bringToTop(e : Event) : Void
    {
        if (MochiServices.clip != null)
        {
            if (MochiServices.childClip != null)
            {
                try
                {
                    if (MochiServices.clip.numChildren > 1)
                    {
                        MochiServices.clip.setChildIndex(MochiServices.childClip, MochiServices.clip.numChildren - 1);
                    }
                }
                catch (errorObject : Error)
                {
                    trace("Warning: Depth sort error.");
                    _container.removeEventListener(Event.ENTER_FRAME, MochiServices.bringToTop);
                }
            }
        }
    }
    
    
    
    public static function init(id : String, clip : Dynamic) : Void
    {
        _id = id;
        if (clip != null)
        {
            _container = clip;
            loadCommunicator(id, _container);
        }
    }
    
    
    
    public static function setContainer(container : Dynamic = null, doAdd : Bool = true) : Void
    {
        if (container != null)
        {
            if (Std.is(container, Sprite))
            {
                _container = container;
            }
        }
        
        if (doAdd)
        {
            if (Std.is(_container, Sprite))
            {
                Sprite(_container).addChild(_clip);
            }
        }
    }
    
    
    
    
    public static function loadCommunicator(id : String, clip : Dynamic) : MovieClip
    {
        var clipname : String = "_mochiservices_com_" + id;
        
        if (_clip != null)
        {
            return _clip;
        }
        
        if (!MochiServices.isNetworkAvailable())
        {
            return null;
        }
        
        if (urlOptions(clip).servicesURL != null)
        {
            _servicesURL = urlOptions(clip).servicesURL;
        }
        
        MochiServices.allowDomains(_servicesURL);
        
        _clip = createEmptyMovieClip(clip, clipname, 10336, false);
        
        
        _loader = new Loader();
        
        var f : Function = function(ev : Dynamic) : Void
        {
            _clip._mochiad_ctr_failed = true;
            trace("MochiServices could not load.");
            MochiServices.disconnect();
            MochiServices.onError("IOError");
        }
        
        _listenChannelName += Math.floor((Date.now()).getTime()) + "_" + Math.floor(Math.random() * 99999);
        _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, f);
        
        var req : URLRequest = new URLRequest(_servicesURL);
        
        var vars : URLVariables = new URLVariables();
        vars.listenLC = _listenChannelName;
        vars.mochiad_options = clip.loaderInfo.parameters.mochiad_options;
        
        if (widget)
        {
            vars.widget = true;
        }
        req.data = vars;
        
        
        listen();
        _loader.load(req);
        
        _clip.addChild(_loader);
        _clip._mochiservices_com = _loader;
        
        
        _sendChannel = new LocalConnection();
        
        _clip._queue = [];
        _clip._nextcallbackID = 0;
        _clip._callbacks = { };
        
        _timer = new Timer(10000, 1);
        _timer.addEventListener(TimerEvent.TIMER, connectWait);
        _timer.start();
        
        return _clip;
    }
    
    
    
    public static function connectWait(e : TimerEvent) : Void
    {
        if (!_connected)
        {
            _clip._mochiad_ctr_failed = true;
            trace("MochiServices could not load. (timeout)");
            MochiServices.disconnect();
            MochiServices.onError("IOError");
        }
    }
    
    
    
    public static function onStatus(event : StatusEvent) : Void
    {
        var _sw1_ = (event.level);        

        switch (_sw1_)
        {
            case "error":
                _connected = false;
                _listenChannel.connect(_listenChannelName);
        }
    }
    
    
    
    public static function listen() : Void
    {
        _listenChannel = new LocalConnection();
        _listenChannel.client = _clip;
        _clip.handshake = function(args : Dynamic) : Void
                {
                    MochiServices.comChannelName = args.newChannel;
                };
        _listenChannel.allowDomain("*", "localhost");
        _listenChannel.allowInsecureDomain("*", "localhost");
        _listenChannel.connect(_listenChannelName);
        trace("Waiting for MochiAds services to connect...");
    }
    
    
    
    public static function initComChannels() : Void
    {
        if (!_connected)
        {
            _sendChannel.addEventListener(StatusEvent.STATUS, MochiServices.onStatus);
            _sendChannel.send(_sendChannelName, "onReceive", {
                        methodName : "handshakeDone"
                    });
            _sendChannel.send(_sendChannelName, "onReceive", {
                        methodName : "registerGame",
                        id : _id,
                        clip : _container,
                        version : getVersion(),
                        parentURL : _container.loaderInfo.loaderURL
                    });
            _listenChannel.addEventListener(StatusEvent.STATUS, MochiServices.onStatus);
            _clip.onReceive = function(pkg : Dynamic) : Void
                    {
                        var cb : String = pkg.callbackID;
                        var cblst : Dynamic = this.client._callbacks[cb];
                        if (cblst == null)
                        {
                            return;
                        }
                        var method : Dynamic = cblst.callbackMethod;
                        var methodName : String = "";
                        var obj : Dynamic = cblst.callbackObject;
                        if (obj != null && as3hx.Compat.typeof((method)) == "string")
                        {
                            methodName = method;
                            if (Reflect.field(obj, Std.string(method)) != null)
                            {
                                method = Reflect.field(obj, Std.string(method));
                            }
                            else
                            {
                                trace("Error: Method  " + method + " does not exist.");
                            }
                        }
                        if (method != null)
                        {
                            try
                            {
                                method.apply(obj, pkg.args);
                            }
                            catch (error : Error)
                            {
                                trace("Error invoking callback method '" + methodName + "': " + Std.string(error));
                            }
                        }
                        else if (obj != null)
                        {
                            try
                            {
                                obj(pkg.args);
                            }
                            catch (error : Error)
                            {
                                trace("Error invoking method on object: " + Std.string(error));
                            }
                        }
                        ;
                    };
            _clip.onError = function() : Void
                    {
                        MochiServices.onError("IOError");
                    };
            trace("connected!");
            _connecting = false;
            _connected = true;
            while (_clip._queue.length > 0)
            {
                _sendChannel.send(_sendChannelName, "onReceive", _clip._queue.shift());
            }
        }
    }
    
    
    
    
    public static function flush(error : Bool) : Void
    {
        var request : Dynamic = null;        var callback : Dynamic = null;        
        if (_clip != null)
        {
            if (_clip._queue != null)
            {
                while (_clip._queue.length > 0)
                {
                    request = _clip._queue.shift();
                    callback = null;
                    
                    if (request != null)
                    {
                        if (request.callbackID != null)
                        {
                            callback = _clip._callbacks[request.callbackID];
                        }
                        ;
                        
                        if (error && callback != null)
                        {
                            handleError(request.args, callback.callbackObject, callback.callbackMethod);
                        }
                    }
                }
            }
        }
    }
    
    
    
    public static function handleError(args : Dynamic, callbackObject : Dynamic, callbackMethod : Dynamic) : Void
    {
        if (args != null)
        {
            if (args.onError != null)
            {
                args.onError.apply(null, ["NotConnected"]);
            }
            if (args.options != null && args.options.onError != null)
            {
                args.options.onError.apply(null, ["NotConnected"]);
            }
        }
        
        if (callbackMethod != null)
        {
            args = { };
            args.error = true;
            args.errorCode = "NotConnected";
            
            if (callbackObject != null && Std.is(callbackMethod, String))
            {
                try
                {
                    Reflect.field(callbackObject, Std.string(callbackMethod))(args);
                }
                catch (error : Error)
                {
                }
            }
            else if (callbackMethod != null)
            {
                try
                {
                    callbackMethod.apply(args);
                }
                catch (error : Error)
                {
                }
            }
        }
    }
    
    
    
    public static function send(methodName : String, args : Dynamic = null, callbackObject : Dynamic = null, callbackMethod : Dynamic = null) : Void
    {
        if (_connected)
        {
            _sendChannel.send(_sendChannelName, "onReceive", {
                        methodName : methodName,
                        args : args,
                        callbackID : _clip._nextcallbackID
                    });
        }
        else if (_clip == null || !_connecting)
        {
            onError("NotConnected");
            handleError(args, callbackObject, callbackMethod);
            flush(true);
            return;
        }
        else
        {
            _clip._queue.push({
                        methodName : methodName,
                        args : args,
                        callbackID : _clip._nextcallbackID
                    });
        }
        if (_clip != null)
        {
            if (_clip._callbacks != null && _clip._nextcallbackID != null)
            {
                _clip._callbacks[_clip._nextcallbackID] = {
                            callbackObject : callbackObject,
                            callbackMethod : callbackMethod
                        };
                _clip._nextcallbackID++;
            }
        }
    }
    
    public static function urlOptions(clip : Dynamic) : Dynamic
    {
        var opts : Dynamic = { };
        var options : String = clip.loaderInfo.parameters.mochiad_options;
        if (options != null)
        {
            var pairs : Array<Dynamic> = options.split("&");
            for (i in 0...pairs.length)
            {
                var kv : Array<Dynamic> = pairs[i].split("=");
                Reflect.setField(opts, Std.string(unescape(kv[0])), unescape(kv[1]));
            }
        }
        
        return opts;
    }
    
    public static function addLinkEvent(url : String, burl : String, btn : DisplayObjectContainer, onClick : Function = null) : Void
    {
        var vars : Dynamic = {};
        var avm1Click : DisplayObject = null;        
        Reflect.setField(vars, "mav", getVersion());
        Reflect.setField(vars, "swfv", "9");
        Reflect.setField(vars, "swfurl", btn.loaderInfo.loaderURL);
        Reflect.setField(vars, "fv", Capabilities.version);
        Reflect.setField(vars, "os", Capabilities.os);
        Reflect.setField(vars, "lang", Capabilities.language);
        Reflect.setField(vars, "scres", (Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY));
        
        var s : String = "?";
        var i : Float = 0;
        for (x in Reflect.fields(vars))
        {
            if (i != 0)
            {
                s = s + "&";
            }
            i++;
            s = s + x + "=" + escape(Reflect.field(vars, x));
        }
        
        var req : URLRequest = new URLRequest("http://x.mochiads.com/linkping.swf");
        var loader : Loader = new Loader();
        
        var setURL : Function = function(url : String) : Void
        {
            if (avm1Click != null)
            {
                btn.removeChild(avm1Click);
            }
            
            avm1Click = clickMovie(url, onClick);
            var rect : Rectangle = btn.getBounds(btn);
            btn.addChild(avm1Click);
            avm1Click.x = rect.x;
            avm1Click.y = rect.y;
            avm1Click.scaleX = 0.01 * rect.width;
            avm1Click.scaleY = 0.01 * rect.height;
        }
        
        var err : Function = function(ev : Dynamic) : Void
        {
            netup = false;
            ev.target.removeEventListener(ev.type, arguments.callee);
            setURL(burl);
        }
        var complete : Function = function(ev : Dynamic) : Void
        {
            ev.target.removeEventListener(ev.type, arguments.callee);
        }
        
        if (netup)
        {
            setURL(url + s);
        }
        else
        {
            setURL(burl);
        }
        
        if (!(netupAttempted || _connected))
        {
            netupAttempted = true;
            
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, err);
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
            loader.load(req);
        }
    }
    
    
    public static function clickMovie(url : String, cb : Function) : MovieClip
    {
        var avm1_bytecode : Array<Dynamic> = [150, 21, 0, 7, 1, 0, 0, 0, 0, 98, 116, 110, 0, 7, 2, 0, 0, 0, 0, 116, 104, 105, 115, 0, 28, 150, 22, 0, 0, 99, 114, 101, 97, 116, 101, 69, 109, 112, 116, 121, 77, 111, 118, 105, 101, 67, 108, 105, 112, 0, 82, 135, 1, 0, 0, 23, 150, 13, 0, 4, 0, 0, 111, 110, 82, 101, 108, 101, 97, 115, 101, 0, 142, 8, 0, 0, 0, 0, 2, 42, 0, 114, 0, 150, 17, 0, 0, 32, 0, 7, 1, 0, 0, 0, 8, 0, 0, 115, 112, 108, 105, 116, 0, 82, 135, 1, 0, 1, 23, 150, 7, 0, 4, 1, 7, 0, 0, 0, 0, 78, 150, 8, 0, 0, 95, 98, 108, 97, 110, 107, 0, 154, 1, 0, 0, 150, 7, 0, 0, 99, 108, 105, 99, 107, 0, 150, 7, 0, 4, 1, 7, 1, 0, 0, 0, 78, 150, 27, 0, 7, 2, 0, 0, 0, 7, 0, 0, 0, 0, 0, 76, 111, 99, 97, 108, 67, 111, 110, 110, 101, 99, 116, 105, 111, 110, 0, 64, 150, 6, 0, 0, 115, 101, 110, 100, 0, 82, 79, 150, 15, 0, 4, 0, 0, 95, 97, 108, 112, 104, 97, 0, 7, 0, 0, 0, 0, 79, 150, 23, 0, 7, 255, 0, 255, 0, 7, 1, 0, 0, 0, 4, 0, 0, 98, 101, 103, 105, 110, 70, 105, 108, 108, 0, 82, 23, 150, 25, 0, 7, 0, 0, 0, 0, 7, 0, 0, 0, 0, 7, 2, 0, 0, 0, 4, 0, 0, 109, 111, 118, 101, 84, 111, 0, 82, 23, 150, 25, 0, 7, 100, 0, 0, 0, 7, 0, 0, 0, 0, 7, 2, 0, 0, 0, 4, 0, 0, 108, 105, 110, 101, 84, 111, 0, 82, 23, 150, 25, 0, 7, 100, 0, 0, 0, 7, 100, 0, 0, 0, 7, 2, 0, 0, 0, 4, 0, 0, 108, 105, 110, 101, 84, 111, 0, 82, 23, 150, 25, 0, 7, 0, 0, 0, 0, 7, 100, 0, 0, 0, 7, 2, 0, 0, 0, 4, 0, 0, 108, 105, 110, 101, 84, 111, 0, 82, 23, 150, 25, 0, 7, 0, 0, 0, 0, 7, 0, 0, 0, 0, 7, 2, 0, 0, 0, 4, 0, 0, 108, 105, 110, 101, 84, 111, 0, 82, 23, 150, 16, 0, 7, 0, 0, 0, 0, 4, 0, 0, 101, 110, 100, 70, 105, 108, 108, 0, 82, 23];
        var b : Int = 0;        var header : Array<Dynamic> = [
        0x68, 0x00, 0x1f, 0x40, 0x00, 0x07, 0xd0, 0x00, 
        0x00, 0x0c, 0x01, 0x00, 0x43, 0x02, 0xff, 0xff, 
        0xff, 0x3f, 0x03
    ];
        var footer : Array<Dynamic> = [0x00, 0x40, 0x00, 0x00, 0x00];
        
        var mc : MovieClip = new MovieClip();
        var lc : LocalConnection = new LocalConnection();
        var lc_name : String = "_click_" + Math.floor(Math.random() * 999999) + "_" + Math.floor((Date.now()).getTime());
        lc = new LocalConnection();
        mc.lc = lc;
        mc.click = cb;
        lc.client = mc;
        lc.connect(lc_name);
        
        var ba : ByteArray = new ByteArray();
        var cpool : ByteArray = new ByteArray();
        
        cpool.endian = Endian.LITTLE_ENDIAN;
        cpool.writeShort(1);
        cpool.writeUTFBytes(url + " " + lc_name);
        cpool.writeByte(0);
        
        var actionLength : Int = as3hx.Compat.parseInt(avm1_bytecode.length + cpool.length + 4);
        var fileLength : Int = as3hx.Compat.parseInt(actionLength + 35);
        
        ba.endian = Endian.LITTLE_ENDIAN;
        ba.writeUTFBytes("FWS");
        ba.writeByte(8);
        ba.writeUnsignedInt(fileLength);
        for (b in header)
        {
            ba.writeByte(b);
        }
        ba.writeUnsignedInt(actionLength);
        
        ba.writeByte(0x88);
        ba.writeShort(cpool.length);
        ba.writeBytes(cpool);
        
        for (b in avm1_bytecode)
        {
            ba.writeByte(b);
        }
        
        for (b in footer)
        {
            ba.writeByte(b);
        }
        
        var loader : Loader = new Loader();
        loader.loadBytes(ba);
        mc.addChild(loader);
        return mc;
    }

    public function new()
    {
    }
}

