// Embedded game data (release SWF embedded these via [Embed]); toString -> the XML text.
class EmbedLevelsTestbed { public function new() {} public function toString():String { return openfl.utils.Assets.getText("assets/SoccerBalls2_Levels_Testbed_Data.xml"); } }
