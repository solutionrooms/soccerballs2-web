package nape.phys;

/**
 * nape.phys.BodyType shim. Singletons compared by identity (`body.type == BodyType.DYNAMIC`).
 * `code` maps to the replica's setBodyType convention: 0=static, 1=dynamic, 2=kinematic.
 */
class BodyType {
	public var code(default, null):Int;

	function new(code:Int)
		this.code = code;

	static var _static:BodyType;
	static var _dynamic:BodyType;
	static var _kinematic:BodyType;

	public static var STATIC(get, never):BodyType;
	static function get_STATIC():BodyType {
		if (_static == null) _static = new BodyType(0);
		return _static;
	}

	public static var DYNAMIC(get, never):BodyType;
	static function get_DYNAMIC():BodyType {
		if (_dynamic == null) _dynamic = new BodyType(1);
		return _dynamic;
	}

	public static var KINEMATIC(get, never):BodyType;
	static function get_KINEMATIC():BodyType {
		if (_kinematic == null) _kinematic = new BodyType(2);
		return _kinematic;
	}
}
