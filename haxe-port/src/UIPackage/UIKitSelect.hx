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
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_back, buttonBackPressed);
        
        
        TextStrings.ReplaceTextFieldText((untyped titleMC).textTitle);
        
        UI.AddBarebonesMCButton((untyped titleMC).btn_shirtPlain, buttonStylePressed);
        UI.AddBarebonesMCButton((untyped titleMC).btn_shirtStripes, buttonStylePressed);
        UI.AddBarebonesMCButton((untyped titleMC).btn_shirtHoops, buttonStylePressed);
        (untyped titleMC).btn_shirtPlain.style = 0;
        (untyped titleMC).btn_shirtStripes.style = 1;
        (untyped titleMC).btn_shirtHoops.style = 2;
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_shirt, buttonKitPressed);
        UI.AddAnimatedMCButton((untyped titleMC).btn_pattern, buttonKitPressed);
        UI.AddAnimatedMCButton((untyped titleMC).btn_shorts, buttonKitPressed);
        UI.AddAnimatedMCButton((untyped titleMC).btn_socks, buttonKitPressed);
        (untyped titleMC).btn_shirt.kit_part = 0;
        (untyped titleMC).btn_shorts.kit_part = 1;
        (untyped titleMC).btn_socks.kit_part = 2;
        (untyped titleMC).btn_pattern.kit_part = 3;
        
        
        
        
        
        InitColorButtons((untyped titleMC).palette, 0, "shirt");
        
        team = GameVars.GetTeam(GameVars.currentEditTeamIndex);
        
        
        
        
        UpdateKit();
        
        UpdateColorButtons((untyped titleMC).palette, team.kitColorShirt);
        
        (untyped titleMC).textTeamName.text = Std.string(team.teamName);
    }
    
    public var team : TeamDef;
    
    public var currentKitPart : Int = 0;
    public function buttonKitPressed(e : MouseEvent)
    {
        currentKitPart = e.currentTarget.kit_part;
        Utils.print("kit part " + currentKitPart);
        UpdateKit();
    }
    public function UpdateKit()
    {
        UpdateColorButtons((untyped titleMC).palette, team.kitColorShirt);
        
        
        
        
        
        
        (untyped titleMC).btn_shirt.hilight.visible = false;
        (untyped titleMC).btn_shorts.hilight.visible = false;
        (untyped titleMC).btn_socks.hilight.visible = false;
        (untyped titleMC).btn_pattern.hilight.visible = false;
        if (currentKitPart == 0)
        {
            (untyped titleMC).btn_shirt.hilight.visible = true;
        }
        if (currentKitPart == 1)
        {
            (untyped titleMC).btn_shorts.hilight.visible = true;
        }
        if (currentKitPart == 2)
        {
            (untyped titleMC).btn_socks.hilight.visible = true;
        }
        if (currentKitPart == 3)
        {
            (untyped titleMC).btn_pattern.hilight.visible = true;
        }
        
        (untyped titleMC.btn_shirtPlain).selected.visible = false;
        (untyped titleMC.btn_shirtStripes).selected.visible = false;
        (untyped titleMC.btn_shirtHoops).selected.visible = false;
        if (team.kitStyle == 0)
        {
            (untyped titleMC.btn_shirtPlain).selected.visible = true;
        }
        if (team.kitStyle == 1)
        {
            (untyped titleMC.btn_shirtStripes).selected.visible = true;
        }
        if (team.kitStyle == 2)
        {
            (untyped titleMC.btn_shirtHoops).selected.visible = true;
        }
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        (untyped titleMC).btn_shirtPlain.base.transform.colorTransform = ct0;
        (untyped titleMC).btn_shirtStripes.base.transform.colorTransform = ct0;
        (untyped titleMC.btn_shirtStripes).stripes.transform.colorTransform = ct3;
        (untyped titleMC).btn_shirtHoops.base.transform.colorTransform = ct0;
        (untyped titleMC.btn_shirtHoops).stripes.transform.colorTransform = ct3;
        
        (untyped titleMC.kit).shirt.base.transform.colorTransform = ct0;
        (untyped titleMC.kit).shorts.transform.colorTransform = ct1;
        (untyped titleMC.kit).socks.transform.colorTransform = ct2;
        (untyped titleMC.kit.shirt).hoops.transform.colorTransform = ct3;
        (untyped titleMC.kit.shirt).stripes.transform.colorTransform = ct3;
        
        if (team.kitStyle == 0)
        {
            (untyped titleMC.kit.shirt).hoops.visible = false;
            (untyped titleMC.kit.shirt).stripes.visible = false;
        }
        if (team.kitStyle == 2)
        {
            (untyped titleMC.kit.shirt).hoops.visible = false;
            (untyped titleMC.kit.shirt).stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            (untyped titleMC.kit.shirt).hoops.visible = true;
            (untyped titleMC.kit.shirt).stripes.visible = false;
        }
    }
    
    public function UpdateHeads()
    {
        for (i in 0...7)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("player" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            (untyped mc).head.gotoAndStop(team.playerHeads[i] + 1);
        }
    }
    public function InitHeads()
    {
        for (i in 0...7)
        {
            var mc : MovieClip = try cast(titleMC.getChildByName("player" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
            UI.AddAnimatedMCButton((untyped mc).btn_head, HeadClicked);
            (untyped mc).textName.text = team.playerNames[i];
            (untyped mc).headIndex = i;
            (untyped mc.btn_head).headIndex = i;
        }
    }
    
    
    public function HeadClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        var i : Int = team.playerHeads[(untyped mc).headIndex];
        i++;
        if (i >= 10)
        {
            i = 0;
        }
        team.playerHeads[(untyped mc).headIndex] = i;
        UpdateHeads();
    }
    
    
    
    
    public var dobj : DisplayObj;
    public var animHierarchy : AnimHierarchy;
    public var player_Race : Int = 0;
    public var player_Head : Int = 0;
    
    
    
    public var bd : BitmapData;
    public var b : Bitmap;
    
    public function InitColorButtons(parentMC : MovieClip, itemIndex : Int, title : String)
    {
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
        if (currentKitPart == 0)
        {
            team.kitColorShirt = (untyped mc).colorIndex;
        }
        else if (currentKitPart == 1)
        {
            team.kitColorShorts = (untyped mc).colorIndex;
        }
        else if (currentKitPart == 2)
        {
            team.kitColorSocks = (untyped mc).colorIndex;
        }
        else
        {
            team.kitColorPattern = (untyped mc).colorIndex;
        }
        UpdateColorButtons((untyped titleMC).palette, team.kitColorShirt);
        UpdateKit();
    }
    
    public function UpdateColorButtons(parentMC : MovieClip, selectedIndex : Int)
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
            (untyped mc).highlight.visible = false;
            if (i == selectedIndex)
            {
                (untyped mc).highlight.visible = true;
            }
        }
    }
    
    public function buttonStylePressed(e : MouseEvent)
    {
        team.kitStyle = e.currentTarget.style;
        
        currentKitPart = 3;
        
        UpdateKit();
    }
    
    
    
    public function buttonBackPressed(e : MouseEvent)
    {
        team.teamName = (untyped titleMC).textTeamName.text;
        SaveData.Save();
        
        
        UI.StartTransition("matchselect");
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



