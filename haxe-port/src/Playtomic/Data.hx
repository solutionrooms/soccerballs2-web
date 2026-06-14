  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import haxe.Constraints.Function;
@:final class Data
{private static var SECTION : String;private static var VIEWS : String;private static var PLAYS : String;private static var PLAYTIME : String;private static var CUSTOMMETRIC : String;private static var LEVELCOUNTERMETRIC : String;private static var LEVELRANGEDMETRIC : String;private static var LEVELAVERAGEMETRIC : String;@:allow(playtomic)
    private static function Initialise(apikey : String) : Void
    {
        SECTION = Encode.MD5("data-" + apikey);VIEWS = Encode.MD5("data-views-" + apikey);PLAYS = Encode.MD5("data-plays-" + apikey);PLAYTIME = Encode.MD5("data-playtime-" + apikey);CUSTOMMETRIC = Encode.MD5("data-custommetric-" + apikey);LEVELCOUNTERMETRIC = Encode.MD5("data-levelcountermetric-" + apikey);LEVELRANGEDMETRIC = Encode.MD5("data-levelrangedmetric-" + apikey);LEVELAVERAGEMETRIC = Encode.MD5("data-levelaveragemetric-" + apikey);
    }  /**		 * Loads the views your game logged on a day or all time		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function Views(callback : Function, options : Dynamic = null) : Void
    {
        General(VIEWS, "Views", callback, options);
    }  /**		 * Loads the plays your game logged on a day or all time		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function Plays(callback : Function, options : Dynamic = null) : Void
    {
        General(PLAYS, "Plays", callback, options);
    }  /**		 * Loads the playtime your game logged on a day or all time		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function PlayTime(callback : Function, options : Dynamic = null) : Void
    {
        General(PLAYTIME, "Playtime", callback, options);
    }  /**		 * Passes a general request on		 * @param	action		The action on the server		 * @param	type		The type of data being requested		 * @param	callback	The user's callback function		 * @param	options		Object with day, month, year properties or null for all time		 */  private static function General(action : String, type : String, callback : Function, options : Dynamic) : Void
    {
        if (options == null)
        {
            options = {};
        }var postdata : Dynamic = {};Reflect.setField(postdata, "type", type);Reflect.setField(postdata, "day", (options.exists("day")) ? Reflect.field(options, "day") : 0);Reflect.setField(postdata, "month", (options.exists("month")) ? Reflect.field(options, "month") : 0);Reflect.setField(postdata, "year", (options.exists("year")) ? Reflect.field(options, "year") : 0);PRequest.Load(SECTION, action, GeneralComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function GeneralComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success == 1)
        {
            Reflect.setField(result, "Name", Reflect.field(postdata, "type"));Reflect.setField(result, "Day", Reflect.field(postdata, "day"));Reflect.setField(result, "Month", Reflect.field(postdata, "month"));Reflect.setField(result, "Year", Reflect.field(postdata, "year"));Reflect.setField(result, "Value", as3hx.Compat.parseInt(data.get("value")));
        }callback(result, response);
    }  /**		 * Loads a custom metric's data for a date or all time		 * @param	metric		The name of your metric		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function CustomMetric(metric : String, callback : Function, options : Dynamic = null) : Void
    {
        if (options == null)
        {
            options = {};
        }var postdata : Dynamic = {};Reflect.setField(postdata, "metric", metric);Reflect.setField(postdata, "day", (options.exists("day")) ? Reflect.field(options, "day") : 0);Reflect.setField(postdata, "month", (options.exists("month")) ? Reflect.field(options, "month") : 0);Reflect.setField(postdata, "year", (options.exists("year")) ? Reflect.field(options, "year") : 0);PRequest.Load(SECTION, CUSTOMMETRIC, CustomMetricComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function CustomMetricComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success)
        {
            Reflect.setField(result, "Name", "CustomMetric");Reflect.setField(result, "Metric", Reflect.field(postdata, "metric"));Reflect.setField(result, "Day", Reflect.field(postdata, "day"));Reflect.setField(result, "Month", Reflect.field(postdata, "month"));Reflect.setField(result, "Year", Reflect.field(postdata, "year"));Reflect.setField(result, "Value", as3hx.Compat.parseInt(data.get("value")));
        }callback(result, response);
    }  /**		 * Loads a level counter metric's data for a level on a date or all time		 * @param	metric		The name of your metric		 * @param	level		The level number (integer) or name (string)		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function LevelCounterMetric(metric : String, level : Dynamic, callback : Function, options : Dynamic = null) : Void
    {
        LevelMetric(LEVELCOUNTERMETRIC, metric, level, LevelCounterMetricComplete, callback, options);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LevelCounterMetricComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success)
        {
            Reflect.setField(result, "Name", "LevelAverageMetric");Reflect.setField(result, "Metric", Reflect.field(postdata, "metric"));Reflect.setField(result, "Level", Reflect.field(postdata, "level"));Reflect.setField(result, "Day", Reflect.field(postdata, "day"));Reflect.setField(result, "Month", Reflect.field(postdata, "month"));Reflect.setField(result, "Year", Reflect.field(postdata, "year"));Reflect.setField(result, "Value", as3hx.Compat.parseInt(data.get("value")));
        }callback(result, response);
    }  /**		 * Loads a level ranged metric's data for a level on a date or all time		 * @param	metric		The name of your metric		 * @param	level		The level number (integer) or name (string)		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function LevelRangedMetric(metric : String, level : Dynamic, callback : Function, options : Dynamic = null) : Void
    {
        LevelMetric(LEVELRANGEDMETRIC, metric, level, LevelRangedMetricComplete, callback, options);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LevelRangedMetricComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success)
        {
            Reflect.setField(result, "Name", "LevelAverageMetric");Reflect.setField(result, "Metric", Reflect.field(postdata, "metric"));Reflect.setField(result, "Level", Reflect.field(postdata, "level"));Reflect.setField(result, "Day", Reflect.field(postdata, "day"));Reflect.setField(result, "Month", Reflect.field(postdata, "month"));Reflect.setField(result, "Year", Reflect.field(postdata, "year"));var values : Array<Dynamic> = new Array<Dynamic>();var list : FastXMLList = data.get("value");var n : FastXML;for (n in list)
            {
                values.push({
                            TrackValue : as3hx.Compat.parseInt(n.att.trackvalue),
                            Value : as3hx.Compat.parseInt(n)
                        });
            }Reflect.setField(result, "Values", values);
        }callback(result, response);
    }  /**		 * Loads a level average metric's data for a level on a date or all time		 * @param	metric		The name of your metric		 * @param	level		The level number (integer) or name (string)		 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);		 * @param	options		Object with day, month, year properties or null for all time		 */  public static function LevelAverageMetric(metric : String, level : Dynamic, callback : Function, options : Dynamic = null) : Void
    {
        LevelMetric(LEVELAVERAGEMETRIC, metric, level, LevelAverageMetricComplete, callback, options);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LevelAverageMetricComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success)
        {
            Reflect.setField(result, "Name", "LevelAverageMetric");Reflect.setField(result, "Metric", Reflect.field(postdata, "metric"));Reflect.setField(result, "Level", Reflect.field(postdata, "level"));Reflect.setField(result, "Day", Reflect.field(postdata, "day"));Reflect.setField(result, "Month", Reflect.field(postdata, "month"));Reflect.setField(result, "Year", Reflect.field(postdata, "year"));Reflect.setField(result, "Min", as3hx.Compat.parseInt(data.get("min")));Reflect.setField(result, "Max", as3hx.Compat.parseInt(data.get("max")));Reflect.setField(result, "Average", as3hx.Compat.parseInt(data.get("average")));Reflect.setField(result, "Total", as3hx.Compat.parseFloat(data.get("total")));
        }callback(result, response);
    }  /**		 * Passes a level metric request on		 * @param	action		The action on the server		 * @param	metric		The metric		 * @param	level		The level number or name as a string		 * @param	complete	The complete handler		 * @param	callback	The user's callback function		 * @param	options		Object with day, month, year properties or null for all time		 */  private static function LevelMetric(action : String, metric : String, level : String, complete : Function, callback : Function, options : Dynamic) : Void
    {
        if (options == null)
        {
            options = {};
        }var postdata : Dynamic = {};Reflect.setField(postdata, "metric", metric);Reflect.setField(postdata, "level", level);Reflect.setField(postdata, "day", (options.exists("day")) ? Reflect.field(options, "day") : 0);Reflect.setField(postdata, "month", (options.exists("month")) ? Reflect.field(options, "month") : 0);Reflect.setField(postdata, "year", (options.exists("year")) ? Reflect.field(options, "year") : 0);PRequest.Load(SECTION, action, complete, callback, postdata);
    }

    public function new()
    {
    }
}