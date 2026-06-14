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
    
    override private function setProperty(name : Dynamic, value : Dynamic) : Void
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.vault != null)
        {
            KiziAPI.api.vault[name] = value;
        }
    }
    
    override private function getProperty(name : Dynamic) : Dynamic
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
