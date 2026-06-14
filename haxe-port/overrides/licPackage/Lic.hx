package licPackage;

import openfl.display.MovieClip;
import openfl.display.SimpleButton;
import openfl.text.TextField;
import haxe.Constraints.Function;

// STUB. The original Lic is the licensing / portal / ads / social-button glue
// (CPMStar, Mochi, Kongregate, Facebook, "more games" links). None of it affects
// gameplay physics, levels, or timing — the faithfulness target — so it is
// replaced with no-ops. The one behaviourally important call is ShowIntro, which
// must invoke its callback so boot continues into the game. LicDef (the licensor
// constants + GetStage) is kept as converted; only this ad-glue layer is stubbed.
class Lic {
	public static function InitFromMain():Void {}
	public static function Playtomic_Log():Void {}

	public static function ShowIntro(_showIntroCallback:Function):Void {
		// no intro/preroll ad — proceed straight to the game
		if (_showIntroCallback != null) Reflect.callMethod(null, _showIntroCallback, []);
	}

	// portal / social buttons: present in some menus, inert in this build
	public static function AuthorButton(mc:SimpleButton):Void {}
	public static function PlayWithScoresButton(btn:SimpleButton):Void {}
	public static function AnimatedMCPrequelButton(mc:MovieClip):Void {}
	public static function AnimatedMCFacebookButton(mc:MovieClip):Void {}
	public static function Y8LogoButton(b:SimpleButton):Void {}
	public static function AnimatedMCDownloadForYourSiteButton(mc:MovieClip):Void {}
	public static function AnimatedMCMoreGamesButton(btn:MovieClip, _from:String):Void {}
	public static function MCMoreGamesButton(btn:MovieClip, _from:String, noChange:Bool = false):Void {}
	public static function MainLogoButton(mc:MovieClip):Void {}
	public static function AnimatedMCWalkthroughButton(mc:MovieClip):Void {}
	public static function SubmitScoreButton(b:MovieClip, textField:TextField, _cb:Function = null):Void {}
	public static function Kongregate_SubmitStat(value:Float, type:String):Void {}
}
