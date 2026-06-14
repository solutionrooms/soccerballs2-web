package achievementPackage;

import audioPackage.Audio;
import flash.display.MovieClip;

/**
	 * ...
	 * @author 
	 */
class AchievementDisplayQueue
{
    
    public function new()
    {
    }
    private var displayQueue : Array<AchievementPopup>;
    
    public function IsDisplayQueueActive() : Bool
    {
        if (displayQueue.length == 0)
        {
            return false;
        }
        return true;
    }
    public function Update() : Bool
    {
        if (displayQueue.length == 0)
        {
            return false;
        }
        
        var popup : AchievementPopup = displayQueue[0];
        if (popup.active == false)
        {
            Audio.OneShot("sfx_got_achievement");
            popup.active = true;
            popup.mc = new MovieClip();  // AchievementPopupMC();  
            popup.mc.inner.achievementName.text = popup.achievement.name;
            popup.mc.inner.achievement_text.text = popup.achievement.description;
            popup.mc.inner.icon.descendants("gotoAndStop")(popup.achievement.popupFrame);
            Game.main.addChild(popup.mc);
            popup.mc.gotoAndPlay("on");
        }
        else
        {
            popup.mc.inner.achievementName.text = popup.achievement.name;
            popup.mc.inner.achievement_text.text = popup.achievement.description;
            popup.mc.inner.icon.descendants("gotoAndStop")(popup.achievement.popupFrame);
            popup.timer--;
            if (popup.timer == 0)
            {
                popup.mc.gotoAndPlay("off");
            }
            else if (popup.timer < -10)
            {
                popup.active = false;
                Game.main.removeChild(popup.mc);
                popup.mc = null;
                popup.active = false;
                
                displayQueue.splice(0, 1);
            }
        }
        return true;
    }
    public function AddUnlockedList(unlockedList : Array<Achievement>)
    {
        for (ach in unlockedList)
        {
            var popup : AchievementPopup = new AchievementPopup();
            popup.achievement = ach;
            popup.timer = Defs.fps * 3;
            popup.active = false;
            displayQueue.push(popup);
        }
    }
    private function Reset()
    {
        displayQueue = new Array<AchievementPopup>();
    }
}

