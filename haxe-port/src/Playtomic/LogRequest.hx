  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

@:final class LogRequest
{private static var Pool : Array<Dynamic> = new Array<Dynamic>();private var _data : String = "";private var _hasView : Bool = false;private var _hasPlay : Bool = false;@:allow(playtomic)
    private var ready : Bool = false;  /**		 * Creates a log request or re-uses an old one from the pool		 */  @:allow(playtomic)
    private static function Create() : LogRequest
    {
        var request : LogRequest = (Pool.length > 0) ? try cast(Pool.pop(), LogRequest) catch(e:Dynamic) null : new LogRequest();request._data = "";request._hasView = false;request._hasPlay = false;request.ready = false;return request;
    }  /**		 * Adds queued events to the data		 */  @:allow(playtomic)
    private function MassQueue(data : Array<Dynamic>) : Void
    {
        var i : Int = as3hx.Compat.parseInt(data.length - 1);
        while (i > -1)
        {
            cast((data[i]), Queue);data.splice(i, 1);if (ready)
            {
                Send();var request : LogRequest = Create();request.MassQueue(data);return;
            }
            i--;
        }Log.LogQueue = this;
    }  /**		 * Queues a single event		 */  @:allow(playtomic)
    private function Queue(data : String) : Void
    {
        _data += ((_data == "") ? "" : "~") + data;if (_data.indexOf("v/") > -1)
        {
            _hasView = true;
        }if (_data.indexOf("p/") > -1)
        {
            _hasPlay = true;
        }if (_data.length > 300)
        {
            ready = true;
        }
    }  /**		 * Sends the data 		 */  public function Send() : Void
    {
        if (_data == "")
        {
            return;
        }PRequest.SendStatistics(Complete, "/tracker/q.aspx?q=" + _data + "&url=" + ((_hasView) ? Log.SourceUrl : Log.BaseUrl));
    }  /**		 * Increases views/plays counter if successful and stores the request for re-use		 */  private function Complete(success : Bool) : Void
    {
        if (success)
        {
            if (_hasView)
            {
                Log.IncreaseViews();
            }if (_hasPlay)
            {
                Log.IncreasePlays();
            }
        }Pool.push(this);
    }

    @:allow(playtomic)
    private function new()
    {
    }
}