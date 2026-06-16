package kizi;

import flash.utils.Dictionary;
import flash.utils.Proxy;


/**
	 * ...
	 * @author ...
	 */
class KiziVault extends Proxy
{
    public function new()
    {
        super();
    }
    
    override public function setProperty(name : Dynamic, value : Dynamic) : Void
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.vault != null)
        {
            KiziAPI.api.vault[name] = value;
        }
    }
    
    override public function getProperty(name : Dynamic) : Dynamic
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.vault != null)
        {
            return KiziAPI.api.vault[name];
        }
        else
        {
            return null;
        }
    }
}

