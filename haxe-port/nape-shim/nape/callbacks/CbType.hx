package nape.callbacks;

/** nape.callbacks.CbType shim — identity token. The game uses a single shared
 * CbType for every body + all four listeners, so it carries no filtering here. */
class CbType {
	static var _next:Int = 1;

	public var id(default, null):Int;
	public var userData:Dynamic;

	public function new() {
		id = _next++;
		userData = {data: null};
	}
}
