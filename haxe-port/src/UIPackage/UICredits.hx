package uIPackage;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.net.URLRequest;
import flash.ui.Mouse;

/**
	 * ...
	 * @author LongAnimals
	 */
class UICredits extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        titleMC.stop();
        UI.RemoveAllButtons();
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        titleMC = new ScreenCredits();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndPlay(1);
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_back, buttonBackPressed);
        
        UI.AddBarebonesMCButton((untyped titleMC).link_longAnimals, link_longAnimalsPressed);
        UI.AddBarebonesMCButton((untyped titleMC).link_robotJam, link_robotJamPressed);
    }
    
    
    public function link_snakeEnginePressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.longanimalsgames.com/SnakeEngine.php?gamereferral=soccerballs2"), "_blank");
    }
    
    public function link_tomamotoPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.tomamoto.com?gamereferral=soccerballs2"), "_blank");
    }
    public function link_longAnimalsPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.longanimalsgames.com?gamereferral=soccerballs2"), "_blank");
    }
    public function link_robotJamPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.robotjam.com?gamereferral=soccerballs2"), "_blank");
    }
    public function link_jimpPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.artjimp.com?gamereferral=soccerballs2"), "_blank");
    }
    public function link_asutePressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.asute.com?gamereferral=soccerballs2"), "_blank");
    }
    public function buttonBackPressed(e : MouseEvent) : Void
    {
        UI.StartTransition("title");
    }
}


