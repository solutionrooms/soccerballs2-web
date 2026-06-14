package kizi;


/**
	 * ...
	 * @author
	 */
class KiziUser
{
    public static var inventory : KiziInventory;
    
    
    
    public static function getCoins() : Int
    {
        return KiziAPI.api.user.coins;
    }
    public static function getLevel() : Int
    {
        return KiziAPI.api.user.level;
    }
    public static function getExperience() : Int
    {
        return KiziAPI.api.user.experience;
    }
    public static function getLogin() : Int
    {
        return KiziAPI.api.user.login;
    }
    public static function isGuest() : Int
    {
        return KiziAPI.api.user.isGuest();
    }

    public function new()
    {
    }
    private static var KiziUser_static_initializer = {
        {
            inventory = new KiziInventory();
        };
        true;
    }

}


