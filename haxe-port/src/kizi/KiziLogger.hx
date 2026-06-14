package kizi;


/**
	 * ...
	 * @author 
	 */
class KiziLogger
{
    public static var logLevel : Int;
    public static inline var VERBOSE : Int = 2;
    public static inline var DEBUG : Int = 1;
    public static inline var ERROR : Int = 0;
    public static function verbose(params : Array<Dynamic> = null) : Void
    {
        log(2, params.join(" "));
    }
    
    public static function debug(params : Array<Dynamic> = null) : Void
    {
        log(1, params.join(" "));
    }
    
    public static function error(params : Array<Dynamic> = null) : Void
    {
        log(0, params.join(" "));
    }
    
    public static function log(logLevel : Int, message : String) : Void
    {
        if (logLevel <= KiziLogger.logLevel)
        {
            var now : Date = Date.now();
            var datetimeString : String = now.getDay() + "." + now.getMonth() + "." + now.getFullYear() + " " + now.getHours() + ":" + now.getMinutes() + ":" + now.getSeconds();
            trace(datetimeString + " - Host: " + message);
        }
    }

    public function new()
    {
    }
}

