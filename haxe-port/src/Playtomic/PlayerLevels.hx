  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Matrix;
import flash.net.SharedObject;

@:final class PlayerLevels
{public function new()
    {
    }public static inline var NEWEST : String = "newest";public static inline var POPULAR : String = "popular";private static var KongAPI : Dynamic = null;private static var KongLevelReceiver : Function;private static var SECTION : String;private static var SAVE : String;private static var LIST : String;private static var LOAD : String;private static var RATE : String;@:allow(playtomic)
    private static function Initialise(apikey : String) : Void
    {
        SECTION = Encode.MD5("playerlevels-" + apikey);RATE = Encode.MD5("playerlevels-rate-" + apikey);LIST = Encode.MD5("playerlevels-list-" + apikey);SAVE = Encode.MD5("playerlevels-save-" + apikey);LOAD = Encode.MD5("playerlevels-load-" + apikey);
    }  /**		 * Defers all level operations to Kongregate if you are using their level sharing API		 * @param	kongapi			Their API object		 * @param	levelreceiver	Your function to receive a PlayerLevel-formatted Kongregate level		 */  public static function DeferToKongregate(kongapi : Dynamic, levelreceiver : Function) : Void
    {
        KongLevelReceiver = levelreceiver;KongAPI = kongapi;KongAPI.sharedContent.addLoadListener("level", KongLevelLoaded);
    }  /**		 * Logs a start on a player level		 * @param	levelid			The playerLevel.LevelId 		 */  public static function LogStart(levelid : String) : Void
    {
        Log.PlayerLevelStart(levelid);
    }  /**		 * Logs a win on a player level		 * @param	levelid			The playerLevel.LevelId 		 */  public static function LogWin(levelid : String) : Void
    {
        Log.PlayerLevelWin(levelid);
    }  /**		 * Logs a quit on a player level		 * @param	levelid			The playerLevel.LevelId 		 */  public static function LogQuit(levelid : String) : Void
    {
        Log.PlayerLevelQuit(levelid);
    }  /**		 * Logs a retry on a player level		 * @param	levelid			The playerLevel.LevelId 		 */  public static function LogRetry(levelid : String) : Void
    {
        Log.PlayerLevelRetry(levelid);
    }  /**		 * Flags a player level		 * @param	levelid			The playerLevel.LevelId 		 */  public static function Flag(levelid : String) : Void
    {
        Log.PlayerLevelFlag(levelid);
    }  /**		 * Rates a player level		 * @param	levelid			The playerLevel.LevelId 		 * @param	rating			Integer from 1 to 10		 * @param	callback		Your function to receive the response:  function(response:Response)		 */  public static function Rate(levelid : String, rating : Int, callback : Function = null) : Void
    {
        var cookie : SharedObject = SharedObject.getLocal("ratings");if (cookie.data[levelid] != null)
        {
            if (callback != null)
            {
                callback(new Response(0, 402));
            }return;
        }if (rating < 0 || rating > 10)
        {
            if (callback != null)
            {
                callback(new Response(0, 401));
            }return;
        }var postdata : Dynamic = {};Reflect.setField(postdata, "levelid", levelid);Reflect.setField(postdata, "rating", rating);cookie.data[levelid] = rating;PRequest.Load(SECTION, RATE, RateComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function RateComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }callback(response);data = data;postdata = postdata;
    }  /**		 * Loads a player level		 * @param	levelid			The playerLevel.LevelId 		 * @param	callback		Your function to receive the response:  function(response:Response)		 */  public static function Load(levelid : String, callback : Function = null) : Void
    {
        var postdata : Dynamic = {};Reflect.setField(postdata, "levelid", levelid);PRequest.Load(SECTION, LOAD, LoadComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LoadComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var level : PlayerLevel = null;if (response.Success)
        {
            var item : FastXML = FastXML.parse(data.get("level"));var datestring : String = item.get("sdate");var year : Int = as3hx.Compat.parseInt(datestring.substring(datestring.lastIndexOf("/") + 1));var month : Int = as3hx.Compat.parseInt(datestring.substring(0, datestring.indexOf("/")));var day : Int = as3hx.Compat.parseInt(datestring.substring(datestring.indexOf("/") + 1).substring(0, 2));level = new PlayerLevel();level.LevelId = item.get("levelid");level.PlayerName = item.get("playername");level.PlayerId = item.get("playerid");level.Name = item.get("name");level.Score = item.get("score");level.Votes = item.get("votes");level.Rating = item.get("rating");level.Data = item.get("data");level.Wins = item.get("wins");level.Starts = item.get("starts");level.Retries = item.get("retries");level.Quits = item.get("quits");level.Flags = item.get("flags");level.SDate = new Date(year, month - 1, day);level.RDate = item.get("rdate");level.SetThumb(item.get("thumb"));if (item.get("custom") != null)
            {
                var custom : FastXMLList = item.get("custom");for (cfield/* AS3HX WARNING could not determine type for var: cfield exp: ECall(EField(EIdent(custom),children),[]) type: null */ in custom.node.children.innerData())
                {
                    level.CustomData[cfield.name()] = cfield.text();
                }
            }
        }callback(level, response);postdata = postdata;
    }  /**		 * Lists player levels		 * @param	callback		Your function to receive the response:  function(response:Response)		 * @param	options			The list options, see http://playtomic.com/api/as3#PlayerLevels		 */  public static function List(callback : Function = null, options : Dynamic = null) : Void
    {
        if (options == null)
        {
            options = {};
        }var mode : String = (options.exists("mode")) ? Reflect.field(options, "mode") : "popular";var page : Int = (options.exists("page")) ? Reflect.field(options, "page") : 1;var perpage : Int = (options.exists("perpage")) ? Reflect.field(options, "perpage") : 20;var datemin : String = (options.exists("datemin")) ? Reflect.field(options, "datemin") : "";var datemax : String = (options.exists("datemax")) ? Reflect.field(options, "datemax") : "";var data : Bool = (options.exists("data")) ? Reflect.field(options, "data") : false;var thumbs : Bool = (options.exists("thumbs")) ? Reflect.field(options, "thumbs") : false;var customfilters : Dynamic = (options.exists("customfilters")) ? Reflect.field(options, "customfilters") : { };  // defer to kongregate  if (KongAPI != null)
        {
            if (mode == "popular")
            {
                KongAPI.sharedContent.browse("level", KongAPI.sharedContent.BY_RATING);
            }
            else
            {
                KongAPI.sharedContent.browse("level", KongAPI.sharedContent.BY_NEWEST);
            }return;
        }var postdata : Dynamic = {};Reflect.setField(postdata, "mode", mode);Reflect.setField(postdata, "page", page);Reflect.setField(postdata, "perpage", perpage);Reflect.setField(postdata, "data", (data) ? "y" : "n");Reflect.setField(postdata, "thumbs", (thumbs) ? "y" : "n");Reflect.setField(postdata, "datemin", datemin);Reflect.setField(postdata, "datemax", datemax);var numcustomfilters : Int = 0;if (customfilters != null)
        {
            for (key in Reflect.fields(customfilters))
            {
                Reflect.setField(postdata, Std.string("ckey" + numcustomfilters), numcustomfilters);Reflect.setField(postdata, Std.string("cdata" + numcustomfilters), numcustomfilters);numcustomfilters++;
            }
        }Reflect.setField(postdata, "filters", numcustomfilters);PRequest.Load(SECTION, LIST, ListComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function ListComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var levels : Array<Dynamic> = [];var numresults : Int = 0;if (response.Success)
        {
            var entries : FastXMLList = data.get("level");var cfield : FastXML;var datestring : String;var year : Int;var month : Int;var day : Int;numresults = data.get("numresults");for (item in entries)
            {
                datestring = item.get("sdate");year = as3hx.Compat.parseInt(datestring.substring(datestring.lastIndexOf("/") + 1));month = as3hx.Compat.parseInt(datestring.substring(0, datestring.indexOf("/")));day = as3hx.Compat.parseInt(datestring.substring(datestring.indexOf("/") + 1).substring(0, 2));var level : PlayerLevel = new PlayerLevel();level.LevelId = item.get("levelid");level.PlayerId = item.get("playerid");level.PlayerName = item.get("playername");level.Name = item.get("name");level.Score = item.get("score");level.Rating = item.get("rating");level.Votes = item.get("votes");level.Wins = item.get("wins");level.Starts = item.get("starts");level.Retries = item.get("retries");level.Quits = item.get("quits");level.Flags = item.get("flags");level.SDate = new Date(year, month - 1, day);level.RDate = item.get("rdate");if (item.get("data") != null)
                {
                    level.Data = item.get("data");
                }level.SetThumb(item.get("thumb"));var custom : FastXMLList = item.get("custom");if (custom != null)
                {
                    for (cfield/* AS3HX WARNING could not determine type for var: cfield exp: ECall(EField(EIdent(custom),children),[]) type: null */ in custom.node.children.innerData())
                    {
                        level.CustomData[cfield.node.name.innerData()] = cfield.node.text.innerData();
                    }
                }levels.push(level);
            }
        }callback(levels, numresults, response);postdata = postdata;
    }  /**		 * Saves a player level		 * @param	level			The PlayerLevel to save		 * @param	thumb			A movieclip or other displayobject (optional)		 * @param	callback		Your function to receive the response:  function(level:PlayerLevel, response:Response)		 */  public static function Save(level : PlayerLevel, thumb : DisplayObject = null, callback : Function = null) : Void
    // defer to kongregate
    {
        if (KongAPI != null)
        {
            var kcallback : Function = function(kparam : Dynamic) : Void
            {
                level.LevelId = Reflect.field(kparam, "id");level.Permalink = Reflect.field(kparam, "permalink");level.Name = Reflect.field(kparam, "name");if (callback != null)
                {
                    callback(level, new Response((Reflect.field(kparam, "success") != null) ? 1 : 0, 0));
                }
            }KongAPI.sharedContent.save("level", level.Data, kcallback, thumb, level.Name);return;
        }var postdata : Dynamic = {};Reflect.setField(postdata, "data", level.Data);Reflect.setField(postdata, "playerid", level.PlayerId);Reflect.setField(postdata, "playersource", level.PlayerSource);Reflect.setField(postdata, "playername", level.PlayerName);Reflect.setField(postdata, "name", level.Name);if (thumb != null)
        {
            var scale : Float = 1;var w : Int = thumb.width;var h : Int = thumb.height;if (thumb.width > 100 || thumb.height > 100)
            {
                if (thumb.width >= thumb.height)
                {
                    scale = 100 / thumb.width;w = 100;h = Math.ceil(scale * thumb.height);
                }
                else if (thumb.height > thumb.width)
                {
                    scale = 100 / thumb.height;w = Math.ceil(scale * thumb.width);h = 100;
                }
            }var scaler : Matrix = new Matrix();scaler.scale(scale, scale);var image : BitmapData = new BitmapData(w, h, true, 0x00000000);image.draw(thumb, scaler, null, null, null, true);Reflect.setField(postdata, "image", Encode.Base64(Encode.PNG(image)));Reflect.setField(postdata, "arrp", cast((image), RandomSample));Reflect.setField(postdata, "hash", Encode.MD5(Reflect.field(postdata, "image") + Reflect.field(postdata, "arrp")));
        }
        else
        {
            Reflect.setField(postdata, "nothumb", "y");
        }var customfields : Int = 0;if (level.CustomData != null)
        {
            for (key in Reflect.fields(level.CustomData))
            {
                Reflect.setField(postdata, Std.string("ckey" + customfields), customfields);Reflect.setField(postdata, Std.string("cdata" + customfields), customfields);customfields++;
            }
        }Reflect.setField(postdata, "customfields", customfields);PRequest.Load(SECTION, SAVE, SaveComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function SaveComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var level : PlayerLevel = new PlayerLevel();level.Data = Reflect.field(postdata, "data");level.PlayerId = Reflect.field(postdata, "playerid");level.PlayerSource = Reflect.field(postdata, "playersource");level.PlayerName = Reflect.field(postdata, "playername");level.Name = Reflect.field(postdata, "name");for (key in Reflect.fields(postdata))
        {
            if (key.indexOf("ckey") == 0)
            {
                var num : String = key.substring(4);var name : String = Reflect.field(postdata, Std.string("ckey" + num));var value : String = Reflect.field(postdata, Std.string("cdata" + num));level.CustomData[name] = value;
            }
        }Reflect.setField(postdata, "data", level.Data);Reflect.setField(postdata, "playerid", level.PlayerId);Reflect.setField(postdata, "playersource", level.PlayerSource);Reflect.setField(postdata, "playername", level.PlayerName);Reflect.setField(postdata, "name", level.Name);if (response.Success || response.ErrorCode == 406)
        {
            level.LevelId = data.get("levelid");level.SDate = Date.now();level.RDate = "Just now";
        }callback(level, response);
    }  /**		 * Bridge used when deferring to Kongregate and loading a level		 * @param	params		The object Kongregate gives us		 */  private static function KongLevelLoaded(params : Dynamic) : Void
    {
        var level : PlayerLevel = new PlayerLevel();level.Data = Reflect.field(params, "content");level.Permalink = Reflect.field(params, "permalink");level.Name = Reflect.field(params, "name");level.LevelId = Reflect.field(params, "id");if (KongLevelReceiver != null)
        {
            cast((level), KongLevelReceiver);
        }
    }  /**		 * Gets a random sampling of pixels from an image		 * @param	b	The image		 */  private static function RandomSample(b : BitmapData) : String
    {
        var arr : Array<Dynamic> = new Array<Dynamic>();var x : Int;var y : Int;var c : String;while (arr.length < 10)
        {
            x = as3hx.Compat.parseInt(Math.random() * b.width);y = as3hx.Compat.parseInt(Math.random() * b.height);c = Std.string(b.getPixel32(x, y));while (c.length < 6)
            {
                c = "0" + c;
            }arr.push(x + "/" + y + "/" + c);
        }return arr.join(",");
    }
}