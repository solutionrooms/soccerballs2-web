package kizi;

import haxe.Constraints.Function;

/**
	 * ...
	 * @author 
	 */
class KiziStore
{
    public static inline var ITEM_MAXED_OUT : String = "ITEM_MAXED_OUT";
    public static inline var NOT_ENOUGH_COINS : String = "NOT_ENOUGH_COINS";
    public static inline var ITEM_NOT_FOUND : String = "ITEM_NOT_FOUND";
    public static inline var UNKNOWN_ERROR : String = "UNKNOWN_ERROR";
    
    public static function getItemPrice(itemName : String) : Int
    {
        if (KiziAPI.apiLoaded)
        {
            return KiziAPI.api.store.getItemPrice(itemName);
        }
        else
        {
            return 0;
        }
    }
    
    public static function getItemLevelPrices(itemName : String) : Array<Dynamic>
    {
        if (KiziAPI.apiLoaded)
        {
            return KiziAPI.api.store.getItemLevelPrices(itemName);
        }
        else
        {
            return [];
        }
    }
    
    public static function getItemBundleSize(itemName : String) : Int
    {
        if (KiziAPI.apiLoaded)
        {
            return KiziAPI.api.store.getItemBundleSize(itemName);
        }
        else
        {
            return 0;
        }
    }
    
    public static function purchaseItem(itemName : String, callback : Function, suppressPurchasePopup : Bool = false) : Void
    {
        if (KiziAPI.apiLoaded)
        {
            KiziAPI.api.store.purchaseItem([itemName], callback, suppressPurchasePopup);
        }
    }
    
    public static function purchaseItems(itemNames : Array<Dynamic>, callback : Function, suppressPurchasePopup : Bool = false) : Void
    {
        if (KiziAPI.apiLoaded)
        {
            KiziAPI.api.store.purchaseItems(itemNames, callback, suppressPurchasePopup);
        }
    }

    public function new()
    {
    }
}

