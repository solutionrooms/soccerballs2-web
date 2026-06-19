package nape.callbacks;

/** nape.callbacks.InteractionType shim — singletons compared by identity. */
class InteractionType {
	public var code(default, null):Int;

	function new(code:Int)
		this.code = code;

	static var _collision:InteractionType;
	static var _sensor:InteractionType;
	static var _fluid:InteractionType;

	public static var COLLISION(get, never):InteractionType;
	static function get_COLLISION():InteractionType {
		if (_collision == null) _collision = new InteractionType(0);
		return _collision;
	}

	public static var SENSOR(get, never):InteractionType;
	static function get_SENSOR():InteractionType {
		if (_sensor == null) _sensor = new InteractionType(1);
		return _sensor;
	}

	public static var FLUID(get, never):InteractionType;
	static function get_FLUID():InteractionType {
		if (_fluid == null) _fluid = new InteractionType(2);
		return _fluid;
	}
}
