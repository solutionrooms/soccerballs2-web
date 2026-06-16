// Minimal stub for the Stage3D context holder. useStage3D=false in this build (GPU path dead),
// so there is no real Context3D. Crucially, the original Game.InitOnce ends with
// `s3d.InitOnce(InitOnceA)` — the Stage3D init takes a completion callback that chains into
// InitGame()/StartTitleScreen(). With no GPU init to wait for, we invoke the callback
// synchronously so the boot sequence (and thus the title screen) still runs.
class s3d {
	public static var context3D:openfl.display3D.Context3D;
	public static function SetVisible(b:Bool):Void {}
	public static function InitOnce(?onReady:Void->Void):Void {
		if (onReady != null) onReady();
	}
}
