// Stub for the embedded Font20 font asset (Komika Axis / KOMIKAX.TTF). Embedding it via @:font +
// Font.registerFont gave the font an undefined fontName on HTML5, which crashed the swf library's
// font-matching loop (AnimateDynamicTextSymbol enumerates fonts and calls .replace on fontName).
// Reverted to a stub; the real font needs proper async loading — see follow-up.
class Font20 extends openfl.text.Font { public function new() { super(); } }
