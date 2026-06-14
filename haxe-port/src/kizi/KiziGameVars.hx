package kizi;


/**
	 * ...
	 * @author 
	 */
class KiziGameVars
{
    public static function getVar(key : String, defaultValue : Dynamic) : Dynamic
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.customVars[key] != null)
        {
            return KiziAPI.api.customVars[key];
        }
        else
        {
            return defaultValue;
        }
    }

    public function new()
    {
    }
}

