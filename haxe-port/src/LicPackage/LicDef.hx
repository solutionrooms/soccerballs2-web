package licPackage;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.net.URLRequest;

/**
	 * ...
	 * @author Julian
	 */
class LicDef
{
    
    public static inline var LICENSOR_DEVELOPMENT : Int = 0;
    public static inline var LICENSOR_NOBRANDING : Int = 1;
    public static inline var LICENSOR_LONGANIMALS : Int = 2;
    public static inline var LICENSOR_LONGANIMALS_SITELOCKED : Int = 3;
    public static inline var LICENSOR_ROBOTJAM : Int = 4;
    public static inline var LICENSOR_TURBONUKE : Int = 5;
    public static inline var LICENSOR_KONGREGATE : Int = 6;
    public static inline var LICENSOR_KONGREGATE_ONSITE : Int = 7;
    public static inline var LICENSOR_ANDKON : Int = 8;
    public static inline var LICENSOR_ARMORGAMES : Int = 9;
    public static inline var LICENSOR_ARMORGAMES_VIRAL : Int = 10;
    public static inline var LICENSOR_MOUSEBREAKER : Int = 11;
    public static inline var LICENSOR_ADDICTINGGAMES : Int = 12;
    public static inline var LICENSOR_COOLIFIED : Int = 13;
    public static inline var LICENSOR_YEPI : Int = 14;
    public static inline var LICENSOR_PANDAZONE : Int = 15;
    public static inline var LICENSOR_KIZI : Int = 16;
    public static inline var LICENSOR_HOODAMATH : Int = 17;
    public static inline var LICENSOR_BEGAMER : Int = 18;
    
    public static inline var ADTYPE_NONE : Int = 0;
    public static inline var ADTYPE_MOCHI : Int = 1;
    public static inline var ADTYPE_MOCHI_VC : Int = 2;
    public static inline var ADTYPE_CPMSTAR : Int = 3;
    public static inline var ADTYPE_EPICGAMEADS : Int = 4;
    
    
    public static var MochiAdID : String = "e5813d4154e50e8f";
    public static var MochiAdRes : String = "700x525";
    
    public static var primary_sponsor : Int = LICENSOR_KONGREGATE;
    
    public static var licensor : Int = LICENSOR_TURBONUKE;
    
    public static var armorHighScore_devKey : String = "57e6ffa35f343197fbd276da0a94ccbb";
    public static var armorHighScore_gameKey : String = "basketballs-level-pack";
    
    public static var mouseBreaker_hiscore_url : String = "http://www.mousebreaker.com/games/redcardrampage2/highscores_redcardrampage2.php";
    
    public static var newgrounds_id0 : String = "21399:JE19X8KX";
    public static var newgrounds_id1 : String = "cZ5A6UCtOgci9gls5AFEw2b3RbqbY2lw";
    
    
    public static var Playtomic_id : Int = 939551;
    public static var Playtomic_GUID : String = "d2ed3deb2c9042d5";
    public static var Playtomic_APIKey : String = "c42a42183ebc4abf8ee44b5bc93eff";
    
    
    
    public static var referralName : String = "soccerballs2";
    public static var referralString : String = "?haref=soccerballs2&src=spon&cm=soccerballs2";
    
    
    public static var authorLinks : Array<Dynamic> = new Array<Dynamic>();
    
    
    public static var CPMStarContentSpotIDs : Array<Dynamic> = new Array<Dynamic>();
    public static var CPMStarIntersitialsSpotIDs : Array<Dynamic> = new Array<Dynamic>();
    // Turbonuke
    public static var CPMStarFixedTime : Int = 10;
    
    public static var localTest : Bool = false;
    
    public static var domain : String;
    public static var stg : MovieClip;
    public static var kongregateEmbedFlag : Bool = true;
    
    public function new()
    {
    }
    
    public static function GetCurrentSku() : LicSku
    {
        return cast((licensor), GetSku);
    }
    
    public static function GetSku(skuID : Int) : LicSku
    {
        for (sku/* AS3HX WARNING could not determine type for var: sku exp: EIdent(skus) type: null */ in skus)
        {
            if (sku.id == skuID)
            {
                return sku;
            }
        }
        trace("GetSku invalid SKU: " + skuID);
        return null;
    }
    
    private static function IsOnCorrectSite() : Bool
    {
        if (false)
        {
            return true;
        }
        if (localTest == true)
        {
            return true;
        }
        var sku : LicSku = cast((licensor), GetSku);
        if (sku.sitelocks.length == 0)
        {
            return true;
        }
        for (s/* AS3HX WARNING could not determine type for var: s exp: EField(EIdent(sku),sitelocks) type: null */ in sku.sitelocks)
        {
            if (s == domain)
            {
                return true;
            }
        }
        return false;
    }
    
    public static function GetLicensor() : Int
    {
        return licensor;
    }
    
    public static function InitFromPreloader(_stg : MovieClip)
    {
        InitSkus();
        stg = _stg;
        domain = GetDomain();
        kongregateEmbedFlag = stg.stage.loaderInfo.parameters.kongregate;
        
        SkuModify();
    }
    
    
    public static function GetStage() : MovieClip
    {
        return stg;
    }
    public static function GetDomain() : String
    {
        var url : String = stg.loaderInfo.url;  //this is the magic _url successor  
        var urlStart : Float = url.indexOf("://") + 3;
        var urlEnd : Float = url.indexOf("/", urlStart);
        var dom : String = url.substring(urlStart, urlEnd);
        var LastDot : Float = dom.lastIndexOf(".") - 1;
        var domEnd : Float = dom.lastIndexOf(".", LastDot) + 1;
        dom = dom.substring(domEnd, dom.length);
        return dom;
    }
    
    private static function SkuModify() : Void
    {
        if (LicDef.localTest == true)
        {
            return;
        }
        
        if (licensor == LICENSOR_BEGAMER)
        {
            if (domain == "begamer.com")
            {
                return;
            }
            if (domain == "turbonuke.com")
            {
                return;
            }
            GetStage().x = -1000;
        }
        
        
        if (licensor == LICENSOR_KONGREGATE && IsAtKongregate())
        {
            licensor = LICENSOR_KONGREGATE_ONSITE;
        }
        
        if (IsOnCorrectSite() == false)
        {
            licensor = primary_sponsor;
        }
        
        
        if (false == false)
        {
            if (GetCurrentSku().realSiteLock)
            {
                if (GetDomain() != "kongregate.com" && GetDomain() != "turbonuke.com")
                {
                    do
                    {
                    }
                    while ((1));
                }
            }
        }
    }
    
    public static function AreOtherGamesAdsAllowed() : Bool
    {
        return GetCurrentSku().allowOtherGames;
    }
    
    public static function IsRemoteAdLoadingAllowed() : Bool
    {
        return GetCurrentSku().allowRemoteAdLoading;
    }
    
    public static function IsAtKongregate() : Bool
    {
        if (domain == "kongregate.com" && kongregateEmbedFlag)
        {
            return true;
        }
        return false;
    }
    
    private static var skus : Array<Dynamic>;
    
    public static function InitSkus() : Void
    {
        skus = new Array<Dynamic>();
        var sku : LicSku;
        
        sku = new LicSku(LICENSOR_BEGAMER, "Begamer");
        sku.introName = "Intro_Begamer";
        sku.mainLogoName = "";
        sku.introFPS = 30;
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_DEVELOPMENT, "Development");
        sku.AddSiteLock("longanimalsgames.com");
        sku.AddSiteLock("flashgamelicense.com");
        sku.AddSiteLock("turbonuke.com");
        sku.AddSiteLock("");
        
        
        sku.allowOtherGames = true;
        sku.showMoreGamesButton = true;
        sku.skipPreloaderContinueButton = true;
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_PANDAZONE, "PandaZone");
        sku.AddSiteLock("longanimalsgames.com");
        sku.AddSiteLock("pandazone.com");
        sku.showMoreGamesButton = false;
        sku.mainLogoName = "pandazone";
        sku.linkURL = "http://www.pandazone.com";
        sku.allowAuthorLink = false;
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_HOODAMATH, "Hoodamath");
        sku.introName = "Intro_Hoodamath";
        sku.mainLogoName = "hoodamath";
        sku.linkURL = "http://www.hoodamath.com";
        sku.AddSiteLock("hoodamath.com");
        sku.allowAuthorLink = false;
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_TURBONUKE, "TurboNUKE");
        sku.AddSiteLock("turbonuke.com");
        sku.introName = "Intro_TurboNuke";
        sku.mainLogoName = "turbonuke";
        sku.linkURL = "http://www.turbonuke.com";
        sku.prequelLinkURL = "http://www.turbonuke.com/games.php?game=basketballs";
        sku.walkthroughURL = "http://www.turbonuke.com/walkthrough.php?game=basketballslevelpack";
        skus.push(sku);
        sku = new LicSku(LICENSOR_KONGREGATE, "Kongregate");
        
        sku.introName = "Intro_Kongregate";
        sku.introFPS = 60;
        sku.mainLogoName = "kongregate";
        sku.linkURL = "http://www.kongregate.com";
        sku.adtype = ADTYPE_CPMSTAR;
        sku.allowIntersitialAd = false;
        
        sku.prequelLinkURL = "http://www.kongregate.com/games/turboNuke/soccer-balls";
        
        sku.playWithScoresURL = "http://www.kongregate.com/games/TurboNuke/soccer-balls-2";
        
        sku.facebookLinkURL = "http://www.kongregate.com/pages/fb-redirect?haref=soccerballs2&src=spon&cm=soccerballs2&subs=FBPage";
        sku.downloadLinkURL = "http://www.kongregate.com/games_for_your_site";
        
        sku.walkthroughURL = "http://www.kongregate.com/games/TurboNuke/soccer-balls-2-walkthrough";
        
        sku.secondaryIntroName = "Intro_TurboNuke";
        sku.secondaryIntroLinkURL = "http://www.turbonuke.com";
        sku.allowRemoteAdLoading = true;
        
        sku.allowOtherGames = true;
        sku.allowAuthorLink = true;
        
        
        if (Game.usedebug)
        {
            sku.secondaryIntroName = "";
            sku.secondaryIntroLinkURL = "";
            sku.adtype = ADTYPE_NONE;
            sku.introName = "";
        }
        
        if (false)
        {
            sku.secondaryIntroName = "";
            sku.secondaryIntroLinkURL = "";
            sku.adtype = ADTYPE_NONE;
            sku.introName = "";
            sku.skipPreloaderContinueButton = true;
        }
        
        
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_KONGREGATE_ONSITE, "Kongregate OnSite");
        
        sku.introName = "Intro_Kongregate";
        sku.mainLogoName = "kongregate";
        
        sku.prequelLinkURL = "http://www.kongregate.com/games/turboNuke/soccer-balls";
        
        sku.facebookLinkURL = "http://www.kongregate.com/pages/fb-redirect?haref=soccerballs2&src=spon&cm=soccerballs2&subs=FBPage";
        
        sku.downloadLinkURL = "http://www.kongregate.com/games_for_your_site";
        
        sku.walkthroughURL = "http://www.kongregate.com/games/TurboNuke/soccer-balls-2-walkthrough";
        
        sku.allowIntersitialAd = false;
        
        sku.allowOtherGames = true;
        sku.allowAuthorLink = true;
        sku.allowRemoteAdLoading = false;
        
        skus.push(sku);
        sku = new LicSku(LICENSOR_ANDKON, "Andkon");
        sku.AddSiteLock("andkon.com");
        sku.introName = "Intro_Andkon";
        sku.mainLogoName = "andkon";
        sku.linkURL = "http://www.andkon.com/arcade/";
        sku.walkthroughURL = "walkthrough.html";
        sku.allowAuthorLink = false;
        sku.allowRemoteAdLoading = false;
        sku.allowOtherGames = false;
        sku.allowIntersitialAd = false;
        skus.push(sku);
        
        sku = new LicSku(LICENSOR_ARMORGAMES, "Armor Games");
        sku.AddSiteLock("armorgames.com");
        sku.AddSiteLock("longanimalsgames.com");
        sku.introName = "Intro_ArmorGames";
        sku.adtype = ADTYPE_NONE;
        sku.mainLogoName = "armorGames";
        sku.linkURL = "http://armor.ag/MoreGames";
        sku.facebookLinkURL = "http://plus.google.com/u/0/104425856972539712808/posts";
        sku.prequelLinkURL = "http://armorgames.com/play/6106/soccer-balls";
        sku.allowAuthorLink = true;
        sku.skipPreloaderContinueButton = true;
        skus.push(sku);
        
        
        sku = new LicSku(LICENSOR_YEPI, "Yepi");
        sku.AddSiteLock("twizl.com");
        sku.AddSiteLock("yepi.com");
        sku.AddSiteLock("bgames.com");
        sku.AddSiteLock("fishflashgames.com");
        sku.mainLogoName = "yepi";
        sku.introName = "Intro_Yepi";
        sku.adtype = ADTYPE_NONE;
        sku.allowAuthorLink = false;
        skus.push(sku);
        
        
        sku = new LicSku(LICENSOR_COOLIFIED, "Coolified");
        sku.AddSiteLock("coolifiedgames.com");
        sku.AddSiteLock("longanimalsgames.com");
        sku.introName = "Intro_Coolified";
        sku.adtype = ADTYPE_NONE;
        sku.allowAuthorLink = false;
        skus.push(sku);
        
        
        sku = new LicSku(LICENSOR_NOBRANDING, "No branding");
        skus.push(sku);
        sku = new LicSku(LICENSOR_KIZI, "Kizi Sitelock");
        sku.AddSiteLock("kizi.com");
        sku.skipPreloaderContinueButton = true;
        sku.allowAuthorLink = false;
        
        skus.push(sku);
        sku = new LicSku(LICENSOR_MOUSEBREAKER, "MouseBreaker");
        sku.AddSiteLock("mousebreaker.com");
        sku.mainLogoName = "mousebreaker";
        sku.showMoreGamesButton = false;
        sku.introName = "Intro_MouseBreaker";
        sku.allowAuthorLink = false;
        sku.walkthroughURL = "http://www.mousebreaker.com/games/redcardrampage2walkthrough/playgame";
        sku.prequelLinkURL = "http://www.mousebreaker.com/games/redcardrampage";
        
        sku.introFPS = 30;
        
        skus.push(sku);
        sku = new LicSku(LICENSOR_ADDICTINGGAMES, "Addicting Games");
        sku.introName = "Intro_AddictingGames";
        sku.mainLogoName = "addictingGames";
        sku.linkURL = "http://www.addictinggames.com";
        sku.AddSiteLock("addictinggames.com");
        skus.push(sku);
        sku = new LicSku(LICENSOR_LONGANIMALS, "LongAnimals");
        sku.adtype = ADTYPE_CPMSTAR;
        sku.mainLogoName = "longAnimals";
        sku.linkURL = "http://www.longanimalsgames.com";
        skus.push(sku);
        sku = new LicSku(LICENSOR_LONGANIMALS_SITELOCKED, "LongAnimalsSitelocked");
        sku.AddSiteLock("longanimalsgames.com");
        sku.AddSiteLock("longanimals.com");
        sku.mainLogoName = "longAnimals";
        sku.linkURL = "http://www.longanimalsgames.com";
        skus.push(sku);
        sku = new LicSku(LICENSOR_ROBOTJAM, "RobotJam");
        sku.AddSiteLock("robotjam.com");
        sku.AddSiteLock("robotjamgames.com");
        sku.introName = "Intro_RobotJam";
        sku.scaleIntroToStage = true;
        sku.mainLogoName = "robotJam";
        sku.linkURL = "http://www.robotjamgames.com";
        sku.adtype = ADTYPE_CPMSTAR;
        skus.push(sku);
    }
    private static var LicDef_static_initializer = {
        authorLinks.push("http://www.turbonuke.com");
        CPMStarContentSpotIDs.push("8122QBE1BD8F0");
        true;
    }

}

