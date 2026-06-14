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
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        TextStrings.ReplaceTextFieldText(titleMC.textTitle);
        
        
        
        InitTeamButtons();
        
        if (Game.usedebug)
        {
            ExportKits();
        }
    }
    private function ExportKits()
    {
        var s : String = "";
        for (i in 0...9)
        {
            var tm : TeamDef = GameVars.GetTeam(i);
            
            var s1 : String;
            
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
    
    private function InitTeamButtons()
    {
        for (i in 0...9)
        {
            var tm : TeamDef = GameVars.GetTeam(i);
            var mc : MovieClip = try cast(titleMC.getChildByName("team" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton(mc.btn_yes, PickClicked);
            UI.AddAnimatedMCButton(mc.btn_modify, ModifyClicked);
            mc.textTeamName.text = tm.teamName;
            mc.btn_yes.teamIndex = i;
            mc.btn_modify.teamIndex = i;
            InitShirt(mc, tm);
        }
    }
    
    private function InitShirt(mc : MovieClip, team : TeamDef)
    {
        var a : Array<Dynamic>;
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        mc.shirt.base.transform.colorTransform = ct0;
        mc.shirt.hoops.transform.colorTransform = ct3;
        mc.shirt.stripes.transform.colorTransform = ct3;
        
        if (team.kitStyle == 0)
        {
            mc.shirt.hoops.visible = false;
            mc.shirt.stripes.visible = false;
        }
        if (team.kitStyle == 2)
        {
            mc.shirt.hoops.visible = false;
            mc.shirt.stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            mc.shirt.hoops.visible = true;
            mc.shirt.stripes.visible = false;
        }
    }
    
    private function PickClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        GameVars.currentEditTeamIndex = mc.teamIndex;
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
    private function ModifyClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        GameVars.currentEditTeamIndex = mc.teamIndex;
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
    
    
    private var team : TeamDef;
    private var team0 : TeamDef;
    private var team1 : TeamDef;
    
    private function RenderPlayer()
    {
        dobj = GraphicObjects.GetDisplayObjByName("player");
        
        var a : Array<Dynamic>;
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
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
    
    
    private var dobj : DisplayObj;
    private var animHierarchy : AnimHierarchy;
    private var player_Race : Int = 0;
    private var player_Head : Int = 0;
    
    
    
    private var bd : BitmapData;
    private var b : Bitmap;
    
    private function InitColorButtons(parentMC : MovieClip, itemIndex : Int, title : String)
    {
        parentMC.title.text = title;
        for (i in 0...16)
        {
            var mc : MovieClip = try cast(parentMC.getChildByName("color" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton(mc, ColorClicked);
            mc.colorIndex = i;
            mc.itemIndex = itemIndex;
            var a : Array<Dynamic> = GameVars.GetKitColorRGBArrayByIndex(i);
            mc.color.transform.colorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2]);
        }
    }
    
    private function ColorClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        if (mc.itemIndex == 0)
        {
            team.kitColorShirt = mc.colorIndex;
        }
        else if (mc.itemIndex == 1)
        {
            team.kitColorShorts = mc.colorIndex;
        }
        else if (mc.itemIndex == 2)
        {
            team.kitColorSocks = mc.colorIndex;
        }
        else
        {
            team.kitColorPattern = mc.colorIndex;
        }
        UpdateColorButtons(titleMC.palette0, team.kitColorShirt);
        UpdateColorButtons(titleMC.palette1, team.kitColorShorts);
        UpdateColorButtons(titleMC.palette2, team.kitColorSocks);
        UpdateColorButtons(titleMC.palette3, team.kitColorPattern);
        RenderPlayer();
    }
    
    private function UpdateColorButtons(parentMC : MovieClip, selectedIndex : Int)
    {
        for (i in 0...16)
        {
            var mc : MovieClip = try cast(parentMC.getChildByName("color" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            mc.selected.visible = false;
            if (i == selectedIndex)
            {
                mc.selected.visible = true;
            }
        }
    }
    
    private function buttonStylePressed(e : MouseEvent)
    {
        team.kitStyle++;
        team.kitStyle %= 3;
        RenderPlayer();
    }
    
    
    private function buttonPick0Pressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "kitselect");
    }
    private function buttonPick1Pressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "kitselect");
    }
    
    private function buttonBackPressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "matchselect");
    }
    
    
    private function AddHierarchy_Player(ct_shirt : ColorTransform, ct_shorts : ColorTransform, ct_socks : ColorTransform, ct_pattern : ColorTransform)
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


