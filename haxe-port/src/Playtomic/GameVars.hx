  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import haxe.Constraints.Function;
@:final class GameVars
{private static var SECTION : String;private static var LOAD : String;private static var LOADSINGLE : String;@:allow(playtomic)
    private static function Initialise(apikey : String) : Void
    {
        SECTION = Encode.MD5("gamevars-" + apikey);LOAD = Encode.MD5("gamevars-load-" + apikey);LOADSINGLE = Encode.MD5("gamevars-loadsingle-" + apikey);
    }  /**		 * Loads your GameVars 		 * @param	callback	Your function to receive the data:  callback(gamevars:Object, response:Response)		 */  public static function Load(callback : Function) : Void
    {
        PRequest.Load(SECTION, LOAD, LoadComplete, callback, null);
    }  /**		 * Loads a single GameVar		 * @param	name	The name of the var you want to laod		 * @param	callback	Your function recieve the data:  callback(gamevar:Object, response:Response)		 */  public static function LoadSingle(name : String, callback : Function) : Void
    {
        var postdata : Dynamic = {};Reflect.setField(postdata, "name", name);PRequest.Load(SECTION, LOADSINGLE, LoadComplete, callback, postdata);
    }  /**		 * Processes the response received from the server, returns the data and response to the user's callback		 * @param	callback	The user's callback function		 * @param	postdata	The data that was posted		 * @param	data		The XML returned from the server		 * @param	status		The request status returned from the esrver (1 for success)		 * @param	errorcode	The errorcode returned from the server (0 for none)		 */  private static function LoadComplete(callback : Function, postdata : Dynamic, data : FastXML = null, response : Response = null) : Void
    {
        if (callback == null)
        {
            return;
        }var result : Dynamic = {};if (response.Success)
        {
            var entries : FastXMLList = data.get("gamevar");var name : String;var value : String;for (item in entries)
            {
                name = item.get("name");value = item.get("value");Reflect.setField(result, name, value);
            }
        }postdata = postdata;callback(result, response);
    }

    public function new()
    {
    }
}