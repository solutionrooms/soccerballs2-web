package uIPackage;

import com.adobe.images.PNGEncoder;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.FileReference;
import flash.ui.Mouse;
import flash.utils.ByteArray;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;
import licPackage.OtherGames;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIWalkthrough extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    /*
			if (adMC != null)
			{
				titleMC.removeChild(adMC);
				adMC = null;
			}
			*/
    {
        
        
        UI.RemoveAllButtons();
    }
    
    private var page : Int;
    
    private var adMC : MovieClip;
    
    override public function InitScreen()
    {
        UI.StartAddButtons();
        
        titleMC = new ScreenWalkthroughMain();
        titleMC.gotoAndStop(1);
        
        Lic.MainLogoButton(titleMC.mainLogo);
        Lic.AuthorButton(titleMC.turboBtn);
        
        UI.AddAnimatedMCButton(titleMC.prevPage, PrevPageClicked);
        UI.AddAnimatedMCButton(titleMC.nextPage, NextPageClicked);
        
        numPages = 4;
        
        InitPage();
        PopulatePage();
        
        
        return;
        /*
			adMC = null;
			if (LicDef.GetCurrentSku().showOtherGamesPanel)
			{
				adMC = OtherGames.GetOtherGamesMC(4, 1);
				adMC.x = 400;
				adMC.y = 365;
				adMC.scaleX = 0.6;
				adMC.scaleY = 0.6;
				titleMC.addChild(adMC);
			}
			*/
        
        
        page = 0;
        
        var spaceX : Int = 8;
        var spaceY : Int = 12;
        
        var numx : Int = 10;
        var numy : Int = 5;
        
        for (y in 0...numy)
        {
            for (x in 0...numx)
            {
                var i : Int = as3hx.Compat.parseInt(x + (y * numx));
                if (i < Levels.list.length)
                {
                    var w : WalkthroughScreen = Walkthrough.walkthroughScreens[i];
                    
                    
                    var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass("WalkthroughScreenshots"));
                    var mc : MovieClip = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
                    mc.gotoAndStop(i + 1);
                    
                    mc.screenIndex = i;
                    mc.x = 10 + (x * (w.thumbW + spaceX));
                    mc.y = 120 + (y * (w.thumbH + spaceY));
                    titleMC.addChild(mc);
                    
                    
                    mc.useHandCursor = true;
                    mc.buttonMode = true;
                    
                    mc.addEventListener(MouseEvent.CLICK, ScreenClicked, false, 0, true);
                    mc.addEventListener(MouseEvent.MOUSE_OVER, ScreenOver, false, 0, true);
                }
            }
        }
    }
    
    
    private var numPages : Int;
    private var numPerPage : Int = 9;
    
    private function InitPage()
    {
        icons = new Array<Dynamic>();
        
        var ox : Int = 145;
        var x : Int = ox;
        var y : Int = 90;
        for (i in 0...numPerPage)
        {
            var mc : LevelIcon = new LevelIcon();
            titleMC.addChild(mc);
            mc.x = x;
            mc.y = y;
            mc.scaleX = 1.6;
            mc.scaleY = 1.6;
            UI.AddAnimatedMCButton(mc, levelPressed, null, false, levelHovered);
            
            x += 150;
            if (x > Defs.displayarea_w - 200)
            {
                x = ox;
                y += 130;
            }
            icons.push(mc);
        }
    }
    
    private var selectedLevel : Int;
    private var icons : Array<Dynamic>;
    
    private function PopulatePage()
    {
        titleMC.prevPage.visible = true;
        titleMC.nextPage.visible = true;
        if (GameVars.currentWalkthroughPage == 0)
        {
            titleMC.prevPage.visible = false;
        }
        if (GameVars.currentWalkthroughPage == numPages - 1)
        {
            titleMC.nextPage.visible = false;
        }
        
        
        var l0 : Int = as3hx.Compat.parseInt(GameVars.currentWalkthroughPage * numPerPage);
        var l1 : Int = as3hx.Compat.parseInt(l0 + (numPerPage - 1));
        
        var mc : MovieClip;
        
        var index : Int = 0;
        for (i in l0...l1 + 1)
        {
            mc = icons[index];
            mc.visible = false;
            if (i < Levels.list.length)
            {
                mc.visible = true;
                var l : Level = Levels.GetLevel(i);
                mc.levelID = i;
                mc.levelNumber.text = Std.string(as3hx.Compat.parseInt(i + 1));
                
                if (Game.usedebug)
                {
                    mc.textLevelCreator.text = l.creator;
                }
                else
                {
                    mc.textLevelCreator.text = "";
                }
                
                
                mc.canPress = false;
                
                mc.coins.gotoAndStop(1);
                mc.gold.gotoAndStop(1);
                mc.gold.visible = false;
                mc.greystar.visible = false;
                mc.cup.visible = false;
                if (l.hasTrophy)
                {
                    mc.cup.visible = true;
                }
                mc.cup.gotoAndStop(l.trophyIndex);
                
                mc.coinpercent.text = l.totalCoins;
                
                if (l.available)
                {
                    mc.canPress = true;
                    mc.levelNumber.visible = true;
                }
                else
                {
                    mc.levelNumber.visible = true;
                }
                
                
                mc.gold.visible = false;
                if (l.rating > 0)
                {
                    mc.gold.visible = true;
                }
                
                /*
					if (l.newlyAvailable)
					{
						mc.newIcon.visible = true;
						mc.newIcon.play();						
					}
					else
					{
						mc.newIcon.visible = false;
						mc.newIcon.stop();			
					}
					*/
                
                index++;
            }
        }
    }
    
    private function PrevPageClicked(e : MouseEvent)
    {
        GameVars.currentWalkthroughPage--;
        if (GameVars.currentWalkthroughPage < 0)
        {
            GameVars.currentWalkthroughPage = numPages - 1;
        }
        PopulatePage();
    }
    private function NextPageClicked(e : MouseEvent)
    {
        GameVars.currentWalkthroughPage++;
        if (GameVars.currentWalkthroughPage >= numPages)
        {
            GameVars.currentWalkthroughPage = 0;
        }
        PopulatePage();
    }
    
    
    private var currentScreenshot : Int;
    private function SaveScreenshots()
    {
        currentScreenshot = 0;
        SaveScreenshot();
    }
    
    private function SaveScreenshot()
    {
        var w : WalkthroughScreen = Walkthrough.walkthroughScreens[currentScreenshot];
        
        var fr : FileReference = new FileReference();
        fr.addEventListener(Event.COMPLETE, SaveScreenshots_CB);
        
        var name : String = "screenshot_level_" + (currentScreenshot + 1) + ".png";
        
        var ba : ByteArray = PNGEncoder.encode(w.thumbBD);
        fr.save(ba, name);
        
        Utils.print("saved level screenshot " + name);
    }
    
    private function SaveScreenshots_CB(e : Event)
    {
        currentScreenshot++;
        if (currentScreenshot < 50)
        {
            SaveScreenshot();
        }
    }
    
    
    private function ScreenOver(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        Levels.currentIndex = mc.screenIndex;
        titleMC.textLevelName.text = Levels.GetCurrent().name;
    }
    private function ScreenClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        Levels.currentIndex = mc.screenIndex;
        UI.StartTransition("walkthrough_screen");
    }
    
    private var adHolder : MovieClip;
    
    private function levelHovered(e : MouseEvent)
    {
        var levelID : Int = e.currentTarget.levelID;
        selectedLevel = levelID;
        var l : Level = Levels.GetLevel(selectedLevel);
        titleMC.textLevelName.text = l.name;
    }
    private function levelPressed(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        Levels.currentIndex = mc.levelID;
        UI.StartTransition("walkthrough_screen");
    }
}

