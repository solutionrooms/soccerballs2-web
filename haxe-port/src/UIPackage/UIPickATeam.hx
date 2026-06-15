package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import licPackage.Lic;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIPickATeam extends UIScreenInstance
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
        Audio.PlayMusic("menus_music");
        
        UI.StartAddButtons();
        
        Mouse.show();
        
        titleMC = new ScreenPickATeamAlt();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_back, buttonBackPressed);
        
        TextStrings.ReplaceTextFieldText((untyped titleMC).textTitle);
        
        
        
        
        InitTeamButtons();
        
        if (Game.usedebug)
        {
            ExportKits();
        }
    }
    public function ExportKits()
    {
        var s : String = "";
        for (i in 0...9)
        {
            var tm : TeamDef = GameVars.GetTeam(i);
            
            var s1 : String = null;            
            s += "\t\t\tteams[" + i + "].teamName = '" + tm.teamName + "';";
            s += "\n";
            s += "\t\t\tteams[" + i + "].kitColorPattern = " + tm.kitColorPattern + ";";
            s += "\n";
            s += "\t\t\tteams[" + i + "].kitColorShirt = " + tm.kitColorShirt + ";";
            s += "\n";
            s += "\t\t\tteams[" + i + "].kitColorShorts = " + tm.kitColorShorts + ";";
            s += "\n";
            s += "\t\t\tteams[" + i + "].kitColorSocks = " + tm.kitColorSocks + ";";
            s += "\n";
            s += "\t\t\tteams[" + i + "].kitStyle = " + tm.kitStyle + ";";
            s += "\n";
            s += "\n";
        }
        Utils.print(s);
        ExternalData.OutputString(s);
    }
    
    public function InitTeamButtons()
    {
        for (i in 0...9)
        {
            var tm : TeamDef = GameVars.GetTeam(i);
            var mc : MovieClip = try cast(titleMC.getChildByName("team" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton((untyped mc).btn_yes, PickClicked);
            UI.AddAnimatedMCButton((untyped mc).btn_modify, ModifyClicked);
            (untyped mc).textTeamName.text = tm.teamName;
            (untyped mc.btn_yes).teamIndex = i;
            (untyped mc.btn_modify).teamIndex = i;
            InitShirt(mc, tm);
        }
    }
    
    public function InitShirt(mc : MovieClip, team : TeamDef)
    {
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        (untyped mc).shirt.base.transform.colorTransform = ct0;
        (untyped mc.shirt).hoops.transform.colorTransform = ct3;
        (untyped mc.shirt).stripes.transform.colorTransform = ct3;
        
        if (team.kitStyle == 0)
        {
            (untyped mc.shirt).hoops.visible = false;
            (untyped mc.shirt).stripes.visible = false;
        }
        if (team.kitStyle == 2)
        {
            (untyped mc.shirt).hoops.visible = false;
            (untyped mc.shirt).stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            (untyped mc.shirt).hoops.visible = true;
            (untyped mc.shirt).stripes.visible = false;
        }
    }
    
    public function PickClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        GameVars.currentEditTeamIndex = (untyped mc).teamIndex;
        if (GameVars.currentPickTeam == 0)
        {
            GameVars.playerTeam = GameVars.currentEditTeamIndex;
        }
        else
        {
            GameVars.opponentTeam = GameVars.currentEditTeamIndex;
        }
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    public function ModifyClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        GameVars.currentEditTeamIndex = (untyped mc).teamIndex;
        if (GameVars.currentPickTeam == 0)
        {
            GameVars.playerTeam = GameVars.currentEditTeamIndex;
        }
        else
        {
            GameVars.opponentTeam = GameVars.currentEditTeamIndex;
        }
        UI.WaitAndStartTransition(titleMC, "kitscreen");
    }
    
    
    public var team : TeamDef;
    public var team0 : TeamDef;
    public var team1 : TeamDef;
    
    public function RenderPlayer()
    {
        dobj = GraphicObjects.GetDisplayObjByName("player");
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        AddHierarchy_Player(ct0, ct1, ct2, ct3);
        bd.fillRect(bd.rect, 0);
        animHierarchy.RenderAt(bd, 350, 450, 0, 3, 0, false, true);
    }
    
    
    public var dobj : DisplayObj;
    public var animHierarchy : AnimHierarchy;
    public var player_Race : Int = 0;
    public var player_Head : Int = 0;
    
    
    
    public var bd : BitmapData;
    public var b : Bitmap;
    
    public function InitColorButtons(parentMC : MovieClip, itemIndex : Int, title : String)
    {
        (untyped parentMC).title.text = title;
        for (i in 0...16)
        {
            var mc : MovieClip = try cast(parentMC.getChildByName("color" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton(mc, ColorClicked);
            (untyped mc).colorIndex = i;
            (untyped mc).itemIndex = itemIndex;
            var a : Array<Dynamic> = GameVars.GetKitColorRGBArrayByIndex(i);
            (untyped mc).color.transform.colorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2]);
        }
    }
    
    public function ColorClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        if ((untyped mc).itemIndex == 0)
        {
            team.kitColorShirt = (untyped mc).colorIndex;
        }
        else if ((untyped mc).itemIndex == 1)
        {
            team.kitColorShorts = (untyped mc).colorIndex;
        }
        else if ((untyped mc).itemIndex == 2)
        {
            team.kitColorSocks = (untyped mc).colorIndex;
        }
        else
        {
            team.kitColorPattern = (untyped mc).colorIndex;
        }
        UpdateColorButtons((untyped titleMC).palette0, team.kitColorShirt);
        UpdateColorButtons((untyped titleMC).palette1, team.kitColorShorts);
        UpdateColorButtons((untyped titleMC).palette2, team.kitColorSocks);
        UpdateColorButtons((untyped titleMC).palette3, team.kitColorPattern);
        RenderPlayer();
    }
    
    public function UpdateColorButtons(parentMC : MovieClip, selectedIndex : Int)
    {
        for (i in 0...16)
        {
            var mc : MovieClip = try cast(parentMC.getChildByName("color" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            (untyped mc).selected.visible = false;
            if (i == selectedIndex)
            {
                (untyped mc).selected.visible = true;
            }
        }
    }
    
    public function buttonStylePressed(e : MouseEvent)
    {
        team.kitStyle++;
        team.kitStyle %= 3;
        RenderPlayer();
    }
    
    
    public function buttonPick0Pressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "kitselect");
    }
    public function buttonPick1Pressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "kitselect");
    }
    
    public function buttonBackPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    
    
    public function AddHierarchy_Player(ct_shirt : ColorTransform, ct_shorts : ColorTransform, ct_socks : ColorTransform, ct_pattern : ColorTransform)
    {
        player_Race = 0;
        player_Head = 0;
        
        
        
        animHierarchy.SetPartColourTransform("body.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("body.tint_hoops", ct_pattern);
        animHierarchy.SetPartColourTransform("body.tint_stripes", ct_pattern);
        animHierarchy.SetPartColourTransform("upperArmRight.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("upperArmLeft.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("upperLegRight.tint", ct_shorts);
        animHierarchy.SetPartColourTransform("upperLegLeft.tint", ct_shorts);
        animHierarchy.SetPartColourTransform("footLeft.tint", ct_socks);
        animHierarchy.SetPartColourTransform("footRight.tint", ct_socks);
        
        animHierarchy.SetPartVisible("body.tint", true);
        
        var style : Int = team.kitStyle;
        if (style == 0)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", false);
            animHierarchy.SetPartVisible("body.tint_stripes", false);
        }
        if (style == 1)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", true);
            animHierarchy.SetPartVisible("body.tint_stripes", false);
        }
        if (style == 2)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", false);
            animHierarchy.SetPartVisible("body.tint_stripes", true);
        }
        
        
        if (player_Race == 1)
        {
            animHierarchy.SetPartFrame("upperArmRight", 1);
            animHierarchy.SetPartFrame("lowerArmRight", 1);
            animHierarchy.SetPartFrame("upperLegRight", 1);
            animHierarchy.SetPartFrame("footRight", 1);
            animHierarchy.SetPartFrame("upperLegLeft", 1);
            animHierarchy.SetPartFrame("footLeft", 1);
            animHierarchy.SetPartFrame("upperArmLeft", 1);
            animHierarchy.SetPartFrame("lowerArmLeft", 1);
        }
        animHierarchy.SetPartFrame("head", player_Head);
    }
}



