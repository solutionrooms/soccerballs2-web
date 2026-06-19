package nape.util;

import nape.geom.Vec2;

/** nape.util.Debug shim — imported but unused by the game; no-op debug renderer. */
class Debug {
	public var drawBodies:Bool = false;
	public var drawConstraints:Bool = false;
	public var display:openfl.display.Sprite;

	public function new()
		display = new openfl.display.Sprite();

	public function clear():Void {}
	public function flush():Void {}
	public function draw(object:Dynamic):Void {}
	public function drawLine(start:Vec2, end:Vec2, colour:Int):Void {}
	public function drawCircle(position:Vec2, radius:Float, colour:Int):Void {}

	public static function version():String
		return "shim";
}
