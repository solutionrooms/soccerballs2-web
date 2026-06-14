import haxe.Constraints.Function;
import flash.display.Stage;
import flash.events.MouseEvent;

/**
	* ...
	* @author Default
	*/
class MouseControl
{
    
    public static var ox : Float = 0;
    public static var oy : Float = 0;
    public static var x : Float = 0;
    public static var y : Float = 0;
    public static var mouseVelX : Float = 0;
    public static var mouseVelY : Float = 0;
    public static var buttonPressed : Bool = false;
    public static var buttonReleased : Bool = false;
    public static var wheelFunction : Function = null;
    
    
    public static function InitOnce(stage : Stage) : Void
    {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, MouseHandler);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, MouseClickHandler);
        stage.addEventListener(MouseEvent.MOUSE_UP, MouseUpHandler);
        stage.addEventListener(MouseEvent.MOUSE_WHEEL, MouseWheelHandler);
        wheelFunction = null;
    }
    
    public static function SetWheelHandler(f : Function) : Void
    {
        wheelFunction = f;
    }
    
    public function new()
    {
    }
    
    
    public static function Reset() : Void
    {
        buttonPressed = false;
        buttonReleased = false;
    }
    
    public static function MouseHandler(event : MouseEvent) : Void
    {
        x = event.stageX;
        y = event.stageY;
        mouseVelX = x - ox;
        mouseVelY = y - oy;
        dx = (x - ox);
        dy = (y - oy);
        ox = x;
        oy = y;
    }
    
    public static function ResetDxDy() : Void
    {
        dx = 0;
        dy = 0;
    }
    
    public static var dx : Float = 0;
    public static var dy : Float = 0;
    
    public static var delta : Int = 0;
    public static function MouseWheelHandler(event : MouseEvent) : Void
    {
        delta = event.delta;
        if (wheelFunction != null)
        {
            wheelFunction(delta);
        }
    }
    public static function MouseClickHandler(event : MouseEvent) : Void
    {
        buttonPressed = true;
        buttonReleased = false;
    }
    public static function MouseUpHandler(event : MouseEvent) : Void
    {
        buttonPressed = false;
        buttonReleased = true;
    }
}

