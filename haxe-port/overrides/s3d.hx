// Minimal stub for the Stage3D context holder. useStage3D=false in this build, so
// the GPU path is dead; only a few residual texture-upload tails (guarded by an
// `if (useStage3D==false) return;` early-out, or otherwise unreachable) still name
// s3d.context3D. context3D stays null on the HTML5/canvas path.
class s3d {
	public static var context3D:openfl.display3D.Context3D;
}
