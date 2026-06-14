package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;
import flash.ui.Mouse;
import licPackage.Lic;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UILevelSelect extends UIScreenInstance
{
    
    private static var usePrePlacedLevels : Bool = true;
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        UI.RemoveAllButtons();
        UI.RemoveGeneric();
    }
    
    public static var greyFilter : ColorMatrixFilter = new ColorMatrixFilter([0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0.3086, 0.6094, 0.0820, 0, 0, 0, 0, 0, 1, 0]);
    
    override public function InitScreen()
    {
        Audio.PlayMusic("menus_music");
        
        UI.StartAddButtons();
        
        Mouse.show();
        selectedLevel = -1;
        
        titleMC = new ScreenLevelSelect();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        TextStrings.ReplaceTextFieldText(titleMC.textTitle);
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        UI.AddAnimatedMCButton(titleMC.prevPage, PrevPageClicked);
        UI.AddAnimatedMCButton(titleMC.nextPage, NextPageClicked);
        
        UI.AddGeneric(titleMC);
        
        
        numPages = 4;
        
        currentPage = 0;
        InitPage();
        PopulatePage();
        
        
        
        UpdateChange();
        
        GameVars.InitTrophiesClip(titleMC.trophies);
        GameVars.InitCoinBoxClip(titleMC.coinBox);
    }
    
    private var selectedLevel : Int;
    
    private var numPages : Int;
    private var numPerPage : Int = 9;
    private var currentPage : Int;
    
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
    
    private var icons : Array<Dynamic>;
    
    private function PopulatePage()
    {
        titleMC.prevPage.visible = true;
        titleMC.nextPage.visible = true;
        if (currentPage == 0)
        {
            titleMC.prevPage.visible = false;
        }
        if (currentPage == numPages - 1)
        {
            titleMC.nextPage.visible = false;
        }
        
        
        var l0 : Int = as3hx.Compat.parseInt(currentPage * numPerPage);
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
                
                var lll : Int = Levels.currentIndex;
                Levels.currentIndex = i;
                GameVars.CalculateNumCoinsInLevel();
                GameVars.CalculateNumLevelCoinsCollected();
                var totalC : Int = GameVars.totalLevelCoins;
                var numC : Int = GameVars.numLevelCoinsCollected;
                Levels.currentIndex = lll;
                
                var coinPC : Int = as3hx.Compat.parseInt(numC * 100 / totalC);
                
                
                mc.coinpercent.text = coinPC + "%";
                
                mc.canPress = false;
                
                mc.coins.gotoAndStop(1);
                mc.gold.gotoAndStop(1);
                mc.cup.visible = false;
                mc.cup.gotoAndStop(1);
                
                if (l.available)
                {
                    mc.canPress = true;
                    mc.levelNumber.visible = true;
                    mc.filters = [];
                }
                else
                {
                    mc.levelNumber.visible = true;
                    mc.filters = [UI.greyFilter];
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
        currentPage--;
        if (currentPage < 0)
        {
            currentPage = as3hx.Compat.parseInt(numPages - 1);
        }
        PopulatePage();
    }
    private function NextPageClicked(e : MouseEvent)
    {
        currentPage++;
        if (currentPage >= numPages)
        {
            currentPage = 0;
        }
        PopulatePage();
    }
    
    private function LockedGiftShopClicked(e : MouseEvent)
    {
    }
    private function GiftShopClicked(e : MouseEvent)
    {
        UI.StartTransition("giftshopscreen");
    }
    private function ArcadeClicked(e : MouseEvent)
    {
        UI.StartTransition("arcadescreen");
    }
    
    private function SetLevelProgress()
    {
        var progress : Float = GameVars.GetLevelProgress();
        
        var maxf : Int = titleMC.progressBar.progressBar.totalFrames;
        
        var f : Int = Utils.ScaleTo(1, maxf, 0, 1, progress);
        titleMC.progressBar.progressBar.gotoAndStop(f);
        titleMC.progressBar.percent.text = Math.round(progress * 100);
        titleMC.textNumGold.text = GameVars.GetNumBonusGold();
    }
    
    public function buttonAchievementsPressed(e : MouseEvent)
    {
        UI.StartTransition("achievements", null, "levelselect");
    }
    
    
    private function UpdateChange()
    {
        if (selectedLevel == -1)
        {
        }
        else
        {
            var level : Level = Levels.GetLevel(selectedLevel);
            titleMC.textInfo.text = level.displayName;
        }
    }
    private function levelOut(e : MouseEvent)
    {
        selectedLevel = -1;
        UpdateChange();
    }
    
    
    
    private function buttonBackPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    
    private function RemoveListeners()
    {
        if (usePrePlacedLevels)
        {
            return;
        }
        var i : Int;
        for (i in 0...Levels.list.length)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("track" + i), MovieClip) catch(e:Dynamic) null;
            mc.removeEventListener(MouseEvent.CLICK, levelPressed);
        }
    }
    
    private function TryBuyLevelCB(yes : Bool)
    {
        if (yes)
        {
            var l : Level = Levels.GetLevel(selectedLevel);
            Game.cash -= l.cost;
            l.owned = true;
            UpdateChange();
            UI.UpdateGeneric();
        }
    }
    private function TryBuyLevel()
    {
        var l : Level = Levels.GetLevel(selectedLevel);
        if (Game.cash >= l.cost)
        {
            var s : String = "Buy a pass for " + l.name + " ($" + l.cost + ") ?";
            UI.AddAreYouSureDialog(titleMC, s, TryBuyLevelCB);
        }
    }
    
    
    private function levelOver(e : MouseEvent)
    {
        var levelID : Int = e.currentTarget.levelID;
        var l : Level = Levels.GetLevel(levelID);
        titleMC.levelNameText.text = l.name;
    }
    private function levelHovered(e : MouseEvent)
    {
        var levelID : Int = e.currentTarget.levelID;
        selectedLevel = levelID;
        var l : Level = Levels.GetLevel(selectedLevel);
        titleMC.textLevelName.text = l.name;
    }
    private function levelPressed(e : MouseEvent)
    {
        var cando : Bool = false;
        
        var levelID : Int = e.currentTarget.levelID;
        selectedLevel = levelID;
        
        
        if (Game.usedebug == false)
        {
            if (e.currentTarget.canPress == false)
            {
                return;
            }
        }
        
        
        var l : Level = Levels.GetLevel(levelID);
        
        
        l.newlyAvailable = false;
        
        Levels.currentIndex = levelID;
        
        UI.WaitAndStartTransition(titleMC, "gamescreen");
    }
}

