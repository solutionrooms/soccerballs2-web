package licPackage;

import haxe.Constraints.Function;

/**
	 * ...
	 * @author ...
	 */
class LicSku
{
    public var secondaryIntroFunction : Function;
    public var introFunction : Function;
    public var id : Int = 0;
    public var name : String;
    public var sitelocks : Array<Dynamic>;
    public var blackList : Array<Dynamic>;
    public var adtype : Int = 0;
    public var mainLogoName : String;
    public var mainLogoLinkURL : String;
    public var facebookLinkURL : String;
    public var prequelLinkURL : String;
    public var scaleIntroToStage : Bool;
    public var allowAuthorLink : Bool;
    public var showMoreGamesButton : Bool;
    public var initFunction : Function;
    public var allowIntersitialAd : Bool;
    public var introName : String;
    public var introFPS : Int = 0;
    public var secondaryIntroName : String;
    public var secondaryIntroLinkURL : String;
    public var linkURL : String;
    public var walkthroughURL : String;
    public var playWithScoresURL : String;
    public var allowRemoteAdLoading : Bool;
    public var allowOtherGames : Bool;
    public var skipPreloaderContinueButton : Bool;
    public var realSiteLock : Bool;
    public var downloadLinkURL : String;
    
    
    public function new(_id : Int, _name : String)
    {
        id = _id;
        name = _name;
        introFunction = null;
        secondaryIntroFunction = null;
        sitelocks = [];
        blackList = [];
        adtype = 0;
        mainLogoName = "";
        facebookLinkURL = "";
        prequelLinkURL = "";
        scaleIntroToStage = false;
        allowAuthorLink = true;
        showMoreGamesButton = true;
        initFunction = null;
        allowIntersitialAd = false;
        introName = "";
        secondaryIntroName = "";
        secondaryIntroLinkURL = "";
        linkURL = "";
        walkthroughURL = "";
        playWithScoresURL = "";
        mainLogoLinkURL = "";
        allowRemoteAdLoading = false;
        allowOtherGames = false;
        introFPS = Std.int(Defs.fps);
        skipPreloaderContinueButton = false;
        realSiteLock = false;
        downloadLinkURL = "";
    }
    
    public function AddSiteLock(s : String, fullDomain : Bool = false) : Void
    {
        sitelocks.push(s);
    }
    public function AddBlackList(s : String, fullDomain : Bool = false) : Void
    {
        blackList.push(s);
    }
}


