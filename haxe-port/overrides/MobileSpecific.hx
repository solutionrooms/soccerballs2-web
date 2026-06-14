// Stub. MobileSpecific wrapped AIR/mobile-only features (native share, etc.).
// isMobile=false in this build, so these are inert. Init runs on boot; PostTwitter
// is a share action with no gameplay effect.
class MobileSpecific {
	public static function Init():Void {}
	public static function PostTwitter(?msg:Dynamic = null):Void {}
}
