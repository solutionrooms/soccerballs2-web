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
        
        UI.AddAnimatedMCButton(titleMC.btn_continue, buttonBackPressed);
        
        for (i in 0...10)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("ach" + i), MovieClip) catch(e:Dynamic) null;
            var item : Achievement = Achievements.list[i + first];
            mc.textTitle.text = item.name;
            mc.textTick.visible = false;
            mc.achievement = item;
            if (item.complete)
            {
                mc.textTick.visible = true;
            }
            mc.addEventListener(MouseEvent.MOUSE_OVER, achievementOver, false, 0, true);
            mc.buttonMode = true;
            mc.useHandCursor = true;
        }
        
        titleMC.textDescription.text = "";
    }
    
    private function achievementOver(e : MouseEvent)
    {
        var item : Achievement = e.currentTarget.achievement;
        if (item == null)
        {
            return;
        }
        titleMC.textDescription.text = item.toUnlockText;
    }
    
    
    private function buttonBackPressed(e : MouseEvent) : Void
    {
        UI.StartTransition(UI.returnScreenName);
    }
}


