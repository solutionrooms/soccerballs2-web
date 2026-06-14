import flash.display.MovieClip;
import flash.display.Stage;
import licPackage.Lic;
import licPackage.LicDef;

/**
	 * ...
	 * @author
	 */
class ScreenSize
{
    
    public function new()
    {
    }
    
    public static var gameStageWidth : Float;
    public static var gameStageHeight : Float;
    public static var fullScreenScale : Float;
    public static var fullScreenScaleXOffset : Float;
    public static var fullScreenBlankArea : Float;
    
    public static var visibleW : Float;
    public static var visibleH : Float;
    
    
    public static function ScaleMovieClip(mc : MovieClip)
    {
        if (false)
        {
            mc.scaleX = ScreenSize.fullScreenScale;
            mc.scaleY = ScreenSize.fullScreenScale;
            mc.x += fullScreenScaleXOffset;
        }
    }
    public static function Calculate(stage : Stage)
    {
        if (stage.fullScreenWidth > stage.fullScreenHeight)
        {
            gameStageWidth = stage.fullScreenWidth;
            gameStageHeight = stage.fullScreenHeight;
        }
        else
        {
            gameStageWidth = stage.fullScreenHeight;
            gameStageHeight = stage.fullScreenWidth;
        }
        
        fullScreenScale = gameStageWidth / Defs.displayarea_w;
        
        var a : Float = stage.fullScreenWidth;
        var b : Float = stage.fullScreenHeight;
        if (stage.fullScreenHeight < a)
        {
            a = stage.fullScreenHeight;
            b = stage.fullScreenWidth;
        }
        
        fullScreenScale = a / Defs.displayarea_h;
        
        fullScreenScaleXOffset = (b - (Defs.displayarea_w * fullScreenScale)) / 2;
        fullScreenBlankArea = (b - (Defs.displayarea_w * fullScreenScale));
        
        visibleW = Defs.displayarea_w * fullScreenScale;
        visibleH = Defs.displayarea_h * fullScreenScale;
        
        Utils.print("********************** " + stage.fullScreenWidth + " " + stage.fullScreenHeight + " " + fullScreenScale);
        Utils.print("********************** " + a + " " + b);
        Utils.print("********************** " + Defs.displayarea_w + " " + Defs.displayarea_h);
        Utils.print("************************xoffset " + fullScreenScaleXOffset);
        Utils.print("************************leftover W " + fullScreenBlankArea);
    }
}


