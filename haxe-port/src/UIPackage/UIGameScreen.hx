package uIPackage;

import flash.display.MovieClip;
import flash.display.StageQuality;
import licPackage.LicDef;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIGameScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
        Game.StopLevel();
        
        
        {
            titleMC.removeChild(Game.main.screenB);
        }
    }
    
    override public function InitScreen()
    {
        LicDef.GetStage().stage.frameRate = Defs.fps;
        LicDef.GetStage().stage.quality = StageQuality.MEDIUM;
        
        Game.main.screenB.bitmapData.fillRect(Defs.screenRect, 0);
        titleMC = new MovieClip();
        titleMC.addChild(Game.main.screenB);
        
        Game.currentMC = titleMC;
        Game.main.screenB.x = 0;
        Game.main.screenB.y = 0;
        Game.StartLevel();
    }
}


