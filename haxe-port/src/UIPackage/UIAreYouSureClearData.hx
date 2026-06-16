package uIPackage;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIAreYouSureClearData extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
    }
    override public function InitScreen()
    {
        UI.StartAddButtons();
        titleMC = new ScreenClearSave();
        UI.AddAnimatedMCButton((untyped titleMC).btn_yes, buttonOKPressed);
        UI.AddAnimatedMCButton((untyped titleMC).btn_no, buttonCancelPressed);
        
        TextStrings.ReplaceTextFieldText((untyped titleMC).textTitle);
    }
    public function buttonOKPressed(e : MouseEvent)
    {
        Game.ResetEverything();
        SaveData.Save();
        UI.StartTransition("title");
    }
    public function buttonCancelPressed(e : MouseEvent)
    {
        UI.StartTransition("title");
    }
}


