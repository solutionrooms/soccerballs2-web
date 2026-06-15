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
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_back, buttonBackPressed);
        
        UI.AddGeneric(titleMC);
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_pick0, buttonPick0Pressed);
        UI.AddAnimatedMCButton((untyped titleMC).btn_pick1, buttonPick1Pressed);
        
        UI.AddAnimatedMCButton((untyped titleMC).btn_playgame, buttonContinuePressed);
        
        TextStrings.ReplaceTextFieldText((untyped titleMC.matchPanel).textTitle);
        TextStrings.ReplaceTextFieldText((untyped titleMC).textPlayer);
        TextStrings.ReplaceTextFieldText((untyped titleMC).textComputer);
        
        team0 = GameVars.GetTeam(GameVars.playerTeam);
        team1 = GameVars.GetTeam(GameVars.opponentTeam);
        
        
        (untyped titleMC).textTeamName0.text = team0.teamName;
        (untyped titleMC).textTeamName1.text = team1.teamName;
        
        RenderPlayers();
    }
    
    
    public function buttonContinuePressed(e : MouseEvent)
    {
        UI.WaitAndStartTransition(titleMC, "levelselect");
    }
    
    public var team0 : TeamDef;
    public var team1 : TeamDef;
    
    public function RenderPlayers()
    {
        var team : TeamDef;
        team = GameVars.GetTeam(GameVars.playerTeam);
        RenderPlayer((untyped titleMC).homeTeam.player1, team);
        RenderPlayer((untyped titleMC).homeTeam.player2, team);
        RenderPlayer((untyped titleMC).homeTeam.player3, team);
        RenderPlayer((untyped titleMC).homeTeam.player4, team);
        RenderPlayer((untyped titleMC).homeTeam.player5, team);
        team = GameVars.GetTeam(GameVars.opponentTeam);
        RenderPlayer((untyped titleMC).awayTeam.player1, team);
        RenderPlayer((untyped titleMC).awayTeam.player2, team);
        RenderPlayer((untyped titleMC).awayTeam.player3, team);
        RenderPlayer((untyped titleMC).awayTeam.player4, team);
    }
    
    public function RenderPlayer(mc : MovieClip, team : TeamDef)
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
        
        
        
        (untyped mc).shorts.transform.colorTransform = ct1;
        (untyped mc).socks.transform.colorTransform = ct2;
        (untyped mc).stripes.transform.colorTransform = ct3;
        if ((untyped mc).hoops)
        {
            (untyped mc).hoops.transform.colorTransform = ct3;
        }
        (untyped mc).shirt.transform.colorTransform = ct0;
        
        (untyped mc).stripes.visible = false;
        if ((untyped mc).hoops)
        {
            (untyped mc).hoops.visible = false;
        }
        if (team.kitStyle == 2)
        {
            (untyped mc).stripes.visible = true;
        }
        if (team.kitStyle == 1)
        {
            if ((untyped mc).hoops)
            {
                (untyped mc).hoops.visible = true;
            }
        }
    }
    
    
    public function buttonPick0Pressed(e : MouseEvent)
    {
        GameVars.currentPickTeam = 0;
        UI.WaitAndStartTransition(titleMC, "pickateam");
    }
    public function buttonPick1Pressed(e : MouseEvent)
    {
        GameVars.currentPickTeam = 1;
        UI.WaitAndStartTransition(titleMC, "pickateam");
    }
    
    public function buttonBackPressed(e : MouseEvent)
    {
        SaveData.Save();
        
        UI.WaitAndStartTransition(titleMC, "title");
    }
}



