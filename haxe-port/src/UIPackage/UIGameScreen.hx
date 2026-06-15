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
            titleMC.removeChild((untyped Game.main).screenB);
        }
    }
    
    override public function InitScreen()
    {
        LicDef.GetStage().stage.frameRate = Defs.fps;
        LicDef.GetStage().stage.quality = StageQuality.MEDIUM;
        
        (untyped Game.main).screenB.bitmapData.fillRect(Defs.screenRect, 0);
        titleMC = new MovieClip();
        titleMC.addChild((untyped Game.main).screenB);
        
        Game.currentMC = titleMC;
        (untyped Game.main).screenB.x = 0;
        (untyped Game.main).screenB.y = 0;
        Game.StartLevel();
    }
}


