package uIPackage;

import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import licPackage.Lic;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIGameCompleteScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
        UI.RemoveAllButtons();
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        Mouse.show();
        
        Audio.StopMusic();
        Audio.OneShot("kazoo");
        
        titleMC = new Endmovie();
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_next, buttonNextPressed);
        
        Lic.MCMoreGamesButton((untyped titleMC).btn_moregames, "gamecomplete", true);
    }
    
    public function buttonNextPressed(e : MouseEvent)
    {
        UI.StartTransition("levelselect");
    }
}


