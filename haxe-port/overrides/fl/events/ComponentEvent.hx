package fl.events;
import openfl.events.Event;
class ComponentEvent extends Event {
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) { super(type, bubbles, cancelable); }
}
