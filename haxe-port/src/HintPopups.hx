import flash.display.MovieClip;
import flash.events.MouseEvent;
import uIPackage.UI;

/**
	 * ...
	 * @author
	 */
class HintPopups
{
    public static var list : Array<HintPopup>;
    public static var displayQueue : Array<HintPopup>;
    public static var active : Bool;
    
    public function new()
    {
    }
    public static function InitOnce()
    {
        displayQueue = [];
        
        list = [];
        
        list.push(new HintPopup("Achieve a certain place in the level to unlock the next level"));
        list.push(new HintPopup("Collect NITRO pickups to fill your nitro bar."));
        list.push(new HintPopup("Hold X to use your nitro."));
        list.push(new HintPopup("Aim your car in the air when using nitro."));
        list.push(new HintPopup("Small wheels are lighter thereby increasing your top speed."));
        list.push(new HintPopup("Scraping your car body on the floor slows you down."));
        list.push(new HintPopup("Try not to crash. This slows you down a lot!"));
        list.push(new HintPopup("Perform a spin to get extra nitro."));
        list.push(new HintPopup("Higher suspension can help you on rough ground."));
        list.push(new HintPopup("Use the RANDOM button in the workshop for some funny cars."));
        list.push(new HintPopup("In the Workshop you can save and load your favourite setups"));
        list.push(new HintPopup("Big chunky wheels operate better on rough ground."));
        list.push(new HintPopup("You lose speed rapidly while in the air."));
        list.push(new HintPopup("For the Law Abider award, check which color the lights are when you finish a race."));
        
        active = true;
    }
    
    
    public static function ResetEverything()
    {
        InitOnce();
    }
    public static function GetNextNotShown() : HintPopup
    {
        for (h in list)
        {
            if (h.shown == false)
            {
                return h;
            }
        }
        return null;
    }
    public static function ShowNext()
    {
        if (active == false)
        {
            return;
        }
        var h : HintPopup = GetNextNotShown();
        if (h == null)
        {
            return;
        }
        h.shown = true;
        
        var popup : HintPopup = h.Clone();
        popup.timer = Std.int(Defs.fps * 5);
        popup.active = false;
        displayQueue.push(popup);
    }
    
    
    
    
    public static function ExitForLevel()
    {
        for (popup in displayQueue)
        {
            if (popup.mc != null)
            {
                UI.RemoveAnimatedMCButton((untyped popup.mc).inner.buttonNoMore);
                Game.main.removeChild(popup.mc);
                popup.mc = null;
            }
        }
    }
    public static function InitForLevel()
    {
        displayQueue = [];
    }
    public static function IsDisplayQueueActive() : Bool
    {
        if (displayQueue.length == 0)
        {
            return false;
        }
        return true;
    }
    
    public static function buttonNoMorePressed(e : MouseEvent)
    {
        active = false;
        for (popup in displayQueue)
        {
            popup.timer = 1;
        }
    }
    
    public static function UpdateDisplayQueue() : Bool
    {
        if (displayQueue.length == 0)
        {
            return false;
        }
        
        var popup : HintPopup = displayQueue[0];
        if (popup.active == false)
        {
            popup.active = true;
            popup.mc = new MovieClip();
            UI.AddAnimatedMCButton((untyped popup.mc).inner.buttonNoMore, buttonNoMorePressed);
            (untyped popup.mc).inner.hint_text.text = popup.text;
            Game.main.addChild(popup.mc);
            popup.mc.gotoAndPlay("on");
        }
        else
        {
            (untyped popup.mc).inner.hint_text.text = popup.text;
            popup.timer--;
            if (popup.timer == 0)
            {
                popup.mc.gotoAndPlay("off");
            }
            else if (popup.timer < -10)
            {
                popup.active = false;
                UI.RemoveAnimatedMCButton((untyped popup.mc).inner.buttonNoMore);
                Game.main.removeChild(popup.mc);
                popup.mc = null;
                popup.active = false;
                
                displayQueue.splice(0, 1);
            }
        }
        return true;
    }
    
    public static function ToSharedObject() : Dynamic
    {
        var o : Dynamic = {};
        o.active = active;
        o.shown = [];
        
        for (h in list)
        {
            o.shown.push(h.shown);
        }
        return o;
    }
    
    public static function FromSharedObject(o : Dynamic)
    {
        if (o == null)
        {
            return;
        }
        if (o.shown == null)
        {
            return;
        }
        active = o.active;
        
        for (i in 0...o.shown.length)
        {
            var h : HintPopup = list[i];
            h.shown = o.shown[i];
        }
    }
}


