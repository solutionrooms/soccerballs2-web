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
    
    public static var usePrePlacedLevels : Bool = true;
    
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
        
        TextStrings.ReplaceTextFieldText((untyped titleMC).textTitle);
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_back, buttonBackPressed);
        
        UI.AddAnimatedMCButton((untyped titleMC).prevPage, PrevPageClicked);
        UI.AddAnimatedMCButton((untyped titleMC).nextPage, NextPageClicked);
        
        UI.AddGeneric(titleMC);
        
        
        numPages = 4;
        
        currentPage = 0;
        InitPage();
        PopulatePage();
        
        
        
        
        
        
        
        UpdateChange();
        
        GameVars.InitTrophiesClip((untyped titleMC).trophies);
        GameVars.InitCoinBoxClip((untyped titleMC).coinBox);
    }
    
    public var selectedLevel : Int;
    
    public var numPages : Int;
    public var numPerPage : Int = 9;
    public var currentPage : Int;
    
    public function InitPage()
    {
        icons = [];
        
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
    
    public var icons : Array<Dynamic>;
    
    public function PopulatePage()
    {
        (untyped titleMC).prevPage.visible = true;
        (untyped titleMC).nextPage.visible = true;
        if (currentPage == 0)
        {
            (untyped titleMC).prevPage.visible = false;
        }
        if (currentPage == numPages - 1)
        {
            (untyped titleMC).nextPage.visible = false;
        }
        
        
        var l0 : Int = as3hx.Compat.parseInt(currentPage * numPerPage);
        var l1 : Int = as3hx.Compat.parseInt(l0 + (numPerPage - 1));
        
        var mc : MovieClip = null;        
        var index : Int = 0;
        for (i in l0...l1 + 1)
        {
            mc = icons[index];
            mc.visible = false;
            if (i < Levels.list.length)
            {
                mc.visible = true;
                var l : Level = Levels.GetLevel(i);
                (untyped mc).levelID = i;
                (untyped mc).levelNumber.text = Std.string(as3hx.Compat.parseInt(i + 1));
                
                if (Game.usedebug)
                {
                    (untyped mc).textLevelCreator.text = l.creator;
                }
                else
                {
                    (untyped mc).textLevelCreator.text = "";
                }
                
                var lll : Int = Levels.currentIndex;
                Levels.currentIndex = i;
                GameVars.CalculateNumCoinsInLevel();
                GameVars.CalculateNumLevelCoinsCollected();
                var totalC : Int = GameVars.totalLevelCoins;
                var numC : Int = GameVars.numLevelCoinsCollected;
                Levels.currentIndex = lll;
                
                var coinPC : Int = as3hx.Compat.parseInt(numC * 100 / totalC);
                
                
                (untyped mc).coinpercent.text = coinPC + "%";
                
                (untyped mc).canPress = false;
                
                (untyped mc).coins.gotoAndStop(1);
                (untyped mc).gold.gotoAndStop(1);
                (untyped mc).cup.visible = false;
                (untyped mc).cup.gotoAndStop(1);
                
                if (l.available)
                {
                    (untyped mc).canPress = true;
                    
                    (untyped mc).levelNumber.visible = true;
                    mc.filters = [];
                }
                else
                {
                    (untyped mc).levelNumber.visible = true;
                    mc.filters = [UI.greyFilter];
                }
                
                
                (untyped mc).gold.visible = false;
                if (l.rating > 0)
                {
                    (untyped mc).gold.visible = true;
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
    
    public function PrevPageClicked(e : MouseEvent)
    {
        currentPage--;
        if (currentPage < 0)
        {
            currentPage = as3hx.Compat.parseInt(numPages - 1);
        }
        PopulatePage();
    }
    public function NextPageClicked(e : MouseEvent)
    {
        currentPage++;
        if (currentPage >= numPages)
        {
            currentPage = 0;
        }
        PopulatePage();
    }
    
    public function LockedGiftShopClicked(e : MouseEvent)
    {
    }
    public function GiftShopClicked(e : MouseEvent)
    {
        UI.StartTransition("giftshopscreen");
    }
    public function ArcadeClicked(e : MouseEvent)
    {
        UI.StartTransition("arcadescreen");
    }
    
    public function SetLevelProgress()
    {
        var progress : Float = GameVars.GetLevelProgress();
        
        var maxf : Int = (untyped titleMC.progressBar).progressBar.totalFrames;
        
        var f : Int = Std.int(Utils.ScaleTo(1, maxf, 0, 1, progress));
        (untyped titleMC.progressBar).progressBar.gotoAndStop(f);
        (untyped titleMC).progressBar.percent.text = Math.round(progress * 100);
        (untyped titleMC).textNumGold.text = GameVars.GetNumBonusGold();
    }
    
    public function buttonAchievementsPressed(e : MouseEvent)
    {
        UI.StartTransition("achievements", null, "levelselect");
    }
    
    
    public function UpdateChange()
    {
        if (selectedLevel == -1)
        {
        }
        else
        {
            var level : Level = Levels.GetLevel(selectedLevel);
            (untyped titleMC).textInfo.text = level.displayName;
        }
    }
    public function levelOut(e : MouseEvent)
    {
        selectedLevel = -1;
        
        UpdateChange();
    }
    
    
    
    public function buttonBackPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    
    public function RemoveListeners()
    {
        if (usePrePlacedLevels)
        {
            return;
        }
        var i : Int = 0;        for (i in 0...Levels.list.length)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("track" + i), MovieClip) catch(e:Dynamic) null;
            mc.removeEventListener(MouseEvent.CLICK, levelPressed);
        }
    }
    
    public function TryBuyLevelCB(yes : Bool)
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
    public function TryBuyLevel()
    {
        var l : Level = Levels.GetLevel(selectedLevel);
        if (Game.cash >= l.cost)
        {
            var s : String = "Buy a pass for " + l.name + " ($" + l.cost + ") ?";
            UI.AddAreYouSureDialog(titleMC, s, TryBuyLevelCB);
        }
    }
    
    
    public function levelOver(e : MouseEvent)
    {
        var levelID : Int = (untyped e.currentTarget).levelID;
        var l : Level = Levels.GetLevel(levelID);
        (untyped titleMC).levelNameText.text = l.name;
    }
    public function levelHovered(e : MouseEvent)
    {
        var levelID : Int = (untyped e.currentTarget).levelID;
        selectedLevel = levelID;
        var l : Level = Levels.GetLevel(selectedLevel);
        (untyped titleMC).textLevelName.text = l.name;
    }
    public function levelPressed(e : MouseEvent)
    {
        var cando : Bool = false;
        
        var levelID : Int = (untyped e.currentTarget).levelID;
        selectedLevel = levelID;
        
        
        if (Game.usedebug == false)
        {
            if ((untyped e.currentTarget).canPress == false)
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


