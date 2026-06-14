package licPackage;

import com.google.analytics.AnalyticsTracker;
import com.google.analytics.GATracker;

/**
	 * ...
	 * @author
	 */
class Tracking
{
    private static var doDebug : Bool = false;
    
    public function new()
    {
    }
    
    public static var tracker : AnalyticsTracker;
    
    
    public static function IsActive() : Bool
    {
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE_ONSITE)
        {
            return true;
        }
        if (LicDef.GetLicensor() == LicDef.LICENSOR_KONGREGATE)
        {
            return true;
        }
        return false;
    }
    
    
    public static function InitOnce()
    {
        if (IsActive() == false)
        {
            return;
        }
        tracker = new GATracker(LicDef.GetStage().root, "UA-603111-20", "AS3", doDebug);
    }
    
    public static function Event(category : String, action : String, label : String = null, value : Float = Math.NaN)
    {
        if (IsActive() == false)
        {
            return;
        }
        tracker.trackEvent(category, action, label, value);
    }
    public static function LogLink(_url : String, _name : String = "undefined")
    {
        if (IsActive() == false)
        {
            return;
        }
        tracker.trackEvent("link", _url, _name);
    }
    public static function LogView()
    {
        if (IsActive() == false)
        {
            return;
        }
        tracker.trackPageview("/view");
    }
}


