// Name carrier for the game font. The actual glyphs are provided by the browser FontFace loaded in
// GameFont.Load() under family "KomikaAxis"; this hands that family name to the TextFormat in
// GraphicObjects.AddFont (tf.font = font.fontName), and DisplayObj.CreateFont rasterizes the bitmap font
// from it with embedFonts=false (device-font path, so the browser FontFace is used).
// NOT registered with openfl (Font.registerFont crashed the swf font-matching loop on HTML5 with an
// undefined fontName) — we only need the family-name string here.
class Font20 extends openfl.text.Font
{
    public function new()
    {
        super();
        fontName = GameFont.FAMILY;
    }
}
