import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class Ease
{
    
    public function new()
    {
    }
    
    private static function DebugOut(s : String)
    {
        Utils.print(s);
    }
    
    public static function GetStringNameList() : String
    {
        return "linear,power_in,power_out,power_inout,spring_in,spring_out,spring_inout";
    }
    
    public static function EaseByName(name : String, time : Float, value : Float)
    {
        if (name == "linear")
        {
            return cast((time), Linear);
        }
        if (name == "power_in")
        {
            return Power_In(time, value);
        }
        if (name == "power_out")
        {
            return Power_Out(time, value);
        }
        if (name == "power_inout")
        {
            return Power_InOut(time, value);
        }
        if (name == "spring_in")
        {
            return cast((time), Spring_In);
        }
        if (name == "spring_out")
        {
            return cast((time), Spring_Out);
        }
        if (name == "spring_inout")
        {
            return cast((time), Spring_InOut);
        }
        return time;
    }
    
    
    public static function Linear(time : Float) : Float
    {
        return time;
    }
    
    public static function Spring_Out(time : Float) : Float
    {
        return easeOut(time, 0, 1, 1);
    }
    public static function Spring_In(time : Float) : Float
    {
        return easeIn(time, 0, 1, 1);
    }
    public static function Spring_InOut(time : Float) : Float
    {
        return easeInOut(time, 0, 1, 1);
    }
    
    
    private static var _2PI : Float = Math.PI * 2;
    
    public static function easeIn(t : Float, b : Float, c : Float, d : Float, a : Float = 0, p : Float = 0) : Float
    {
        var s : Float;
        if (t == 0)
        {
            return b;
        }if ((t /= d) == 1)
        {
            return b + c;
        }if (!p)
        {
            p = d * .3;
        }
        if (!a || (c > 0 && a < c) || (c < 0 && a < -c))
        {
            a = c;s = p / 4;
        }
        else
        {
            s = p / _2PI * Math.asin(c / a);
        }
        return -(a * Math.pow(2, 10 * (t -= 1)) * Math.sin((t * d - s) * _2PI / p)) + b;
    }
    public static function easeOut(t : Float, b : Float, c : Float, d : Float, a : Float = 0, p : Float = 0) : Float
    {
        var s : Float;
        if (t == 0)
        {
            return b;
        }if ((t /= d) == 1)
        {
            return b + c;
        }if (!p)
        {
            p = d * .3;
        }
        if (!a || (c > 0 && a < c) || (c < 0 && a < -c))
        {
            a = c;s = p / 4;
        }
        else
        {
            s = p / _2PI * Math.asin(c / a);
        }
        return (a * Math.pow(2, -10 * t) * Math.sin((t * d - s) * _2PI / p) + c + b);
    }
    public static function easeInOut(t : Float, b : Float, c : Float, d : Float, a : Float = 0, p : Float = 0) : Float
    {
        var s : Float;
        if (t == 0)
        {
            return b;
        }if ((t /= d * 0.5) == 2)
        {
            return b + c;
        }if (!p)
        {
            p = d * (.3 * 1.5);
        }
        if (!a || (c > 0 && a < c) || (c < 0 && a < -c))
        {
            a = c;s = p / 4;
        }
        else
        {
            s = p / _2PI * Math.asin(c / a);
        }
        if (t < 1)
        {
            return -.5 * (a * Math.pow(2, 10 * (t -= 1)) * Math.sin((t * d - s) * _2PI / p)) + b;
        }
        return a * Math.pow(2, -10 * (t -= 1)) * Math.sin((t * d - s) * _2PI / p) * .5 + c + b;
    }
    
    /*
		
		public static function easeOut (t:Number, b:Number, c:Number, d:Number):Number {
			if ((t/=d) < (1/2.75)) {
				return c*(7.5625*t*t) + b;
			} else if (t < (2/2.75)) {
				return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
			} else if (t < (2.5/2.75)) {
				return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
			} else {
				return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
			}
		}
		public static function easeIn (t:Number, b:Number, c:Number, d:Number):Number {
			return c - easeOut(d-t, 0, c, d) + b;
		}
		public static function easeInOut (t:Number, b:Number, c:Number, d:Number):Number {
			if (t < d*0.5) return easeIn (t*2, 0, c, d) * .5 + b;
			else return easeOut (t*2-d, 0, c, d) * .5 + c*.5 + b;
		}		
		*/
    
    
    public static function Power_In(time : Float, power : Float = 2) : Float
    {
        var v : Float = time;
        for (i in 0...power - 1)
        {
            v *= time;
        }
        return v;
    }
    public static function Power_Out(time : Float, power : Float = 2) : Float
    {
        var t : Float = 1 - time;
        var v : Float = t;
        for (i in 0...power - 1)
        {
            v *= t;
        }
        v = 1 - v;
        return v;
    }
    
    public static function Power_InOut(time : Float, power : Float = 2) : Float
    {
        if (time < 0.5)
        {
            return Power_In(time * 2, power) * 0.5;
        }
        return 0.5 + (Power_Out((time - 0.5) * 2, power) * 0.5);
    }
    
    
    
    public static function Render(bd : BitmapData, fn : Function, x : Int, y : Int, w : Int = 45, h : Float = 45)
    {
        bd.fillRect(new Rectangle(x, y, w, h), 0xff000000);
        var t : Float = 0;
        while (t <= 1)
        {
            var v : Float = fn(t);
            var rx : Float = x + (w * t);
            var ry : Float = (y + h) - (h * v);
            bd.setPixel32(rx, ry, 0xffffffff);
            t += 0.01;
        }
    }
}

