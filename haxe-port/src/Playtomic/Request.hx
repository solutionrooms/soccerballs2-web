package playtomic;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.events.Event;
import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.net.URLVariables;
import flash.utils.Timer;
import flash.utils.ByteArray;

@:final class Request extends URLLoader
{
    public static var Pool : Array<Request>;
    public static var Queue : Array<Request>;
    public static var URLStub : String;
    public static var URLTail : String;
    public static var URL : String;
    
    public var urlRequest : URLRequest = new URLRequest();
    public var complete : Function;
    public var callback : Function;
    public var handled : Bool;
    public var logging : Bool;
    public var postdata : Dynamic;
    public var time : Int;
    
    @:allow(playtomic)
    public static function Initialise() : Void
    {
        Pool = [];
        Queue = [];
        URLStub = "http://g" + Log.GUID + ".api.playtomic.com";
        URLTail = "swfid=" + Log.SWFID;
        URL = URLStub + "/v3/api.aspx?" + URLTail;
        
        var reqtimer : Timer = new Timer(500);
        reqtimer.addEventListener("timer", TimeoutHandler);
        reqtimer.start();
        
        for (i in 0...20)
        {
            Pool.push(new Request());
        }
    }
    
    @:allow(playtomic)
    public static function SendStatistics(complete : Function, url : String) : Void
    {
        var request : Request = (Pool.length > 0) ? Pool.pop() : new Request();
        request.time = 0;
        request.handled = false;
        request.complete = complete;
        request.callback = null;
        request.logging = true;
        request.urlRequest.url = URLStub + url + (url.indexOf("?") > -(1) ? "&" : "?") + URLTail + "&" + Math.random() + "Z";
        request.urlRequest.method = "GET";
        request.urlRequest.data = null;
        request.postdata = null;
        request.load(request.urlRequest);
        Queue.push(request);
    }
    
    @:allow(playtomic)
    public static function Load(section : String, action : String, complete : Function, callback : Function, postdata : Dynamic = null) : Void
    {
        var request : Request = (Pool.length > 0) ? Pool.pop() : new Request();
        request.time = 0;
        request.handled = false;
        request.complete = complete;
        request.callback = callback;
        request.logging = false;
        
        var url : String = URL + "&r=" + Math.random() + "Z";
        var timestamp : String = Std.string(Date.now().time).substring(0, 10);
        var nonce : String = Encode.MD5(Date.now().time * Math.random() + Log.GUID);
        
        
        
        var pd : Array<Dynamic> = [];
        pd.push("nonce=" + nonce);
        pd.push("timestamp=" + timestamp);
        
        for (key in Reflect.fields(postdata))
        {
            pd.push(key + "=" + Escape(Reflect.field(postdata, key)));
        }
        
        
        
        
        
        GenerateKey("section", section, pd);
        GenerateKey("action", action, pd);
        GenerateKey("signature", nonce + timestamp + section + action + url + Log.GUID, pd);
        
        
        
        var pda : ByteArray = new ByteArray();
        pda.writeUTFBytes(pd.join("&"));
        pda.position = 0;
        
        var postvars : URLVariables = new URLVariables();
        Reflect.setField(postvars, "data", Escape(Encode.Base64(pda)));
        
        request.urlRequest.url = url;
        request.urlRequest.method = "POST";
        request.urlRequest.data = postvars;
        request.postdata = postdata;
        
        
        
        
        try
        {
            request.load(request.urlRequest);
        }
        catch (s : Error)
        {
            request.complete(request.callback, request.postdata, null, new Response(0, 1));
        }
        
        Queue.push(request);
    }
    
    public static function Escape(str : String) : String
    {
        if (str == null)
        {
            return "";
        }
        
        str = str.split("%").join("%25");
        str = str.split(";").join("%3B");
        str = str.split("?").join("%3F");
        str = str.split("/").join("%2F");
        str = str.split(":").join("%3A");
        str = str.split("#").join("%23");
        str = str.split("&").join("%26");
        str = str.split("=").join("%3D");
        str = str.split("+").join("%2B");
        str = str.split("$").join("%24");
        str = str.split(",").join("%2C");
        str = str.split(" ").join("%20");
        str = str.split("<").join("%3C");
        str = str.split(">").join("%3E");
        str = str.split("~").join("%7E");
        return str;
    }
    
    public static function GenerateKey(name : String, key : String, arr : Array<Dynamic>) : Void
    {
        arr.sort();
        
        
        
        
        arr.push(name + "=" + Encode.MD5(arr.join("&") + key));
    }
    
    public static function TimeoutHandler(e : Event) : Void
    {
        var request : Request;
        
        var n : Int = as3hx.Compat.parseInt(Queue.length - 1);
        while (n > -1)
        {
            request = Queue[n];
            
            if (!request.handled)
            {
                request.time++;
                
                if (request.time < 20)
                {
                    {n--;continue;
                    }
                }
                
                if (request.logging)
                {
                    request.complete(false);
                }
                else
                {
                    request.complete(request.callback, request.postdata, null, new Response(0, 3));
                }
            }
            
            Queue.splice(n, 1);
            Dispose(request);
            n--;
        }
    }
    
    public function new()
    {
        super();
        addEventListener("ioError", Fail);
        addEventListener("networkError", Fail);
        addEventListener("verifyError", Fail);
        addEventListener("diskError", Fail);
        addEventListener("securityError", Fail);
        addEventListener("httpStatus", HTTPStatusIgnore);
        addEventListener("complete", Complete);
    }
    
    public static function Complete(e : Event) : Void
    {
        var request : Request = try cast(e.target, Request) catch(e:Dynamic) null;
        
        if (request.handled)
        {
            return;
        }
        
        request.handled = true;
        
        if (request.logging)
        {
            request.complete(true);
            return;
        }
        
        
        
        var data : FastXML = FastXML(request.data);
        var status : Int = as3hx.Compat.parseInt(data.get("status"));
        var errorcode : Int = as3hx.Compat.parseInt(data.get("errorcode"));
        
        request.complete(request.callback, request.postdata, data, new Response(status, errorcode));
    }
    
    public static function Fail(e : Event) : Void
    {
        var request : Request = try cast(e.target, Request) catch(e:Dynamic) null;
        
        if (request.handled)
        {
            return;
        }
        
        request.handled = true;
        
        if (request.logging)
        {
            request.complete(false);
        }
        else
        {
            request.complete(request.callback, request.postdata, null, new Response(0, 1));
        }
    }
    
    public static function HTTPStatusIgnore(e : Event) : Void
    {
    }
    
    public static function Dispose(request : Request) : Void
    {
        if (!request.handled)
        {
            request.handled = true;
            request.close();
        }
        
        Pool.push(request);
    }
}

