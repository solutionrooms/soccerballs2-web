package nape.callbacks;

/** nape.callbacks.CbTypeList shim — `body.cbTypes.add(cb)` is a no-op (the shim
 * does not use cbType filtering; all contacts route through the registered
 * listeners). A single shared instance is handed out. */
class CbTypeList {
	static var _shared:CbTypeList;

	public function new() {}

	public static function shared():CbTypeList {
		if (_shared == null) _shared = new CbTypeList();
		return _shared;
	}

	public function add(cb:CbType):Bool
		return true;

	public function remove(cb:CbType):Bool
		return true;

	public function has(cb:CbType):Bool
		return false;
}
