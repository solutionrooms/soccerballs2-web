package nape.callbacks;

/** nape.callbacks.PreListener shim — imported but never registered (the MAX-
 * elasticity PreListener was reverted). Minimal stub so imports resolve. */
class PreListener {
	public var interactionType:InteractionType;
	public var handler:PreCallback->Null<PreFlag>;
	public var precedence:Int;
	public var pure:Bool;

	public function new(interactionType:InteractionType, options1:Dynamic, options2:Dynamic, handler:PreCallback->Null<PreFlag>, precedence:Int = 0, pure:Bool = false) {
		this.interactionType = interactionType;
		this.handler = handler;
		this.precedence = precedence;
		this.pure = pure;
	}
}
