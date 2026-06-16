package kizi;

import flash.utils.Proxy;


/**
	 * ...
	 * @author
	 */
class KiziGameState extends Proxy
{
    override public function getProperty(name : Dynamic) : Dynamic
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.gameState)
        {
            return KiziAPI.api.gameState[name];
        }
        else
        {
            return null;
        }
    }
    
    override public function setProperty(name : Dynamic, value : Dynamic) : Void
    {
        if (KiziAPI.apiLoaded && KiziAPI.api.gameState)
        {
            KiziAPI.api.gameState[name] = value;
        }
    }

    public function new()
    {
        super();
    }
}


