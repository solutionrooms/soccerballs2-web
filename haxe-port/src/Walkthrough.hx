
/**
	 * ...
	 * @author
	 */
class Walkthrough
{
    
    public function new()
    {
    }
    
    
    public static var walkthroughScreens : Array<Dynamic>;
    
    public static function InitScreens()
    {
        walkthroughScreens = [];
        for (i in 0...Levels.list.length)
        {
            var w : WalkthroughScreen = new WalkthroughScreen();
            w.MakeScreen(i);
            walkthroughScreens.push(w);
        }
    }
    
    public static function InitScreen()
    {
        walkthroughScreens = [];
        for (i in 0...Levels.list.length)
        {
            var w : WalkthroughScreen = new WalkthroughScreen();
            if (i == Levels.currentIndex)
            {
                w.MakeScreen(i);
            }
            walkthroughScreens.push(w);
        }
    }
}


