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
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        UI.AddBarebonesMCButton(titleMC.link_longAnimals, link_longAnimalsPressed);
        UI.AddBarebonesMCButton(titleMC.link_robotJam, link_robotJamPressed);
    }
    
    
    private function link_snakeEnginePressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.longanimalsgames.com/SnakeEngine.php?gamereferral=soccerballs2"), "_blank");
    }
    
    private function link_tomamotoPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.tomamoto.com?gamereferral=soccerballs2"), "_blank");
    }
    private function link_longAnimalsPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.longanimalsgames.com?gamereferral=soccerballs2"), "_blank");
    }
    private function link_robotJamPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.robotjam.com?gamereferral=soccerballs2"), "_blank");
    }
    private function link_jimpPressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.artjimp.com?gamereferral=soccerballs2"), "_blank");
    }
    private function link_asutePressed(e : MouseEvent) : Void
    {
        flash.Lib.getURL(new URLRequest("http://www.asute.com?gamereferral=soccerballs2"), "_blank");
    }
    private function buttonBackPressed(e : MouseEvent) : Void
    {
        UI.StartTransition("title");
    }
}


