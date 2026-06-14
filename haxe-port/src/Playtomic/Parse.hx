  //  Parse.com bridge for Playtomic Flash users    // -------------------------------------------------------------------------    //  Note:  This requires a Playtomic.com account AND a Parse.com account,    //  you will have to register at Parse and configure the settings in your    //  Playtomic dashboard.    //    //  http://parse.com/    //    //  If you are using Objective C or Android you should use the official    //  Parse SDKs available directly through Parse.com.    //    //    // -------------------------------------------------------------------------    //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import haxe.Constraints.Function;
@:final class Parse
{private static var SECTION : String;private static var SAVE : String;private static var DELETE : String;private static var LOAD : String;private static var FIND : String;@:allow(playtomic)
    private static function Initialise(apikey : String) : Void
    {
        SECTION = Encode.MD5("parse-" + apikey);SAVE = Encode.MD5("parse-save-" + apikey);DELETE = Encode.MD5("parse-delete-" + apikey);LOAD = Encode.MD5("parse-load-" + apikey);FIND = Encode.MD5("parse-find-" + apikey);
    }  /**		 * Creates or updates an object in your Parse.com database		 * @param	pobject		A ParseObject, if it has an objectId it will update otherwise save		 * @param	callback	Callback function to receive the data:  function(pobject:ParseObject, response:Response)		 */  public static function Save(pobject : PFObject, callback : Function = null) : Void
    {
        PRequest.Load(SECTION, SAVE, SaveComplete, callback, cast((pobject), ObjectPostData));
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function SaveComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var obj : FastXMLList = data.get("object");var item : FastXML = obj.get(0);var pobject : PFObject = new PFObject();pobject.ObjectId = item.get("id");pobject.ClassName = Reflect.field(postdata, "classname");pobject.Password = Reflect.field(postdata, "password");for (key in Reflect.fields(postdata))
        {
            if (key.indexOf("data") == 0)
            {
                pobject.Data[key.substring(4)] = Reflect.field(postdata, key);
            }
        }if (response.Success)
        {
            var object : FastXMLList = data.get("object");pobject.CreatedAt = cast((object.get("created")), DateParse);pobject.UpdatedAt = cast((object.get("created")), DateParse);
        }callback(pobject, response);
    }  /**		 * Deletes an object in your Parse.com database		 * @param	pobject		A ParseObject that must include the ObjectId		 * @param	callback	Callback function to receive the data:  function(response:Response)		 */  public static function Delete(pobject : PFObject, callback : Function = null) : Void
    {
        PRequest.Load(SECTION, DELETE, DeleteComplete, callback, cast((pobject), ObjectPostData));
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function DeleteComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }callback(response);data = data;  // just to hide unused var warning  postdata = postdata;
    }  /**		 * Loads a specific object from your Parse.com database		 * @param	pobject		A ParseObject that must include the ObjectId and className		 * @param	callback	Callback function to receive the data:  function(pobject:ParseObject, response:Response)		 */  public static function Load(pobjectid : String, classname : String, callback : Function = null) : Void
    {
        var pobject : PFObject = new PFObject();pobject.ObjectId = pobjectid;pobject.ClassName = classname;PRequest.Load(SECTION, LOAD, LoadComplete, callback, cast((pobject), ObjectPostData));
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function LoadComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var pobject : PFObject = new PFObject();pobject.ObjectId = Reflect.field(postdata, "objectid");pobject.ClassName = Reflect.field(postdata, "classname");if (response.Success)
        {
            var object : FastXMLList = data.get("object");pobject.CreatedAt = cast((object.get("created")), DateParse);pobject.UpdatedAt = cast((object.get("updated")), DateParse);if (object.node.contains.innerData("fields"))
            {
                var fields : FastXMLList = object.get("fields");for (field/* AS3HX WARNING could not determine type for var: field exp: ECall(EField(EIdent(fields),children),[]) type: null */ in fields.node.children.innerData())
                {
                    pobject[field.name] = field.text();
                }
            }
        }callback(pobject, response);
    }  /**		 * Finds objects matching the criteria in your ParseQuery		 * @param	pquery		A ParseQuery object		 * @param	callback	Callback function to receive the data:  function(objects:Array, response:Response)		 */  public static function Find(pquery : PFQuery, callback : Function = null) : Void
    {
        var postdata : Dynamic = {};Reflect.setField(postdata, "classname", pquery.ClassName);Reflect.setField(postdata, "limit", pquery.Limit);Reflect.setField(postdata, "order", (pquery.Order != null && pquery.Order != "") ? pquery.Order : "created_at");for (key in Reflect.fields(pquery.WhereData))
        {
            Reflect.setField(postdata, Std.string("data" + key), key);
        }PRequest.Load(SECTION, FIND, FindComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	response	The response from the server		 */  private static function FindComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var objs : Array<Dynamic> = new Array<Dynamic>();if (response.Success)
        {
            var objects : FastXMLList = data.get("objects");for (object/* AS3HX WARNING could not determine type for var: object exp: ECall(EField(EIdent(objects),children),[]) type: null */ in objects.node.children.innerData())
            {
                var pobject : PFObject = new PFObject();pobject.ObjectId = Reflect.field(object, "id");pobject.CreatedAt = cast((Reflect.field(object, "created")), DateParse);pobject.UpdatedAt = cast((Reflect.field(object, "updated")), DateParse);if (object.contains("fields"))
                {
                    var fields : FastXMLList = Reflect.field(object, "fields");for (field/* AS3HX WARNING could not determine type for var: field exp: ECall(EField(EIdent(fields),children),[]) type: null */ in fields.node.children.innerData())
                    {
                        pobject[field.name] = field.text();
                    }
                }objs.push(pobject);
            }
        }callback(objs, response);postdata = postdata;
    }  /**		 * Turns a ParseObject into data to be POST'd for saving, finding 		 * @param	pobject		The ParseObject		 */  private static function ObjectPostData(pobject : PFObject) : Dynamic
    {
        var postobject : Dynamic = {};Reflect.setField(postobject, "classname", pobject.ClassName);Reflect.setField(postobject, "id", ((pobject.ObjectId == null) ? "" : pobject.ObjectId));Reflect.setField(postobject, "password", ((pobject.Password == null) ? "" : pobject.Password));for (key in Reflect.fields(pobject.Data))
        {
            Reflect.setField(postobject, Std.string("data" + key), key);
        }return postobject;
    }  /**		 * Converts the server's MM/dd/yyyy hh:mm:ss into a Flash Date		 * @param	date		The date from the XML		 */  private static function DateParse(date : String) : Date
    {
        var parts : Array<Dynamic> = date.split(" ");var dateparts : Array<Dynamic> = (Std.string(parts[0])).split("/");var timeparts : Array<Dynamic> = (Std.string(parts[1])).split(":");var day : Int = as3hx.Compat.parseInt(dateparts[1]);var month : Int = as3hx.Compat.parseInt(dateparts[0]);var year : Int = as3hx.Compat.parseInt(dateparts[2]);var hours : Int = as3hx.Compat.parseInt(timeparts[0]);var minutes : Int = as3hx.Compat.parseInt(timeparts[1]);var seconds : Int = as3hx.Compat.parseInt(timeparts[2]);return new Date(Date.UTC(year, month, day, hours, minutes, seconds));
    }

    public function new()
    {
    }
}