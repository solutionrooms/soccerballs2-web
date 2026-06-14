import editorPackage.EdLine;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import nape.geom.Vec2;
import nape.geom.Vec2List;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;
import textPackage.TextRenderer;

/**
	* ...
	* @author Default
	*/
class EngineDebug
{
    private static var timerNames : Array<Dynamic>;
    private static var timerStartTimes : Array<Dynamic>;
    private static var timerTimes : Array<Dynamic>;
    
    public static var debugMode : Int = 0;
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        timerNames = new Array<Dynamic>();
        timerStartTimes = new Array<Dynamic>();
        timerTimes = new Array<Dynamic>();
    }
    
    public static function IsSet(mask : Int) : Bool
    {
        if ((debugMode & mask) == 0)
        {
            return false;
        }
        return true;
    }
    
    private static var immediateTime : Int;
    public static function StartImmediateTimer()
    {
        immediateTime = Math.round(haxe.Timer.stamp() * 1000);
    }
    public static function StopImmediateTimer(s : String)
    {
        var t : Int = as3hx.Compat.parseInt(Math.round(haxe.Timer.stamp() * 1000) - immediateTime);
        Utils.print("Immediate Timer: " + t + " - " + s);
    }
    
    public static function StartTimers()
    {
        timerNames = new Array<Dynamic>();
        timerTimes = new Array<Dynamic>();
        timerStartTimes = new Array<Dynamic>();
        cast(("total"), StartTimer);
    }
    
    public static function StopTimers()
    {
        cast(("total"), EndTimer);
    }
    
    
    
    public static var timerStrings : Array<Dynamic> = null;
    public static function GetTimerString(index : Int) : String
    {
        if (timerStrings == null)
        {
            return "";
        }
        if (index < 0)
        {
            return "";
        }
        if (index >= timerStrings.length)
        {
            return "";
        }
        return timerStrings[index];
    }
    public static function CreateGetTimerStrings()
    {
        timerStrings = new Array<Dynamic>();
        for (i in 0...10)
        {
            timerStrings.push("");
        }
        
        var totalTime : Float = timerTimes[0];
        var y : Int = 100;
        var x : Int = 10;
        var s : String;
        var i : Int;
        for (i in 0...timerNames.length)
        {
            var percent : Float = 100 / totalTime * timerTimes[i];
            s = timerNames[i] + " : " + timerTimes[i];
            timerStrings[i] = s;
        }
    }
    public static function RenderTimers(bd : BitmapData)
    {
        if (false)
        {
            return;
        }
        if (bd == null)
        {
            return;
        }
        if (cast((2), IsSet) == false)
        {
            return;
        }
        var totalTime : Float = timerTimes[0];
        var y : Int = 100;
        var x : Int = 10;
        var s : String;
        var i : Int;
        for (i in 0...timerNames.length)
        {
            var percent : Float = 100 / totalTime * timerTimes[i];
            s = "Timer " + timerNames[i] + " : " + timerTimes[i] + "   (" + Std.string(as3hx.Compat.parseInt(percent)) + "%";
            TextRenderer.RenderAt(bd, x, y, s, 0, 1, TextRenderer.JUSTIFY_LEFT);
            y += 15;
        }
    }
    
    public static function StartTimer(name : String)
    {
        timerNames.push(name);
        timerStartTimes.push(Math.round(haxe.Timer.stamp() * 1000));
        timerTimes.push(Math.round(haxe.Timer.stamp() * 1000));
    }
    public static function EndTimer(name : String)
    {
        var i : Int = 0;
        for (s in timerNames)
        {
            if (s == name)
            {
                timerTimes[i] = Math.round(haxe.Timer.stamp() * 1000) - timerStartTimes[i];
            }
            i++;
        }
    }
    
    
    private static function RenderNape(bd : BitmapData) : Void
    {
        if (cast((4), IsSet) == false)
        {
            return;
        }
        var bodyList : BodyList = PhysicsBase.GetNapeSpace().bodies;
        
        var col_body : Int = 0xffff0000;
        var col_sensor : Int = 0xff00ff00;
        
        for (i in 0...bodyList.length)
        {
            var b : Body = bodyList.at(i);
            
            for (j in 0...b.shapes.length)
            {
                var shape : Shape = b.shapes.at(j);
                
                var col : Int = col_body;
                if (shape.sensorEnabled)
                {
                    col = col_sensor;
                }
                
                if (shape.isPolygon())
                {
                    var poly : Polygon = shape.castPolygon;
                    var v2list : Vec2List = poly.worldVerts;
                    for (k in 0...v2list.length - 1)
                    {
                        var v0 : Vec2 = v2list.at(k);
                        var v1 : Vec2 = v2list.at(k + 1);
                        var x : Float = v0.x - Game.camera.x;
                        var y : Float = v0.y - Game.camera.y;
                        var x1 : Float = v1.x - Game.camera.x;
                        var y1 : Float = v1.y - Game.camera.y;
                        
                        Utils.RenderDotLine(bd, x, y, x1, y1, 50, col);
                    }
                }
                else if (shape.isCircle())
                {
                    var c : Circle = shape.castCircle;
                    var v0 : Vec2 = c.worldCOM;
                    var x : Float = v0.x - Game.camera.x;
                    var y : Float = v0.y - Game.camera.y;
                    Utils.RenderCircle(bd, x, y, c.radius, col);
                }
            }
        }
    }
    private static function RenderLines(bd : BitmapData) : Void
    {
        if (bd == null)
        {
            return;
        }
        if (cast((1), IsSet) == false)
        {
            return;
        }
        var sx : Float = Game.camera.x;
        var sy : Float = Game.camera.y;
        
        var lev : Level = Levels.GetCurrent();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(lev),lines) type: null */ in lev.lines)
        {
            var i : Int;
            var count : Int = line.points.length;
            for (i in 0...count - 1)
            {
                var x0 : Float = line.points[i + 0].x - sx;
                var y0 : Float = line.points[i + 0].y - sy;
                var x1 : Float = line.points[i + 1].x - sx;
                var y1 : Float = line.points[i + 1].y - sy;
                
                {
                    Utils.RenderDotLine(bd, x0, y0, x1, y1, 1000, 0xffffff00);
                }
            }
        }
    }
}

