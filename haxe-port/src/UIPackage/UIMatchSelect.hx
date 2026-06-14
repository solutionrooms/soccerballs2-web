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
class UIMatchSelect extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        UI.RemoveAllButtons();
        UI.RemoveGeneric();
    }
    
    override public function InitScreen()
    {
        Audio.PlayMusic("menus_music");
        
        UI.StartAddButtons();
        
        Mouse.show();
        
        titleMC = new ScreenMatchSelect();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        UI.AddGeneric(titleMC);
        
        UI.AddAnimatedMCButton(titleMC.btn_pick0, buttonPick0Pressed);
        UI.AddAnimatedMCButton(titleMC.btn_pick1, buttonPick1Pressed);
        
        UI.AddAnimatedMCButton(titleMC.btn_playgame, buttonContinuePressed);
        
        TextStrings.ReplaceTextFieldText(titleMC.matchPanel.textTitle);
        TextStrings.ReplaceTextFieldText(titleMC.textPlayer);
        TextStrings.ReplaceTextFieldText(titleMC.textComputer);
        
        team0 = GameVars.GetTeam(GameVars.playerTeam);
        team1 = GameVars.GetTeam(GameVars.opponentTeam);
        
        
        titleMC.textTeamName0.text = team0.teamName;
        titleMC.textTeamName1.text = team1.teamName;
        
        RenderPlayers();
    }
    
    
    public function buttonContinuePressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "levelselect");
    }
    
    private var team0 : TeamDef;
    private var team1 : TeamDef;
    
    private function RenderPlayers()
    {
        var team : TeamDef;
        team = GameVars.GetTeam(GameVars.playerTeam);
        RenderPlayer(titleMC.homeTeam.player1, team);
        RenderPlayer(titleMC.homeTeam.player2, team);
        RenderPlayer(titleMC.homeTeam.player3, team);
        RenderPlayer(titleMC.homeTeam.player4, team);
        RenderPlayer(titleMC.homeTeam.player5, team);
        team = GameVars.GetTeam(GameVars.opponentTeam);
        RenderPlayer(titleMC.awayTeam.player1, team);
        RenderPlayer(titleMC.awayTeam.player2, team);
        RenderPlayer(titleMC.awayTeam.player3, team);
        RenderPlayer(titleMC.awayTeam.player4, team);
    }
    
    private function RenderPlayer(mc : MovieClip, team : TeamDef)
    {
        var a : Array<Dynamic>;
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        
        mc.shorts.transform.colorTransform = ct1;
        mc.socks.transform.colorTransform = ct2;
        mc.stripes.transform.colorTransform = ct3;
        if (mc.hoops)
        {
            mc.hoops.transform.colorTransform = ct3;
        }
        mc.shirt.transform.colorTransform = ct0;
        
        mc.stripes.visible = false;
        if (mc.hoops)
        {
            mc.hoops.visible = false;
        }
        if (team.kitStyle == 2)
        {
            mc.stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            if (mc.hoops)
            {
                mc.hoops.visible = true;
            }
        }
    }
    
    
    private function buttonPick0Pressed(e : MouseEvent)
    {
        GameVars.currentPickTeam = 0;
        UI.WaitAndStartTransition(titleMC, "pickateam");
    }
    private function buttonPick1Pressed(e : MouseEvent)
    {
        GameVars.currentPickTeam = 1;
        UI.WaitAndStartTransition(titleMC, "pickateam");
    }
    
    private function buttonBackPressed(e : MouseEvent)
    {
        SaveData.Save();
        
        UI.WaitAndStartTransition(titleMC, "title");
    }
}



