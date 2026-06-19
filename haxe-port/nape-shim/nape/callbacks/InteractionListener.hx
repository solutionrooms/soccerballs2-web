package nape.callbacks;

/**
 * nape.callbacks.InteractionListener shim. The game registers four of these
 * (BEGIN/ONGOING × COLLISION/SENSOR) on space0. The Space drains the replica's
 * per-step events and dispatches to the matching listener's handler. options1/
 * options2 (CbTypes) are ignored — there is no cbType filtering in the shim.
 */
class InteractionListener {
	public var event:CbEvent;
	public var interactionType:InteractionType;
	public var handler:InteractionCallback->Void;
	public var precedence:Int;
	public var allowSleepingCallbacks:Bool;

	public function new(event:CbEvent, interactionType:InteractionType, options1:Dynamic, options2:Dynamic, handler:InteractionCallback->Void, precedence:Int = 0) {
		this.event = event;
		this.interactionType = interactionType;
		this.handler = handler;
		this.precedence = precedence;
		this.allowSleepingCallbacks = false;
	}
}
