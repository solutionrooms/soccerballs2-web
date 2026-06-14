import haxe.Constraints.Function;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import kizi.KiziAPI;
import kizi.KiziApiInitiatedEvents;
import kizi.KiziEvents;
import kizi.KiziScores;
import kizi.KiziStore;
import kizi.KiziUser;
import licPackage.LicDef;

/**
	 * ...
	 * @author 
	 */
class KiziStuff
{
    
    public function new()
    {
    }
    
    private static var coinBalanceCB : Function;
    public static function RemoveCoinBalanceCB(cb : Function)
    {
        coinBalanceCB = null;
    }
    public static function AddCoinBalanceCB(cb : Function)
    {
        coinBalanceCB = cb;
    }
    public static function InitFromPreloader()
    {
        KiziEvents.registerCallback(KiziApiInitiatedEvents.USER_LOGGED_IN, Callback_UserLoggedIn);
        KiziEvents.registerCallback(KiziApiInitiatedEvents.COIN_BALANCE_CHANGED, Callback_CoinBalanceChanged);
        coinBalanceCB = null;
    }
    
    public static function Callback_CoinBalanceChanged()
    {
        if (coinBalanceCB != null)
        {
            coinBalanceCB();
        }
    }
    public static function Callback_UserLoggedIn()
    {
        KiziAPI.reloadPage();
    }
    
    public static function Active() : Bool
    {
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KIZI)
        {
            return true;
        }
        return false;
    }
    
    public static function GetSharedObject() : Dynamic
    {
        if (KiziAPI.gameState["shared_object"] == null)
        {
            return null;
        }
        return KiziAPI.gameState["shared_object"];
    }
    public static function ToSharedObject(o : Dynamic)
    {
        KiziAPI.gameState["shared_object"] = o;
    }
    
    public static function MainMenuShown()
    {
        if (Active() == false)
        {
            return;
        }
        KiziEvents.mainMenuShown();
    }
    
    public static function CycleStarted(_cb : Function)
    {
        if (Active() == false)
        {
            _cb(null);
        }
        else
        {
            KiziEvents.cycleStarted(_cb);
        }
    }
    
    public static function GetCoins() : Int
    {
        return KiziUser.getCoins();
    }
    
    public static function PurchaseItem(itemName : String, cb : Function, suppress : Bool = false)
    {
        KiziStore.purchaseItem(itemName, cb, suppress);
    }
    
    public static function SetUpgradeLevel(itemName : String, value : Int)
    {
        KiziUser.inventory[itemName] = value;
    }
    public static function GetUpgradeLevel(itemName : String) : Int
    {
        return KiziUser.inventory[itemName];
    }
    public static function GetUpgradeCost(itemName : String) : Int
    {
        return KiziStore.getItemPrice(itemName);
    }
    public static function TogglePause()
    {
        if (Active() == false)
        {
            return;
        }
        KiziEvents.togglePause();
    }
    
    public static function ReportScore(boardName : String, value : Float)
    {
        if (Active() == false)
        {
            return;
        }
        KiziScores.reportScore(boardName, value);
    }
    
    public static function ScoreScreenClosed(_cb : Function)
    {
        KiziEvents.scoreScreenClosed(_cb);
    }
    
    public static function CycleEnded(_cb : Function)
    {
        if (Active() == false)
        {
            _cb(null);
        }
        else
        {
            KiziEvents.cycleEnded(_cb);
        }
    }
    
    public static function AddCoinAt(mc : MovieClip, xpos : Int, ypos : Int, scale : Float, depth : Int = 0) : MovieClip
    {
        var coinMC : MovieClip = KiziAPI.getCoinIcon();
        mc.addChild(coinMC);
        coinMC.x = xpos;
        coinMC.y = ypos;
        coinMC.scaleX = scale;
        coinMC.scaleY = scale;
        
        if (depth != 0)
        {
            mc.setChildIndex(coinMC, depth);
        }
        
        return coinMC;
    }
    
    
    private static var addLogo_xpos : Int;
    private static var addLogo_ypos : Int;
    private static var addLogo_mc : MovieClip;
    private static var addLogo_scale : Float;
    public static function AddLogoAt(mc : MovieClip, xpos : Int, ypos : Int, scale : Float)
    {
        addLogo_mc = mc;
        addLogo_xpos = xpos;
        addLogo_ypos = ypos;
        addLogo_scale = scale;
        var mLoader : Loader = new Loader();
        var mRequest : URLRequest = new URLRequest("http://cdn0.kizi.com/assets/kiziLogo.swf");
        
        mLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, AddLogoAt_onCompleteHandler);
        mLoader.addEventListener(IOErrorEvent.IO_ERROR, AddLogoAt_onError);
        mLoader.load(mRequest);
    }
    
    private static function AddLogoAt_onCompleteHandler(loadEvent : Event)
    {
        loadEvent.currentTarget.content.x = addLogo_xpos;
        loadEvent.currentTarget.content.y = addLogo_ypos;
        loadEvent.currentTarget.content.scaleX = addLogo_scale;
        loadEvent.currentTarget.content.scaleY = addLogo_scale;
        addLogo_mc.addChild(loadEvent.currentTarget.content);
    }
    private static function AddLogoAt_onError(loadEvent : Event)
    {
        trace("KiziStuff.AddLogoAt error");
    }
}

