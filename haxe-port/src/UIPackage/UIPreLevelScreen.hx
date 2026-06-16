package uIPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class UIPreLevelScreen extends UIScreenInstance
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
        titleMC = new PreLevelScreen();
        var l : Level = Game.GetCurrentLevel();
        (untyped titleMC).textDescription.text = Std.string(l.description);
        (untyped titleMC).textName.text = Std.string(l.name);
        UI.AddMCButton(titleMC.buttonOK, buttonOKPressed);
    }
    public static function buttonOKPressed(e : MouseEvent)
    {
        UI.StartTransition(null, Game.StartLevel);
    }
}


