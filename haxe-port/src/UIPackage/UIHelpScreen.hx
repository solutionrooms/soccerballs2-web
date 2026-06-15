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
    public static var helpPage : Int;
    public static var numHelpPages : Int;
    override public function InitScreen()
    {
        UI.AddMCButton(titleMC.buttonPrev, PrevPressed);
        UI.AddMCButton((untyped titleMC).buttonNext, NextPressed);
        UI.AddMCButton(titleMC.buttonOK, OKPressed);
        
        numHelpPages = titleMC.totalFrames;
        helpPage = 0;
        
        InitHelp_Update();
    }
    public static function InitHelp_Update()
    {
        titleMC.gotoAndStop(helpPage + 1);
        titleMC.textPage.text = as3hx.Compat.parseInt(helpPage + 1) + "/" + as3hx.Compat.parseInt(numHelpPages);
        
        titleMC.buttonPrev.visible = true;
        if (helpPage == 0)
        {
            titleMC.buttonPrev.visible = false;
        }
        (untyped titleMC).buttonNext.visible = true;
        if (helpPage == numHelpPages - 1)
        {
            (untyped titleMC).buttonNext.visible = false;
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
        RemoveScreen(helpMC);
        Game.pause = false;
    }
}


