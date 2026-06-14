// Stub for the embedded VarsData.xml asset class (AS3 [Embed]). Real balance data
// is wired via OpenFL assets in the asset-loading step; this keeps the embedded
// branch (Vars.InitOnce when load_vars_data==false) type-checking. The live web
// path loads VarsData.xml by URL instead.
class ClassVars {
	public function new() {}
}
