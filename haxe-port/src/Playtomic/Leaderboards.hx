  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.external.ExternalInterface;

@:final class Leaderboards
{public static inline var TODAY : String = "today";public static inline var LAST7DAYS : String = "last7days";public static inline var LAST30DAYS : String = "last30days";public static inline var ALLTIME : String = "alltime";public static inline var NEWEST : String = "newest";private static var SECTION : String;private static var CREATEPRIVATELEADERBOARD : String;private static var LOADPRIVATELEADERBOARD : String;private static var SAVEANDLIST : String;private static var SAVE : String;private static var LIST : String;@:allow(playtomic)
    private static function Initialise(apikey : String) : Void
    {
        SECTION = Encode.MD5("leaderboards-" + apikey);CREATEPRIVATELEADERBOARD = Encode.MD5("leaderboards-createprivateleaderboard-" + apikey);LOADPRIVATELEADERBOARD = Encode.MD5("leaderboards-loadprivateleaderboard-" + apikey);SAVEANDLIST = Encode.MD5("leaderboards-saveandlist-" + apikey);SAVE = Encode.MD5("leaderboards-save-" + apikey);LIST = Encode.MD5("leaderboards-list-" + apikey);
    }  /**		 * Creates a private leaderboard for the user		 * @param	table		The name of the leaderboard		 * @param	permalink	The stem of the permalink, eg http://mywebsite.com/game.html?leaderboard=		 * @param	callback	Callback function to receive the data:  function(leaderboard:Leaderboard, response:Response)		 * @param	highest		The board's mode (true for highest, false for lowest)		 */  public static function CreatePrivateLeaderboard(table : String, permalink : String, callback : Function = null, highest : Bool = true) : Void
    {
        var postdata : Dynamic = {};Reflect.setField(postdata, "table", table);Reflect.setField(postdata, "highest", (highest) ? "y" : "n");Reflect.setField(postdata, "permalink", permalink);PRequest.Load(SECTION, CREATEPRIVATELEADERBOARD, CreatePrivateLeaderboardComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function CreatePrivateLeaderboardComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var leaderboard : PrivateLeaderboard = null;if (response.Success)
        {
            leaderboard = new PrivateLeaderboard(data.get("tableid"), data.get("name"), data.get("bitly"), data.get("permalink"), data.get("highest") == "true", data.get("realname"));
        }callback(leaderboard, response);postdata = postdata;
    }  /**		 * Loads a private leaderboard		 * @param	tableid		The id of the leaderboard		 * @param	callback	Callback function to receive the data:  function(leaderboard:Leaderboard, response:Response)		 */  public static function LoadPrivateLeaderboard(tableid : String, callback : Function = null) : Void
    {
        var postdata : Dynamic = {};Reflect.setField(postdata, "tableid", tableid);PRequest.Load(SECTION, LOADPRIVATELEADERBOARD, LoadPrivateLeaderboardComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LoadPrivateLeaderboardComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var leaderboard : PrivateLeaderboard = null;if (response.Success)
        {
            leaderboard = new PrivateLeaderboard(data.get("tableid"), data.get("name"), data.get("bitly"), data.get("permalink"), data.get("highest") == "true", data.get("realname"));
        }callback(leaderboard, response);postdata = postdata;
    }  /**		 * Attempts to retrieve a leaderboard id from the URL (eg http://url.com/game?leaderboard=xxxx)		 */  public static function GetLeaderboardFromUrl() : String
    {
        if (!ExternalInterface.available)
        {
            return null;
        }try
        {
            var url : String = Std.string(ExternalInterface.call("window.location.href.toString"));if (url.indexOf("?") == -1)
            {
                return null;
            }var leaderboardid : String = url.substring(url.indexOf("leaderboard=") + 12);if (leaderboardid.indexOf("&") > -1)
            {
                leaderboardid = leaderboardid.substring(0, leaderboardid.indexOf("&"));
            }if (leaderboardid.indexOf("#") > -1)
            {
                leaderboardid = leaderboardid.substring(0, leaderboardid.indexOf("#"));
            }return leaderboardid;
        }
        catch (s : Error)
        {
        }return null;
    }  /**		 * Performs a save and a list in a single request that returns the player's score and page of scores it occured on		 * @param	score		The player's score as a PlayerScore		 * @param	table		The name of the leaderboard		 * @param	callback	Callback function to receive the data:  function(scores:Array, numscores:int, response:Response)		 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards		 */  public static function SaveAndList(score : PlayerScore, table : String, callback : Function = null, options : Dynamic = null) : Void
    {
        if (options == null)
        {
            options = {};
        }var allowduplicates : Bool = (options.exists("allowduplicates")) ? Reflect.field(options, "allowduplicates") : false;var global : Bool = (options.exists("global")) ? Reflect.field(options, "global") : true;var highest : Bool = (options.exists("highest")) ? Reflect.field(options, "highest") : true;var mode : String = (options.exists("mode")) ? Reflect.field(options, "mode") : "alltime";var customfilters : Dynamic = (options.exists("customfilters")) ? Reflect.field(options, "customfilters") : { };var page : Int = (options.exists("page")) ? Reflect.field(options, "page") : 1;var perpage : Int = (options.exists("perpage")) ? Reflect.field(options, "perpage") : 20;var friendslist : Array<Dynamic> = (options.exists("friendslist")) ? Reflect.field(options, "friendslist") : new Array<Dynamic>();var postdata : Dynamic = {};  // save options  Reflect.setField(postdata, "url", Log.SourceUrl);Reflect.setField(postdata, "table", table);Reflect.setField(postdata, "highest", (highest) ? "y" : "n");Reflect.setField(postdata, "name", score.Name);Reflect.setField(postdata, "points", Std.string(score.Points));Reflect.setField(postdata, "allowduplicates", (allowduplicates) ? "y" : "n");var numfields : Int = 0;if (score.CustomData != null)
        {
            for (dkey in Reflect.fields(score.CustomData))
            {
                Reflect.setField(postdata, Std.string("ckey" + numfields), numfields);Reflect.setField(postdata, Std.string("cdata" + numfields), numfields);numfields++;
            }
        }Reflect.setField(postdata, "numfields", numfields);  // list options  Reflect.setField(postdata, "global", (global) ? "y" : "n");Reflect.setField(postdata, "mode", mode);Reflect.setField(postdata, "page", page);Reflect.setField(postdata, "perpage", perpage);var numfilters : Int = 0;if (customfilters != null)
        {
            for (fkey in Reflect.fields(customfilters))
            {
                Reflect.setField(postdata, Std.string("lkey" + numfilters), numfilters);Reflect.setField(postdata, Std.string("ldata" + numfilters), numfilters);numfilters++;
            }
        }Reflect.setField(postdata, "numfilters", numfilters);if (score.FBUserId != null && score.FBUserId != "")
        {
            if (friendslist.length > 0)
            {
                Reflect.setField(postdata, "friendslist", friendslist.join(","));
            }Reflect.setField(postdata, "fbuserid", score.FBUserId);
        }PRequest.Load(SECTION, SAVEANDLIST, SaveAndListComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function SaveAndListComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }if (response.Success)
        {
            ProcessScores(data, response, callback);
        }
        else
        {
            callback([], 0, response);
        }postdata = postdata;
    }  /**		 * Saves a user's score		 * @param	score		The player's score as a PlayerScore		 * @param	table		The name of the leaderboard		 * @param	callback	Callback function to receive the data:  function(score:PlayerScore, response:Response)		 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards		 */  public static function Save(score : PlayerScore, table : String, callback : Function = null, options : Dynamic = null) : Void
    {
        if (options == null)
        {
            options = {};
        }var allowduplicates : Bool = (options.exists("allowduplicates")) ? Reflect.field(options, "allowduplicates") : false;var highest : Bool = (options.exists("highest")) ? Reflect.field(options, "highest") : true;  // save the score  var s : String = Std.string(score.Points);if (s.indexOf(".") > -1)
        {
            s = s.substring(0, s.indexOf("."));
        }var postdata : Dynamic = {};var customfields : Int = 0;if (score.CustomData != null)
        {
            for (key in Reflect.fields(score.CustomData))
            {
                Reflect.setField(postdata, Std.string("ckey" + customfields), customfields);Reflect.setField(postdata, Std.string("cdata" + customfields), customfields);customfields++;
            }
        }Reflect.setField(postdata, "url", Log.BaseUrl);Reflect.setField(postdata, "table", table);Reflect.setField(postdata, "highest", (highest) ? "y" : "n");Reflect.setField(postdata, "name", score.Name);Reflect.setField(postdata, "points", s);Reflect.setField(postdata, "allowduplicates", (allowduplicates) ? "y" : "n");Reflect.setField(postdata, "auth", Encode.MD5(Log.BaseUrl + s));Reflect.setField(postdata, "fb", (score.FBUserId != "" && score.FBUserId != null) ? "y" : "n");Reflect.setField(postdata, "fbuserid", score.FBUserId);Reflect.setField(postdata, "customfields", customfields);PRequest.Load(SECTION, SAVE, SaveComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function SaveComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }data = data;postdata = postdata;callback(response);
    }  /**		 * Lists scores from a table		 * @param	table		The name of the leaderboard		 * @param	callback	Callback function to receive the data:  function(scores:Array, numscores:int, response:Response)		 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards		 */  public static function List(table : String, callback : Function, options : Dynamic = null) : Void
    //trace("List");
    {
        if (options == null)
        {
            options = {};
        }var global : Bool = (options.exists("global")) ? Reflect.field(options, "global") : true;var highest : Bool = (options.exists("highest")) ? Reflect.field(options, "highest") : true;var mode : String = (options.exists("mode")) ? Reflect.field(options, "mode") : "alltime";var customfilters : Dynamic = (options.exists("customfilters")) ? Reflect.field(options, "customfilters") : {};var page : Int = (options.exists("page")) ? Reflect.field(options, "page") : 1;var perpage : Int = (options.exists("perpage")) ? Reflect.field(options, "perpage") : 20;var facebook : Bool = (options.exists("facebook")) ? Reflect.field(options, "facebook") : false;var friendslist : Array<Dynamic> = (options.exists("friendslist")) ? Reflect.field(options, "friendslist") : new Array<Dynamic>();var postdata : Dynamic = {};var numfilters : Int = 0;for (key in Reflect.fields(customfilters))
        {
            Reflect.setField(postdata, Std.string("ckey" + numfilters), numfilters);Reflect.setField(postdata, Std.string("cdata" + numfilters), numfilters);numfilters++;
        }Reflect.setField(postdata, "url", ((global || Log.BaseUrl == null) ? "global" : Log.BaseUrl));Reflect.setField(postdata, "mode", mode);Reflect.setField(postdata, "page", page);Reflect.setField(postdata, "perpage", perpage);Reflect.setField(postdata, "highest", (highest) ? "y" : "n");Reflect.setField(postdata, "filters", numfilters);Reflect.setField(postdata, "table", table);if (facebook || friendslist.length > 0)
        {
            Reflect.setField(postdata, "friendslist", friendslist.join(","));trace(Reflect.field(postdata, "friendslist"));
        }  //trace("posting ");    //for(var x:String in postdata)    //	trace(x + ": " + postdata[x]);  PRequest.Load(SECTION, LIST, ListComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function ListComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }if (response.Success)
        {
            ProcessScores(data, response, callback);
        }
        else
        {
            callback([], 0, response);
        }postdata = postdata;
    }  /**		 * Processes the scores received from a List request		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 * @param	callback	The user's callback function		 */  private static function ProcessScores(data : FastXML, response : Response, callback : Function) : Void
    {
        var numscores : Int = as3hx.Compat.parseInt(data.get("numscores"));var results : Array<Dynamic> = new Array<Dynamic>();var entries : FastXMLList = data.get("score");var datestring : String;var year : Int;var month : Int;var day : Int;for (item in entries)
        {
            datestring = item.get("sdate");year = as3hx.Compat.parseInt(datestring.substring(datestring.lastIndexOf("/") + 1));month = as3hx.Compat.parseInt(datestring.substring(0, datestring.indexOf("/")));day = as3hx.Compat.parseInt(datestring.substring(datestring.indexOf("/") + 1).substring(0, 2));var score : PlayerScore = new PlayerScore();score.SDate = new Date(year, month - 1, day);score.RDate = item.get("rdate");score.Name = item.get("name");score.Points = item.get("points");score.Website = item.get("website");score.Rank = item.get("rank");if (item.get("submittedorbest") != null)
            {
                score.SubmittedOrBest = item.get("submittedorbest") == "true";
            }if (item.get("fbuserid") != null)
            {
                score.FBUserId = item.get("fbuserid");
            }if (item.get("custom") != null)
            {
                var custom : FastXMLList = item.get("custom");for (cfield/* AS3HX WARNING could not determine type for var: cfield exp: ECall(EField(EIdent(custom),children),[]) type: null */ in custom.node.children.innerData())
                {
                    score.CustomData[cfield.name()] = cfield.text();
                }
            }results.push(score);
        }callback(results, numscores, response);
    }

    public function new()
    {
    }
}