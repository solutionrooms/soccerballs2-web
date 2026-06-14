package uIPackage;

import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.ui.Mouse;
import flash.ui.MouseCursor;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIScreenInstance
{
    private var template : UIScreen;
    private var active : Bool;
    private var titleMC : MovieClip;
    private var onTransitionCompleteFunction : Function = null;
    
    
    
    public function new()
    {
    }
    
    public function GetMC() : MovieClip
    {
        return titleMC;
    }
    
    public function Start()
    {
        onTransitionCompleteFunction = null;
        Mouse.cursor = MouseCursor.AUTO;
        InitScreen();
    }
    public function Stop()
    {
        ExitScreen();
    }
    
    public function OnComplete()
    {
        if (onTransitionCompleteFunction != null)
        {
            onTransitionCompleteFunction();
        }
    }
    
    public function RenderForTransition(renderBD : BitmapData) : Void
    {
        renderBD.draw(titleMC);
    }
    
    
    public function InitScreen()
    {
    }
    public function ExitScreen()
    {
    }
}

