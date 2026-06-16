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
    public var displayQueue : Array<AchievementPopup>;
    
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
            popup.mc = new MovieClip();
            (untyped popup.mc).inner.achievementName.text = (untyped popup).achievement.name;
            (untyped popup.mc).inner.achievement_text.text = (untyped popup).achievement.description;
            (untyped popup.mc).inner.icon.gotoAndStop((untyped popup).achievement.popupFrame);
            Game.main.addChild(popup.mc);
            popup.mc.gotoAndPlay("on");
        }
        else
        {
            (untyped popup.mc).inner.achievementName.text = (untyped popup).achievement.name;
            (untyped popup.mc).inner.achievement_text.text = (untyped popup).achievement.description;
            (untyped popup.mc).inner.icon.gotoAndStop((untyped popup).achievement.popupFrame);
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
            (untyped popup).achievement = ach;
            popup.timer = Std.int(Defs.fps * 3);
            popup.active = false;
            displayQueue.push(popup);
        }
    }
    public function Reset()
    {
        displayQueue = [];
    }
}


