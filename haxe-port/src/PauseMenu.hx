import flash.display.MovieClip;
import flash.events.*;
import flash.text.*;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.URLRequest;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;
import flash.net.*;
import flash.ui.*;
import textPackage.TextStrings;
import uIPackage.UI;

/**
	* ...
	* @author Default
	*/
class PauseMenu
{
    private static var active : Bool;
    private static var pauseMC : MovieClip;
    
    public static function InitOnce() : Void
    {
        active = false;
    }
    
    public function new()
    {
    }
    
    public static function Pause() : Void
    {
        pauseMC = AddMovieClip(0, 0, new ScreenPaused());
        ScreenSize.ScaleMovieClip(pauseMC);
        Game.main.addChild(pauseMC);
        
        TextStrings.ReplaceTextFieldText(pauseMC.textTitle);
        
        UI.AddAnimatedMCButton(pauseMC.ButtonContinue, pressed_buttonContinue);
        UI.AddAnimatedMCButton(pauseMC.ButtonRestart, pressed_buttonRestartLevel);
        UI.AddAnimatedMCButton(pauseMC.ButtonQuit, pressed_buttonQuit);
        
        
        /*			pauseMC.buttonSFX.addEventListener(MouseEvent.CLICK,pressed_buttonSFX);
			pauseMC.buttonMusic.addEventListener(MouseEvent.CLICK,pressed_buttonMusic);
			pauseMC.buttonQuit.addEventListener(MouseEvent.CLICK,pressed_buttonQuit);
			pauseMC.buttonRestartLevel.addEventListener(MouseEvent.CLICK,pressed_buttonRestartLevel);
			pauseMC.buttonContinue.addEventListener(MouseEvent.CLICK,pressed_buttonContinue);
			pauseMC.buttonHelp.addEventListener(MouseEvent.CLICK,pressed_buttonHelp);
			pauseMC.buttonHints.addEventListener(MouseEvent.CLICK, pressed_buttonHelp);

			pauseMC.buttonHelp.visible = false;
			pauseMC.buttonHints.visible = false;
*/
        active = true;
    }
    
    public static function pressed_buttonQuit(event : MouseEvent)
    {
        Unpause();
        UI.StartTransition("levelselect");
    }
    public static function pressed_buttonRestartLevel(event : MouseEvent)
    {
        Unpause();
        Game.StartLevel();
    }
    public static function pressed_buttonHelp(event : MouseEvent)
    {
    }
    public static function pressed_buttonContinue(event : MouseEvent)
    {
        Unpause();
    }
    
    
    
    
    private static function AddMovieClip(x : Float, y : Float, mc : MovieClip) : MovieClip
    {
        mc.x = x;
        mc.y = y;
        Game.main.addChild(mc);
        return mc;
    }
    
    
    public static function IsPaused() : Bool
    {
        return active;
    }
    
    public static function Unpause() : Void
    {
        active = false;
        Game.main.removeChild(pauseMC);
        pauseMC = null;
        KeyReader.InitOnce(Game.main.stage);
    }
}


