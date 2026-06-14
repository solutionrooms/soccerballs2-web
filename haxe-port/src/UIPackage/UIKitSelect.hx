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
class UIKitSelect extends UIScreenInstance
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
        
        titleMC = new ScreenModifyTeam();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        
        TextStrings.ReplaceTextFieldText(titleMC.textTitle);
        
        UI.AddBarebonesMCButton(titleMC.btn_shirtPlain, buttonStylePressed);
        UI.AddBarebonesMCButton(titleMC.btn_shirtStripes, buttonStylePressed);
        UI.AddBarebonesMCButton(titleMC.btn_shirtHoops, buttonStylePressed);
        titleMC.btn_shirtPlain.style = 0;
        titleMC.btn_shirtStripes.style = 1;
        titleMC.btn_shirtHoops.style = 2;
        
        UI.AddAnimatedMCButton(titleMC.btn_shirt, buttonKitPressed);
        UI.AddAnimatedMCButton(titleMC.btn_pattern, buttonKitPressed);
        UI.AddAnimatedMCButton(titleMC.btn_shorts, buttonKitPressed);
        UI.AddAnimatedMCButton(titleMC.btn_socks, buttonKitPressed);
        titleMC.btn_shirt.kit_part = 0;
        titleMC.btn_shorts.kit_part = 1;
        titleMC.btn_socks.kit_part = 2;
        titleMC.btn_pattern.kit_part = 3;
        
        
        
        
        
        InitColorButtons(titleMC.palette, 0, "shirt");
        
        team = GameVars.GetTeam(GameVars.currentEditTeamIndex);
        
        
        
        
        UpdateKit();
        
        UpdateColorButtons(titleMC.palette, team.kitColorShirt);
        
        titleMC.textTeamName.text = team.teamName;
    }
    
    private var team : TeamDef;
    
    private var currentKitPart : Int = 0;
    private function buttonKitPressed(e : MouseEvent)
    {
        currentKitPart = e.currentTarget.kit_part;
        Utils.print("kit part " + currentKitPart);
        UpdateKit();
    }
    private function UpdateKit()
    {
        UpdateColorButtons(titleMC.palette, team.kitColorShirt);
        
        
        
        
        
        
        titleMC.btn_shirt.hilight.visible = false;
        titleMC.btn_shorts.hilight.visible = false;
        titleMC.btn_socks.hilight.visible = false;
        titleMC.btn_pattern.hilight.visible = false;
        if (currentKitPart == 0)
        {
            titleMC.btn_shirt.hilight.visible = true;
        }
        if (currentKitPart == 1)
        {
            titleMC.btn_shorts.hilight.visible = true;
        }
        if (currentKitPart == 2)
        {
            titleMC.btn_socks.hilight.visible = true;
        }
        if (currentKitPart == 3)
        {
            titleMC.btn_pattern.hilight.visible = true;
        }
        
        titleMC.btn_shirtPlain.selected.visible = false;
        titleMC.btn_shirtStripes.selected.visible = false;
        titleMC.btn_shirtHoops.selected.visible = false;
        if (team.kitStyle == 0)
        {
            titleMC.btn_shirtPlain.selected.visible = true;
        }
        if (team.kitStyle == 1)
        {
            titleMC.btn_shirtStripes.selected.visible = true;
        }
        if (team.kitStyle == 2)
        {
            titleMC.btn_shirtHoops.selected.visible = true;
        }
        
        var a : Array<Dynamic>;
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        titleMC.btn_shirtPlain.base.transform.colorTransform = ct0;
        titleMC.btn_shirtStripes.base.transform.colorTransform = ct0;
        titleMC.btn_shirtStripes.stripes.transform.colorTransform = ct3;
        titleMC.btn_shirtHoops.base.transform.colorTransform = ct0;
        titleMC.btn_shirtHoops.stripes.transform.colorTransform = ct3;
        
        titleMC.kit.shirt.base.transform.colorTransform = ct0;
        titleMC.kit.shorts.transform.colorTransform = ct1;
        titleMC.kit.socks.transform.colorTransform = ct2;
        titleMC.kit.shirt.hoops.transform.colorTransform = ct3;
        titleMC.kit.shirt.stripes.transform.colorTransform = ct3;
        
        if (team.kitStyle == 0)
        {
            titleMC.kit.shirt.hoops.visible = false;
            titleMC.kit.shirt.stripes.visible = false;
        }
        if (team.kitStyle == 2)
        {
            titleMC.kit.shirt.hoops.visible = false;
            titleMC.kit.shirt.stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            titleMC.kit.shirt.hoops.visible = true;
            titleMC.kit.shirt.stripes.visible = false;
        }
    }
    
    private function UpdateHeads()
    {
        for (i in 0...7)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("player" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            mc.head.gotoAndStop(team.playerHeads[i] + 1);
        }
    }
    private function InitHeads()
    {
        for (i in 0...7)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("player" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton(mc.btn_head, HeadClicked);
            mc.textName.text = team.playerNames[i];
            mc.headIndex = i;
            mc.btn_head.headIndex = i;
        }
    }
    
    
    private function HeadClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        var i : Int = team.playerHeads[mc.headIndex];
        i++;
        if (i >= 10)
        {
            i = 0;
        }
        team.playerHeads[mc.headIndex] = i;
        UpdateHeads();
    }
    
    
    
    
    private var dobj : DisplayObj;
    private var animHierarchy : AnimHierarchy;
    private var player_Race : Int = 0;
    private var player_Head : Int = 0;
    
    
    
    private var bd : BitmapData;
    private var b : Bitmap;
    
    private function InitColorButtons(parentMC : MovieClip, itemIndex : Int, title : String)
    {
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
        if (currentKitPart == 0)
        {
            team.kitColorShirt = mc.colorIndex;
        }
        else if (currentKitPart == 1)
        {
            team.kitColorShorts = mc.colorIndex;
        }
        else if (currentKitPart == 2)
        {
            team.kitColorSocks = mc.colorIndex;
        }
        else
        {
            team.kitColorPattern = mc.colorIndex;
        }
        UpdateColorButtons(titleMC.palette, team.kitColorShirt);
        UpdateKit();
    }
    
    private function UpdateColorButtons(parentMC : MovieClip, selectedIndex : Int)
    {
        if (currentKitPart == 0)
        {
            selectedIndex = team.kitColorShirt;
        }
        else if (currentKitPart == 1)
        {
            selectedIndex = team.kitColorShorts;
        }
        else if (currentKitPart == 2)
        {
            selectedIndex = team.kitColorSocks;
        }
        else
        {
            selectedIndex = team.kitColorPattern;
        }
        
        for (i in 0...16)
        {
            var mc : MovieClip = try cast(parentMC.getChildByName("color" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            mc.highlight.visible = false;
            if (i == selectedIndex)
            {
                mc.highlight.visible = true;
            }
        }
    }
    
    private function buttonStylePressed(e : MouseEvent)
    {
        team.kitStyle = e.currentTarget.style;
        
        currentKitPart = 3;
        
        UpdateKit();
    }
    
    
    
    private function buttonBackPressed(e : MouseEvent)
    {
        team.teamName = titleMC.textTeamName.text;
        SaveData.Save();
        
        
        UI.StartTransition("matchselect");
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



