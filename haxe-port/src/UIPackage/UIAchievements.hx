package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.net.URLRequest;
import flash.ui.Mouse;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIAchievements extends UIScreenInstance
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
        titleMC = new MovieClip();
        titleMC.gotoAndPlay(1);
        UI.AddGeneric(titleMC);
        
        var first : Int = 33;
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_continue, buttonBackPressed);
        
        for (i in 0...10)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("ach" + i), MovieClip) catch(e:Dynamic) null;
            var item : Achievement = Achievements.list[i + first];
            (untyped mc).textTitle.text = Std.string(item.name);
            (untyped mc).textTick.visible = false;
            (untyped mc).achievement = item;
            if (item.complete)
            {
                (untyped mc).textTick.visible = true;
            }
            mc.addEventListener(MouseEvent.MOUSE_OVER, achievementOver, false, 0, true);
            mc.buttonMode = true;
            mc.useHandCursor = true;
        }
        
        (untyped titleMC).textDescription.text = "";
    }
    
    public function achievementOver(e : MouseEvent)
    {
        var item : Achievement = (untyped e.currentTarget).achievement;
        if (item == null)
        {
            return;
        }
        (untyped titleMC).textDescription.text = Std.string(item.toUnlockText);
    }
    
    
    public function buttonBackPressed(e : MouseEvent) : Void
    {
        UI.StartTransition(UI.returnScreenName);
    }
}


