// Embedded game data (release SWF embedded these via [Embed]); toString -> the XML text.
class EmbedObjectsData { public function new() {} public function toString():String { return openfl.utils.Assets.getText("assets/SoccerBalls2_Objects_Data.xml"); } }
