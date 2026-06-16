// Stands in for the SWF library clip whose N frames hold the texture-page images.
// gotoAndStop(frame) swaps in the page bitmap; the original then BD.draw()s this clip.
class TexturePagesMC extends openfl.display.MovieClip {
	var bmp:openfl.display.Bitmap;
	public function new() { super(); bmp = new openfl.display.Bitmap(); addChild(bmp); gotoAndStop(1); }
	override public function gotoAndStop(frame:Dynamic, ?scene:String):Void {
		var idx = (Std.isOfType(frame, Int) ? cast(frame, Int) : Std.parseInt(Std.string(frame))) - 1;
		bmp.bitmapData = openfl.utils.Assets.getBitmapData("assets/TexturePage_" + idx + ".png");
	}
	override private function get_totalFrames():Int { return 20; }
}
