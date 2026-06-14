package uIPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class UIHelpScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
    }
    private static var helpPage : Int;
    private static var numHelpPages : Int;
    override public function InitScreen()
    {
        UI.AddMCButton(titleMC.buttonPrev, PrevPressed);
        UI.AddMCButton(titleMC.buttonNext, NextPressed);
        UI.AddMCButton(titleMC.buttonOK, OKPressed);
        
        numHelpPages = titleMC.totalFrames;
        helpPage = 0;
        
        InitHelp_Update();
    }
    private static function InitHelp_Update()
    {
        titleMC.gotoAndStop(helpPage + 1);
        titleMC.textPage.text = as3hx.Compat.parseInt(helpPage + 1) + "/" + numHelpPages;
        
        titleMC.buttonPrev.visible = true;
        if (helpPage == 0)
        {
            titleMC.buttonPrev.visible = false;
        }
        titleMC.buttonNext.visible = true;
        if (helpPage == numHelpPages - 1)
        {
            titleMC.buttonNext.visible = false;
        }
    }
    
    public static function PrevPressed(e : MouseEvent)
    {
        helpPage--;
        helpPage = Utils.LimitNumber(0, numHelpPages - 1, helpPage);
        InitHelp_Update();
    }
    public static function NextPressed(e : MouseEvent)
    {
        helpPage++;
        helpPage = Utils.LimitNumber(0, numHelpPages - 1, helpPage);
        InitHelp_Update();
    }
    public static function OKPressed(e : MouseEvent)
    {
        cast((helpMC), RemoveScreen);
        Game.pause = false;
    }
}

