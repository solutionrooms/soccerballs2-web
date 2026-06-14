package fl.controls;
// Stub for the Flash UI ComboBox component (editor panels only).
import openfl.display.Sprite;
class ComboBox extends Sprite {
	public var selectedIndex:Int = -1;
	public var selectedItem:Dynamic;
	public var dataProvider:Dynamic;
	public function new() { super(); }
	public function addItem(item:Dynamic):Void {}
	public function removeAll():Void {}
}
