package kizi;


/**
	 * ...
	 * @author
	 */
class KiziApiInitiatedEvents
{
    public static var USER_LOGGED_IN : KiziApiInitiatedEvents = new KiziApiInitiatedEvents(USER_LOGGED_IN);
    public static var COIN_BALANCE_CHANGED : KiziApiInitiatedEvents = new KiziApiInitiatedEvents(COIN_BALANCE_CHANGED);
    public function new(gs : KiziApiInitiatedEvents)
    {
    }
    public function toString() : String
    {
        switch (this)
        {
            case KiziApiInitiatedEvents.USER_LOGGED_IN:
                return "USER_LOGGED_IN";
            case KiziApiInitiatedEvents.COIN_BALANCE_CHANGED:
                return "COIN_BALANCE_CHANGED";
            default:
                return null;
        }
    }
}


