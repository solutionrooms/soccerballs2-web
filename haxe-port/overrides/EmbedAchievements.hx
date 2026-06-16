// Embedded game data (release SWF embedded these via [Embed]); toString -> the XML text.
class EmbedAchievements { public function new() {} public function toString():String { return openfl.utils.Assets.getText("assets/Achievements.xml"); } }
