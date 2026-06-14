//  This file is part of the official Playtomic API for ActionScript 3 games.  //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import flash.utils.ByteArray;
import flash.events.Event;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Loader;

@:final class PlayerLevel
{public function new()
    {
        SDate = Date.now();RDate = "Just now";
    }public var LevelId : String;public var PlayerSource : String = "";public var PlayerId : String = "";public var PlayerName : String = "";public var Permalink : String;public var Name : String;public var Data : String;public var Thumb : Loader;public var Votes : Int;public var Starts : Int;public var Quits : Int;public var Retries : Int;public var Flags : Int;public var Wins : Int;public var Rating : Float;public var Score : Int;public var SDate : Date;public var RDate : String;public var CustomData : Dynamic = { };@:allow(playtomic)
    private function SetThumb(thumbdata : String) : Void
    {
        if (thumbdata == null || thumbdata == "")
        {
            return;
        }Thumb = new Loader();Thumb.loadBytes(Encode.Base64Decode(thumbdata));
    }public function Thumbnail() : String
    {
        return "http://g" + Log.GUID + ".api.playtomic.com/playerlevels/thumb.aspx?swfid=" + Log.SWFID + "&levelid=" + this.LevelId;
    }
}