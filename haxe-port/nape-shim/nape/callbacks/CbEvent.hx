package nape.callbacks;

/** nape.callbacks.CbEvent shim — singletons compared by identity. */
class CbEvent {
	public var code(default, null):Int;

	function new(code:Int)
		this.code = code;

	static var _begin:CbEvent;
	static var _ongoing:CbEvent;
	static var _end:CbEvent;

	public static var BEGIN(get, never):CbEvent;
	static function get_BEGIN():CbEvent {
		if (_begin == null) _begin = new CbEvent(0);
		return _begin;
	}

	public static var ONGOING(get, never):CbEvent;
	static function get_ONGOING():CbEvent {
		if (_ongoing == null) _ongoing = new CbEvent(1);
		return _ongoing;
	}

	public static var END(get, never):CbEvent;
	static function get_END():CbEvent {
		if (_end == null) _end = new CbEvent(2);
		return _end;
	}
}
