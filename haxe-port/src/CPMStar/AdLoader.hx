package cPMStar;

import flash.display.*;
import flash.events.*;
import flash.net.*;
import flash.system.*;

class AdLoader extends flash.display.Sprite
{
    
    private var cpmstarLoader : Loader;
    private var contentspotid : String;
    public function new(contentspotid : String)
    {
        super();
        this.contentspotid = contentspotid;
        addEventListener(Event.ADDED, addedHandler);
    }
    private function addedHandler(event : Event) : Void
    {
        removeEventListener(Event.ADDED, addedHandler);
        Security.allowDomain("server.cpmstar.com");
        var cpmstarViewSWFUrl : String = "http://server.cpmstar.com/adviewas3.swf";
        var container : DisplayObjectContainer = parent;
        cpmstarLoader = new Loader();
        cpmstarLoader.contentLoaderInfo.addEventListener(Event.INIT, dispatchHandler);
        cpmstarLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, dispatchHandler);
        cpmstarLoader.load(new URLRequest(cpmstarViewSWFUrl + "?contentspotid=" + contentspotid));
        addChild(cpmstarLoader);
    }
    private function dispatchHandler(event : Event) : Void
    {
        dispatchEvent(event);
    }
}

