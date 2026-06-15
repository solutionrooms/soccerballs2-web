package fl.controls;
// Stub for the Flash UI List component (editor panels only; never runs in gameplay).
import openfl.display.Sprite;
class List extends Sprite {
	public var selectedIndex:Int = -1;
	public var selectedItem:Dynamic;
	public var dataProvider:Dynamic;
	public var rowCount:Int = 0;
	public function new() { super(); }
	public function addItem(item:Dynamic):Void {}
	public function removeAll():Void {}
	public function addColumn(c:Dynamic):Dynamic { return null; }
	public function itemToCellRenderer(item:Dynamic):Dynamic { return null; }
}
