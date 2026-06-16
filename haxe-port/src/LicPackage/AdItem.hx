package licPackage;

import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.net.URLLoader;
import flash.utils.ByteArray;

/**
	 * ...
	 * @author Julian
	 */
class AdItem
{
    public var name : String;
    public var type : String;
    public var url : String;
    public var original_url : String;
    public var swfurl : String;
    public var active : Bool;
    public var customAd : MovieClip;
    public var urlLoaded : Bool;
    public var loader : Loader;
    public var fullScreen : Bool;
    
    public function CompareSwfUrlWith(adItem : AdItem) : Bool
    {
        if (swfurl != adItem.swfurl)
        {
            return false;
        }
        return true;
    }
    
    public function new(_name : String, _type : String, _url : String, _swfurl : String)
    {
        name = _name;
        type = _type;
        url = _url;
        original_url = url;
        swfurl = _swfurl;
        active = true;
        customAd = null;
        urlLoaded = false;
        loader = null;
        fullScreen = false;
    }
}


