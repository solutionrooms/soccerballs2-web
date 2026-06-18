// Loads the game's Komika Axis font (the user-provided KOMIKAX.TTF) via the browser FontFace API and
// exposes it under the family name "KomikaAxis". The in-game bitmap font (font1) is rasterized from this
// family in DisplayObj.CreateFont, and the preparing screen waits on `ready` so the 256 glyphs are baked
// with the real font instead of a browser fallback (the cause of the "wrong font" look).
//
// Why a browser FontFace instead of openfl @:font embedding: embedding the TTF via @:font +
// Font.registerFont produced an UNDEFINED fontName on HTML5, which crashed the swf library's
// font-matching loop. Here the glyphs come from a browser FontFace; Font20 is just a name carrier and is
// NOT registered with openfl, so that loop is never involved. Fail-open: any error / load failure sets
// `ready = true` so boot never hangs (text then falls back, but the game runs).
class GameFont
{
    public static inline var FAMILY : String = "KomikaAxis";

    public static var ready : Bool = #if (js && html5) false #else true #end;

    public static function Load() : Void
    {
        #if (js && html5)
        try
        {
            var ff = new js.html.FontFace(FAMILY, "url(assets/fonts/KomikaAxis.ttf)");
            js.Browser.document.fonts.add(ff);
            ff.load().then(function(_) { ready = true; }, function(_) { ready = true; });
        }
        catch (e : Dynamic)
        {
            ready = true;
        }
        #end
    }
}
