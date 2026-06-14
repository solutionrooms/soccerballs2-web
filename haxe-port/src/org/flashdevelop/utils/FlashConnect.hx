package org.flashdevelop.utils;

// Stub for the FlashDevelop debug-console helper used only for trace() logging
// in the original. Routes to haxe trace; no gameplay effect.
class FlashConnect {
	public static function trace(v:Dynamic):Void {
		#if debug
		haxe.Log.trace(v);
		#end
	}
}
