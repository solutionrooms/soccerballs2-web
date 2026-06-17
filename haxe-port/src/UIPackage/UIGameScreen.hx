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
        // 'no underlay' diagnostic: an invisible Bitmap isn't rendered, so its dynamic texture stops
        // being uploaded to the GPU each frame (isolates the iOS texImage2D stall). Toggleable live.
        (untyped Game.main).screenB.visible = !TileRenderer.noUnderlay;
        // GPU sprite layer above the software underlay (screenB = background + vector terrain).
        if (TileRenderer.tilemap != null) titleMC.addChild(TileRenderer.tilemap);

        Game.currentMC = titleMC;
        (untyped Game.main).screenB.x = 0;
        (untyped Game.main).screenB.y = 0;
        Game.StartLevel();
    }
}


