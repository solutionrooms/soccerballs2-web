  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import flash.errors.Error;
import flash.display.LoaderInfo;
import flash.events.ErrorEvent;
import flash.events.TimerEvent;
import flash.events.UncaughtErrorEvent;
import flash.external.ExternalInterface;
import flash.net.SharedObject;
import flash.system.Security;
import flash.utils.Timer;

@:final class Log
{  // API settings  private static var Enabled : Bool = false;private static var Queue : Bool = true;  // SWF settings  @:allow(playtomic)
    private static var SWFID : Int = 0;@:allow(playtomic)
    private static var GUID : String = "";@:allow(playtomic)
    private static var SourceUrl : String;@:allow(playtomic)
    private static var BaseUrl : String;  // play timer, goal tracking etc  private static var Cookie : SharedObject;@:allow(playtomic)
    private static var LogQueue : LogRequest;private static var PingF : Timer = new Timer(1000);private static var Pings : Int = 0;private static var Plays : Int = 0;private static var Frozen : Bool = false;private static var FrozenQueue : Array<Dynamic> = new Array<Dynamic>();  // unique, logged metrics  private static var Customs : Array<Dynamic> = new Array<Dynamic>();private static var LevelCounters : Array<Dynamic> = new Array<Dynamic>();private static var LevelAverages : Array<Dynamic> = new Array<Dynamic>();private static var LevelRangeds : Array<Dynamic> = new Array<Dynamic>();  // parameterized events and other premium features  @:allow(playtomic)
    private static var UseSSL : Bool = false;@:allow(playtomic)
    private static var PEventsEnabled : Bool = false;@:allow(playtomic)
    private static var PData : Dynamic = { };@:allow(playtomic)
    private static var PersistantParams : Dynamic = { };@:allow(playtomic)
    private static var PTime : Int = 0;  /**		 * Sets the API to use SSL-only for all communication		 */  public static function SetSSL() : Void
    {
        UseSSL = true;trace("You are now using SSL for your api requests.  This feature is for premium users only, if your account is not premium the data you send will be ignored.");
    }  /**		 * Sets the referrer		 */  public static function SetReferrer(ref : String) : Void
    {
        PRequest.SendReferrer(ref);
    }  /**		 * Logs a view and initializes the API.  You must do this first before anything else!		 * @param	swfid		Your game id from the Playtomic dashboard		 * @param	guid		Your game guid from the Playtomic dashboard		 * @param	apikey		Your secret API key from the Playtomic dashboard		 * @param	defaulturl	Should be root.loaderInfo.loaderURL or some other default url value to be used if we can't detect the page		 */  public static function View(swfid : Int = 0, guid : String = "", apikey : String = "", loader : LoaderInfo = null) : Void
    {
        if (loader == null)
        {
            defaulturl = apikey;apikey = "";trace("Warning: It looks like you are using the Log.View method from the old version of the API.");trace("Please update your Log.View call to use the new structure: ");trace("Log.View(swfid, guid, apikey, root.loaderInfo.loaderURL);");trace("You can get or create your API key from your game's settings page");
        }if (SWFID > 0)
        {
            return;
        }SWFID = swfid;GUID = guid;Enabled = true;if (SWFID == 0 || GUID == "")
        {
            Enabled = false;return;
        }var defaulturl : String = loader.loaderURL;SourceUrl = cast((defaulturl), GetUrl);if (SourceUrl == null || SourceUrl == "")
        {
            Enabled = false;return;
        }BaseUrl = SourceUrl.split("://")[1];BaseUrl = BaseUrl.substring(0, BaseUrl.indexOf("/"));Parse.Initialise(apikey);GeoIP.Initialise(apikey);Data.Initialise(apikey);Leaderboards.Initialise(apikey);Playtomic.GameVars.Initialise(apikey);PlayerLevels.Initialise(apikey);PRequest.Initialise();LogQueue = LogRequest.Create();Cookie = SharedObject.getLocal("playtomic");  // Load the security context  Security.loadPolicyFile(((UseSSL) ? "https://g" : "http://g") + guid + ".api.playtomic.com/crossdomain.xml");  // Check the URL is http / https  if (defaulturl.indexOf("http://") != 0 && defaulturl.indexOf("https://") != 0)
        
        // Sandbox exceptions for testing{
            if (Security.sandboxType != "localWithNetwork" && Security.sandboxType != "localTrusted" && Security.sandboxType != "remote")
            {
                Enabled = false;return;
            }
        }  // Log the view (first or repeat visitor)  var views : Int = cast(("views"), GetCookie);Send("v/" + (views + 1), true);  // Start the play timer  PingF.addEventListener(TimerEvent.TIMER, PingServer);PingF.start();  // exception catching    //	trace("adding exception catching: " + UncaughtErrorEvent.UNCAUGHT_ERROR);    //	loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, LogException);    // PEvents  if (!PEventsEnabled)
        {
            return;
        }PData.source = BaseUrl;PData.views = views + 1;PData.time = 0;PData.eventnum = 0;PData.location = "initialize";PData.api = "flash";PData.apiversion = "3.48";PData.params = { };SetSession();SendPEvent();
    }  /*private static function LogException(e:UncaughtErrorEvent):void		{			trace("EXCEPTION: ");			trace(e.toString());			e.preventDefault()		}*/    /**		 * Sets user defined session information.  Leave parameters empty strings to use default values		 * @param	sessionid	Your own session id		 * @param	referredby	The ad or campaign or other source this visitor came by		 * @param	invitedby	The invitation that led to the player joining your game		 */  private static function SetSessionInfo(sessionid : String = "", referredby : String = "", invitedby : String = "") : Void
    {
        if (sessionid != null && sessionid != "")
        {
            SaveCookieS("sessionid", sessionid);PData.sessionid = sessionid;
        }if (referredby != null && referredby != "")
        {
            SaveCookieS("referredby", referredby);PData.referredby = referredby;
        }if (invitedby != null && invitedby != "")
        {
            SaveCookieS("invitedby", invitedby);PData.invitedby = invitedby;
        }
    }  /**		 * Sets the player session up if it hasn't already been		 */  private static function SetSession() : Void
    {
        if (!PData.session)
        {
            var csession : String = cast(("session"), GetCookieS);if (csession != "")
            {
                PData.session = csession;
            }
            else
            {
                PData.session = Encode.MD5(SessionID.Create() + SessionID.Create());SaveCookieS("session", PData.session);
            }
        }if (!PData.invitedby)
        {
            PData.invitedby = cast(("invitedby"), GetCookieS);
        }if (!PData.referredby)
        {
            PData.referredby = cast(("referredby"), GetCookieS);
        }
    }  /**		 * Logs an event with parameters		 * @param	params		Any parameters you wish to include with the event such as gender, how they found your game, etc		 * @param	location	The player's current location (eg main menu, level 1)		 */  private static function PEvent(params : Dynamic, location : String = null) : Void
    {
        if (location != null)
        {
            PData.locationbefore = PData.location;PData.location = location;
        }PData.timebefore = PData.time;PData.time = PTime;PData.eventnum++;PData.params = params;SendPEvent();
    }  /**		 * Logs a transaction in a PEvent		 * @param	params		Any parameters you wish to include		 * @param	location	The player's current location		 * @param	transactions	Array of transactions: {item: string, quantity: int, price: number, any other properties you want}		 */  private static function PTransaction(params : Dynamic, location : String, transactions : Array<Dynamic>) : Void
    {
        var nparams : Dynamic = { };for (x in Reflect.fields(params))
        {
            Reflect.setField(nparams, x, Reflect.field(params, x));
        }var total : Float = 0;for (i in 0...transactions.length)
        {
            if (!transactions[i].exists("item"))
            {
                trace("** PEVENT ERROR ** Transaction is missing 'item'.\nThe transactions array must be {item: 'name', quantity: int, price: number, ... }");return;
            }if (!transactions[i].exists("quantity"))
            {
                trace("** PEVENT ERROR ** Transaction is missing 'quantity'.\nThe transactions array must be {item: 'name', quantity: int, price: number, ... }");return;
            }if (!transactions[i].exists("price"))
            {
                trace("** PEVENT ERROR ** Transaction is missing 'price'.\nThe transactions array must be {item: 'name', quantity: int, price: number, ... }");return;
            }total += transactions[i].price;
        }nparams.transactions = transactions;nparams.total = total;PData.transaction = true;PEvent(nparams, location);This is an intentional compilation error. See the README for handling the delete keyword
        delete (PData.transaction);
    }  /**		 * Logs an invitation in a PEvent		 * @param	params		Any parameters you wish to include		 * @param	location	The player's current location		 * @param	invitations	Array of friend id's invited, from Facebook or other		 */  private static function PInvitation(params : Dynamic, location : String, invitations : Array<Dynamic>) : Void
    {
        var nparams : Dynamic = { };for (x in Reflect.fields(params))
        {
            Reflect.setField(nparams, x, Reflect.field(params, x));
        }nparams.invitations = invitations;nparams.total = invitations.length;PData.invitation = true;PEvent(nparams, location);This is an intentional compilation error. See the README for handling the delete keyword
        delete (PData.invitation);
    }  /**		 * Merges persistant parameters with event parameters and sends		 */  private static function SendPEvent() : Void
    {
        for (x in Reflect.fields(PersistantParams))
        {
            PData.params[x] = Reflect.field(PersistantParams, x);
        }PRequest.SendPEvent(PData);
    }  /**		 * Increases the number of views successfully logged 		 */  @:allow(playtomic)
    private static function IncreaseViews() : Void
    {
        var views : Int = cast(("views"), GetCookie);views++;SaveCookie("views", views);
    }  /**		 * Increases the number of plays successfully logged 		 */  @:allow(playtomic)
    private static function IncreasePlays() : Void
    {
        Plays++;
    }  /**		 * Logs a play.  Call this when the user begins an actual game (eg clicks play button)		 */  public static function Play() : Void
    {
        if (!Enabled)
        {
            return;
        }LevelCounters = new Array<Dynamic>();LevelAverages = new Array<Dynamic>();LevelRangeds = new Array<Dynamic>();Send("p/" + (Plays + 1), true);
    }  /**		 * Increases the play time and triggers events being sent		 */  private static function PingServer(e : TimerEvent) : Void
    {
        if (!Enabled)
        {
            return;
        }PTime++;if (PTime == 60)
        {
            Pings = 1;Send("t/y/1", true);
        }
        else if (PTime > 60 && PTime % 30 == 0)
        {
            Pings++;Send("t/n/" + Pings, true);
        }
    }  /**		 * Logs a custom metric which can be used to track how many times something happens in your game.		 * @param	name		The metric name		 * @param	group		Optional group used in reports		 * @param	unique		Only count a metric one single time per view		 */  public static function CustomMetric(name : String, group : String = null, unique : Bool = false) : Void
    {
        if (!Enabled)
        {
            return;
        }if (group == null)
        {
            group = "";
        }if (unique)
        {
            if (Lambda.indexOf(Customs, name) > -1)
            {
                return;
            }Customs.push(name);
        }cast(("c/" + cast((name), Clean) + "/" + cast((group), Clean)), Send);
    }  /**		 * Logs a level counter metric which can be used to track how many times something occurs in levels in your game.		 * @param	name		The metric name		 * @param	level		The level number as an integer or name as a string		 * @param	unique		Only count a metric one single time per play		 */  public static function LevelCounterMetric(name : String, level : Dynamic, unique : Bool = false) : Void
    {
        if (!Enabled)
        {
            return;
        }if (unique)
        {
            var key : String = name + "." + Std.string(level);if (Lambda.indexOf(LevelCounters, key) > -1)
            {
                return;
            }LevelCounters.push(key);
        }cast(("lc/" + cast((name), Clean) + "/" + cast((level), Clean)), Send);
    }  /**		 * Logs a level ranged metric which can be used to track how many times a certain value is achieved in levels in your game.		 * @param	name		The metric name		 * @param	level		The level number as an integer or name as a string		 * @param	value		The value being tracked		 * @param	unique		Only count a metric one single time per play		 */  public static function LevelRangedMetric(name : String, level : Dynamic, value : Int, unique : Bool = false) : Void
    {
        if (!Enabled)
        {
            return;
        }if (unique)
        {
            var key : String = name + "." + Std.string(level) + "." + Std.string(value);if (Lambda.indexOf(LevelRangeds, key) > -1)
            {
                return;
            }LevelRangeds.push(key);
        }cast(("lr/" + cast((name), Clean) + "/" + cast((level), Clean) + "/" + value), Send);
    }  /**		 * Logs a level average metric which can be used to track the min, max, average and total values for an event.		 * @param	name		The metric name		 * @param	level		The level number as an integer or name as a string		 * @param	value		The value being added		 * @param	unique		Only count a metric one single time per play		 */  public static function LevelAverageMetric(name : String, level : Dynamic, value : Int, unique : Bool = false) : Void
    {
        if (!Enabled)
        {
            return;
        }if (unique)
        {
            var key : String = name + "." + Std.string(level);if (Lambda.indexOf(LevelAverages, key) > -1)
            {
                return;
            }LevelAverages.push(key);
        }cast(("la/" + cast((name), Clean) + "/" + cast((level), Clean) + "/" + value), Send);
    }  /**		 * Logs the link results, internal use only.  The correct use is Link.Open(...)		 * @param	url		The url that was opened		 * @param	name	The name for the url		 * @param	group	The group for the url 		 * @param	unique	Increase uniques by this value		 * @param	total	Increase totals by this value		 * @param	fail	Increase fails by this value		 */  @:allow(playtomic)
    private static function Link(url : String, name : String, group : String, unique : Int, total : Int, fail : Int) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("l/" + cast((name), Clean) + "/" + cast((group), Clean) + "/" + cast((url), Clean) + "/" + unique + "/" + total + "/" + fail), Send);
    }  /**		 * Logs a heatmap which allows you to visualize where some event occurs.		 * @param	metric		The metric you are tracking (eg clicks)		 * @param	heatmap		The heatmap (the one you upload images for)		 * @param	x			The x coordinate		 * @param	y			The y coordinate		 */  public static function Heatmap(metric : String, heatmap : String, x : Int, y : Int) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("h/" + cast((metric), Clean) + "/" + cast((heatmap), Clean) + "/" + x + "/" + y), Send);
    }  /**		 * Not yet implemented :(		 */  @:allow(playtomic)
    private static function Funnel(name : String, step : String, stepnum : Int) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("f/" + cast((name), Clean) + "/" + cast((step), Clean) + "/" + stepnum), Send);
    }  /**		 * Logs a start of a player level, internal use only.  The correct use is PlayerLevels.LogStart(...);		 * @param	levelid		The player level id		 */  @:allow(playtomic)
    private static function PlayerLevelStart(levelid : String) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("pls/" + levelid), Send);
    }  /**		 * Logs a win on a player level, internal use only.  The correct use is PlayerLevels.LogWin(...);		 * @param	levelid		The player level id		 */  @:allow(playtomic)
    private static function PlayerLevelWin(levelid : String) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("plw/" + levelid), Send);
    }  /**		 * Logs a quit on a player level, internal use only.  The correct use is PlayerLevels.LogQuit(...);		 * @param	levelid		The player level id		 */  @:allow(playtomic)
    private static function PlayerLevelQuit(levelid : String) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("plq/" + levelid), Send);
    }  /**		 * Logs a flag on a player level, internal use only.  The correct use is PlayerLevels.Flag(...);		 * @param	levelid		The player level id		 */  @:allow(playtomic)
    private static function PlayerLevelFlag(levelid : String) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("plf/" + levelid), Send);
    }  /**		 * Logs a retry on a player level, internal use only.  The correct use is PlayerLevels.LogRetry(...);		 * @param	levelid		The player level id		 */  @:allow(playtomic)
    private static function PlayerLevelRetry(levelid : String) : Void
    {
        if (!Enabled)
        {
            return;
        }cast(("plr/" + levelid), Send);
    }  /**		 * Freezes the API so analytics events are queued but not sent		 */  public static function Freeze() : Void
    {
        Frozen = true;
    }  /**		 * Unfreezes the API and sends any queued events		 */  public static function UnFreeze() : Void
    {
        if (!Enabled)
        {
            return;
        }Frozen = false;LogQueue.MassQueue(FrozenQueue);
    }  /**		 * Forces the API to send any unsent data now		 */  public static function ForceSend() : Void
    {
        if (!Enabled)
        {
            return;
        }if (LogQueue == null)
        {
            LogQueue = LogRequest.Create();
        }LogQueue.Send();LogQueue = LogRequest.Create();if (FrozenQueue.length > 0)
        {
            LogQueue.MassQueue(FrozenQueue);
        }
    }  /**		 * Adds an event and if ready or a view or not queuing, sends it		 * @param	s	The event as an ev/xx string		 * @param	view	If it's a view or not		 */  private static function Send(s : String, view : Bool = false) : Void
    {
        if (Frozen)
        {
            FrozenQueue.push(s);return;
        }LogQueue.Queue(s);if (LogQueue.ready || view || !Queue)
        {
            LogQueue.Send();LogQueue = LogRequest.Create();
        }
    }  /**		 * Cleans a piece of text of reserved characters		 * @param	s	The string to be cleaned		 */  private static function Clean(s : String) : String
    {
        while (s.indexOf("/") > -1)
        {
            s = StringTools.replace(s, "/", "\\");
        }while (s.indexOf("~") > -1)
        {
            s = StringTools.replace(s, "~", "-");
        }return escape(s);
    }  /**		 * Gets a cookie value		 * @param	n	The key (views, plays)		 */  private static function GetCookie(n : String) : Int
    {
        if (Cookie.data[n] == null)
        {
            return 0;
        }
        else
        {
            return as3hx.Compat.parseInt(Cookie.data[n]);
        }
    }private static function GetCookieS(n : String) : String
    {
        if (Cookie.data[n] == null)
        {
            return "";
        }
        else
        {
            return Cookie.data[n];
        }
    }  /**		 * Saves a cookie value		 * @param	n	The key (views, plays)		 * @param	v	The value		 */  private static function SaveCookie(n : String, v : Int) : Void
    {
        Cookie.data[n] = Std.string(v);try
        {
            Cookie.flush();
        }
        catch (s : Error)
        {
        }
    }private static function SaveCookieS(n : String, v : String) : Void
    {
        Cookie.data[n] = Std.string(v);try
        {
            Cookie.flush();
        }
        catch (s : Error)
        {
        }
    }  /**		 * Attempts to detect the page url		 * @param	defaulturl		The fallback url if page cannot be detected		 */  private static function GetUrl(defaulturl : String) : String
    {
        var url : String;if (ExternalInterface.available)
        {
            try
            {
                url = Std.string(ExternalInterface.call("window.location.href.toString"));
            }
            catch (s : Error)
            {
                url = defaulturl;
            }
        }
        else if (defaulturl.indexOf("http://") == 0 || defaulturl.indexOf("https://") == 0)
        {
            url = defaulturl;
        }if (url == null || url == "" || url == "null")
        {
            url = "http://localhost/";
        }if (url.indexOf("http://") != 0 && url.indexOf("https://") != 0)
        {
            url = "http://localhost/";
        }return url;
    }

    public function new()
    {
    }
}