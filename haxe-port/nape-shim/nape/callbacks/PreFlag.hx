package nape.callbacks;

/** nape.callbacks.PreFlag shim — singletons (PreListener is unused/reverted). */
class PreFlag {
	function new() {}

	static var _accept:PreFlag;
	static var _ignore:PreFlag;
	static var _acceptOnce:PreFlag;
	static var _ignoreOnce:PreFlag;

	public static var ACCEPT(get, never):PreFlag;
	static function get_ACCEPT():PreFlag {
		if (_accept == null) _accept = new PreFlag();
		return _accept;
	}

	public static var IGNORE(get, never):PreFlag;
	static function get_IGNORE():PreFlag {
		if (_ignore == null) _ignore = new PreFlag();
		return _ignore;
	}

	public static var ACCEPT_ONCE(get, never):PreFlag;
	static function get_ACCEPT_ONCE():PreFlag {
		if (_acceptOnce == null) _acceptOnce = new PreFlag();
		return _acceptOnce;
	}

	public static var IGNORE_ONCE(get, never):PreFlag;
	static function get_IGNORE_ONCE():PreFlag {
		if (_ignoreOnce == null) _ignoreOnce = new PreFlag();
		return _ignoreOnce;
	}
}
