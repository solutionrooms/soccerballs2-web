  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import flash.errors.Error;
import flash.net.URLRequest;

@:final class Link
{private static var Clicks : Array<Dynamic> = new Array<Dynamic>();  /**		 * Attempts to open a URL, tracking the unique/total/failed clicks the user experiences.		 * @param	url			The url to open		 * @param	name		A name for the URL (eg splashscreen)		 * @param	group		The group for the reports (eg sponsor links)		 * @param	options		Object with day, month, year properties or null for all time		 * @param	trackonly	Do not try and open the link, just log the click		 * @param	target		The target to open the link in (usually 'blank' the default)		 */  public static function Open(url : String, name : String, group : String, trackonly : Bool = false, target : String = "_blank") : Bool
    {
        var unique : Int = 0;var bunique : Int = 0;var total : Int = 0;var btotal : Int = 0;var fail : Int = 0;var bfail : Int = 0;var key : String = url + "." + name;var result : Bool;var baseurl : String = url;baseurl = StringTools.replace(baseurl, "http://", "");if (baseurl.indexOf("/") > -1)
        {
            baseurl = baseurl.substring(0, baseurl.indexOf("/"));
        }if (baseurl.indexOf("?") > -1)
        {
            baseurl = baseurl.substring(0, baseurl.indexOf("?"));
        }baseurl = "http://" + baseurl + "/";var baseurlname : String = baseurl;if (baseurlname.indexOf("//") > -1)
        {
            baseurlname = baseurlname.substring(baseurlname.indexOf("//") + 2);
        }baseurlname = StringTools.replace(baseurlname, "www.", "");if (baseurlname.indexOf("/") > -1)
        {
            baseurlname = baseurlname.substring(0, baseurlname.indexOf("/"));
        }try
        {
            if (!trackonly)
            {
                flash.Lib.getURL(new URLRequest(url), target);
            }if (Lambda.indexOf(Clicks, key) > -1)
            {
                total = 1;
            }
            else
            {
                total = 1;unique = 1;Clicks.push(key);
            }if (Lambda.indexOf(Clicks, baseurlname) > -1)
            {
                btotal = 1;
            }
            else
            {
                btotal = 1;bunique = 1;Clicks.push(baseurlname);
            }result = true;
        }
        catch (err : Error)
        {
            fail = 1;bfail = 1;result = false;
        }Log.Link(baseurl, baseurlname.toLowerCase(), "DomainTotals", bunique, btotal, bfail);Log.Link(url, name, group, unique, total, fail);Log.ForceSend();return result;
    }

    public function new()
    {
    }
}