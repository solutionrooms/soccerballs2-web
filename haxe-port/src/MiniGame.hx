import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import licPackage.Lic;

/**
	 * ...
	 * @author 
	 */
class MiniGame
{
    
    public function new()
    {
    }
    
    public static var screenBD : BitmapData;
    public static var screenB : Bitmap;
    public static var titleMC : MovieClip;
    
    public static var highscore : Int;
    public static var score : Int;
    public static var lives : Int;
    
    public static function Exit()
    {
        screenB.bitmapData = null;
        screenBD.dispose();
        screenBD = null;
    }
    public static function Init(_titleMC : MovieClip)
    {
        titleMC = _titleMC;
        Game.QuietAllSounds();
        
        PhysicsBase.Init();
        
        screenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0);
        screenB = new Bitmap(screenBD);
        
        highscore = 0;
    }
    
    public static function End()
    {
        if (score > highscore)
        {
            highscore = score;
        }
        GameObjects.ClearAll();
        titleMC.overlay.visible = true;
        titleMC.overlay.textBestScore.text = "Your Best Score: " + highscore;
        Lic.Kongregate_SubmitStat(score, "minigamescore");
    }
    public static function Start()
    {
        titleMC.overlay.visible = false;
        Restart();
    }
    
    private static function Restart()
    {
        Particles.Reset();
        GameObjects.ClearAll();
        var go : GameObj;
        go = GameObjects.AddObj(0, 0, 0);
        
        var go : GameObj;
        go = GameObjects.AddObj(0, 0, 0);
        
        score = 0;
        lives = 5;
    }
    
    public static function GetBitmap() : Bitmap
    {
        return screenB;
    }
    
    public static function Render()
    {
        var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("ArcadeBackground");
        dob.RenderAt(0, screenBD, 0, 0);
        GameObjects.Render(screenBD);
    }
    public static function UpdateHud()
    {
        titleMC.textLives.text = "Lives: " + lives;
        titleMC.textScore.text = "Score: " + score;
    }
    public static function Update()
    {
        GameObjects.ClearAddList();
        GameObjects.Update();
        GameObjects.KillObjects();
        GameObjects.DoAddList();
        UpdateHud();
        
        if (lives < 1)
        {
            End();
        }
    }
}

