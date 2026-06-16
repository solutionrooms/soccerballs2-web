package kizi;

import haxe.Constraints.Function;

/**
	 * ...
	 * @author
	 */
class KiziEvents
{
    public static function cycleStarted(callback : Function) : Void
    {
        KiziLogger.debug("cycleStarted called");
        KiziAPI.api.events.onCycleStart(callback);
    }
    
    public static function cycleEnded(callback : Function) : Void
    {
        KiziLogger.debug("cycleEnded called");
        KiziAPI.api.events.onCycleEnd(callback);
    }
    
    public static function scoreScreenClosed(callback : Function) : Void
    {
        KiziLogger.debug("scoreScreenClosed called");
        KiziAPI.api.events.afterScoreScreen(callback);
    }
    
    public static function mainMenuShown() : Void
    {
        KiziLogger.debug("mainMenuShown called");
        KiziAPI.api.events.onMainMenu();
    }
    
    
    public static function togglePause() : Void
    {
        KiziLogger.debug("togglePause called");
        KiziAPI.api.events.onTogglePause();
    }
    
    public static function registerCallback(eventName : KiziApiInitiatedEvents, callbackFunction : Function) : Void
    {
        KiziAPI.api.events.registerCallback(eventName, callbackFunction);
    }

    public function new()
    {
    }
}

