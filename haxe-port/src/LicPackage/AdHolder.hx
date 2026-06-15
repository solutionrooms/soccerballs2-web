package licPackage;
// Stub. Pre-roll/interstitial ad holder. Inert in this build; InitOnce proceeds.
import openfl.display.MovieClip;
import openfl.events.MouseEvent;
import haxe.Constraints.Function;
class AdHolder {
	public static function InitOnce(_callback:Function):Void { if (_callback != null) Reflect.callMethod(null, _callback, []); }
	public static function IsLoadedPreAdAvailable():Bool { return false; }
	public static function RemoveAd(parent:MovieClip):Void {}
	public static function GetAd():MovieClip { return null; }
	public static function PreAdClicked(e:MouseEvent):Void {}
	public static function GetPreAdItem():Dynamic { return null; }
	public static function GetPreAdCustomMC(?mc:Dynamic):Dynamic { return null; }
}
