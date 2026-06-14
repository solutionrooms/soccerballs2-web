package kizi;

import flash.utils.Proxy;


/**
	 * ...
	 * @author
	 */
class KiziInventory extends Proxy
{
    override private function getProperty(name : Dynamic) : Dynamic
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.user && KiziAPI.api.user.inventory)
        {
            return KiziAPI.api.user.inventory[name];
        }
        else
        {
            return null;
        }
    }
    
    override private function setProperty(name : Dynamic, value : Dynamic) : Void
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.user && KiziAPI.api.user.inventory)
        {
            KiziAPI.api.user.inventory[name] = value;
        }
    }

    public function new()
    {
        super();
    }
}


