package kizi;

import flash.net.URLRequest;
import flash.utils.Dictionary;

/**
	 * ...
	 * @author
	 */
class KiziScores
{
    public static function reportScore(boardName : String, value : Float) : Void
    {
        if (KiziAPI.apiLoaded)
        {
            KiziAPI.api.scores.reportScore(boardName, value);
        }
    }

    public function new()
    {
    }
}

