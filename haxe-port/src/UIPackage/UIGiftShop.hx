package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.URLRequest;
import flash.ui.Mouse;
import licPackage.AdHolder;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;
import licPackage.LicSku;
import licPackage.OtherGames;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIGiftShop extends UIScreenInstance
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
        
        Audio.PlayMusic("menus_music");
        
        titleMC = new MovieClip();  // giftShop();  
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.buttonQuit, buttonBackPressed, null, true);
        UI.AddAnimatedMCButton(titleMC.intro_text.close_btn, buttonClosePressed, null, true);
        
        titleMC.intro_text.visible = true;
        
        titleMC.textNumGold.text = GameVars.GetNumBonusGold();
        InitGifts();
    }
    
    private function InitGifts()
    {
        var numGold : Int = GameVars.GetNumBonusGold();
        var costs : Array<Dynamic> = new Array<Dynamic>(10, 15, 25, 50);
        for (i in 1...4)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("gift" + i), MovieClip) catch(e:Dynamic) null;
            if (numGold >= costs[i - 1])
            {
                mc.gotoAndStop(2);
            }
            else
            {
                mc.gotoAndStop(1);
            }
            mc.downloadBtn.giftID = i;
            UI.AddAnimatedMCButton(mc.downloadBtn, DownloadPressed);
        }
    }
    
    private function DownloadFile(url : String)
    {
        flash.Lib.getURL(new URLRequest(url), "_blank");
    }
    
    public function DownloadPressed(e : MouseEvent)
    {
        var id : Int = e.currentTarget.giftID;
        if (id == 1)
        {
            cast(("http://www.guineapop.com/Downloads/PackofPiggies.pdf"), DownloadFile);
        }
        if (id == 2)
        {
            cast(("http://www.guineapop.com/Downloads/TokyoGuineaPop_WALLPAPERS.zip"), DownloadFile);
        }
        if (id == 3)
        {
            cast(("http://www.guineapop.com/Downloads/Concepts.jpg"), DownloadFile);
        }
        if (id == 4)
        {
            cast(("http://www.guineapop.com/Downloads/BoardGames.zip"), DownloadFile);
        }
    }
    
    public function buttonClosePressed(e : MouseEvent)
    {
        titleMC.intro_text.visible = false;
    }
    public function buttonBackPressed(e : MouseEvent)
    {
        UI.StartTransition("levelselect");
    }
}

