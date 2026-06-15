import com.adobe.images.PNGEncoder;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.Event;
import flash.geom.Matrix;
import flash.net.FileReference;
import flash.utils.ByteArray;

/**
	 * ...
	 * @author ...
	 */
class WalkthroughScreen
{
    public var screenBD : BitmapData;
    public var thumbBD : BitmapData;
    public var screenB : Bitmap;
    public var thumbB : Bitmap;
    
    public function new()
    {
        var ratio : Float = Defs.displayarea_h / Defs.displayarea_w;
        SetScreenSize(Defs.displayarea_w, Defs.displayarea_h);
        
        var thumbW : Float = 60;
        
        SetThumbSize(Std.int(thumbW), Std.int(thumbW * ratio));
    }
    
    public var screenW : Int;
    public var screenH : Int;
    public var thumbW : Int;
    public var thumbH : Int;
    
    public function SetScreenSize(w : Int, h : Int)
    {
        screenW = w;
        screenH = h;
    }
    public function SetThumbSize(w : Int, h : Int)
    {
        thumbW = w;
        thumbH = h;
    }
    
    public var titleMC : MovieClip;
    public function InitPlayback(_titleMC : MovieClip)
    {
        Game.gameState = Game.gameState_Walkthrough;
        Game.StartLevel(true);
        titleMC = _titleMC;
        
        titleMC.addChild(screenB);
        titleMC.setChildIndex(screenB, 0);
        titleMC.addEventListener(Event.ENTER_FRAME, OnEnterFrame);
    }
    
    public function OnEnterFrame(e : Event)
    {
        UpdatePlayback();
    }
    
    public function UpdatePlayback()
    {
        Game.gameState = Game.gameState_Walkthrough;
        Game.UpdateGameplay();
        Game.Render(screenBD);
    }
    
    public function StopPlayback()
    {
        titleMC.removeEventListener(Event.ENTER_FRAME, OnEnterFrame);
    }
    
    public function MakeScreen(level : Int)
    {
        Levels.currentIndex = level;
        var l : Level = Levels.GetCurrent();
        
        /*

			Game.StartLevel(true);

			Game.gameState = Game.gameState_Play;
			Game.UpdateGameplay();
			var bd:BitmapData = Game.main.screenBD;
			bd.fillRect(Defs.screenRect, 0);
			Game.Render(bd);
			Game.gameState = Game.gameState_UI;



			var m:Matrix = new Matrix();

			var scale:Number;

			scale = screenW/Defs.displayarea_w;
			screenBD = new BitmapData(screenW, screenH);
			m.identity();
			m.scale(scale, scale);
			screenBD.draw(bd, m, null, null, null, true);
			screenB = new Bitmap(screenBD);

			scale = thumbW/Defs.displayarea_w;
			thumbBD = new BitmapData(thumbW, thumbH);
			m.identity();
			m.scale(scale, scale);
			thumbBD.draw(bd, m, null, null, null, true);

			thumbB = new Bitmap(thumbBD);
			*/
        
        screenBD = new BitmapData(screenW, screenH);
        screenB = new Bitmap(screenBD);
    }
}


