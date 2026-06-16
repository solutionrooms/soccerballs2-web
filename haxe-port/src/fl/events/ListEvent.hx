package fl.events;
import openfl.events.Event;
class ListEvent extends Event {
	public static inline var ITEM_CLICK = "itemClick";
	public var item:Dynamic;
	public var rowIndex:Int = 0;
	public var columnIndex:Int = 0;
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) { super(type, bubbles, cancelable); }
}
