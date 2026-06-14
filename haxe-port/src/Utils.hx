import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import org.flashdevelop.utils.FlashConnect;
import org.flashdevelop.utils.TraceLevel;

/**
	* ...
	* @author Default
	*/
class Utils
{
    
    public function new()
    {
    }
    
    public static function CopyColorTransform(ct : ColorTransform) : ColorTransform
    {
        if (ct == null)
        {
            return null;
        }
        var newct : ColorTransform = new ColorTransform();
        newct.redOffset = ct.redOffset;
        newct.greenOffset = ct.greenOffset;
        newct.blueOffset = ct.blueOffset;
        newct.alphaOffset = ct.alphaOffset;
        newct.redMultiplier = ct.redMultiplier;
        newct.greenMultiplier = ct.greenMultiplier;
        newct.blueMultiplier = ct.blueMultiplier;
        newct.alphaMultiplier = ct.alphaMultiplier;
        return newct;
    }
    
    private var FASTRANDOMTOFLOAT(default, never) : Float = 1 / as3hx.Compat.INT_MAX;
    private var fastrandomseed : Int = Math.random() * as3hx.Compat.INT_MAX;
    public function fastRandom() : Float
    {
        fastrandomseed = fastrandomseed ^ as3hx.Compat.parseInt(fastrandomseed << 21);
        fastrandomseed = fastrandomseed ^ as3hx.Compat.parseInt(fastrandomseed >>> 35);
        fastrandomseed = fastrandomseed ^ as3hx.Compat.parseInt(fastrandomseed << 4);
        return (fastrandomseed * FASTRANDOMTOFLOAT);
    }
    public static function print(str : Dynamic)
    {
        if (Game.debugPrint)
        {
            trace(str);
        }
    }
    public static function traceerror(str : String)
    {
        if (Game.debugPrintError)
        {
            trace(str);
        }
    }
    
    
    
    public static function ShuffleIntList(a : Array<Dynamic>, amount : Int = 100) : Array<Dynamic>
    {
        var len : Int = a.length;
        for (i in 0...amount)
        {
            var p0 : Int = Utils.RandBetweenInt(0, len - 1);
            var p1 : Int = Utils.RandBetweenInt(0, len - 1);
            
            var x : Int = a[p0];
            a[p0] = a[p1];
            a[p1] = x;
        }
        return a;
    }
    
    public static function AddLeadingZeroes(number : Int, amt : Int) : String
    {
        if (number < 10)
        {
            return "0" + Std.string(number);
        }
        return Std.string(number);
    }
    
    public static function RemoveWhiteSpace(s : String) : String
    {
        s = StringTools.replace(s, " ", "");
        return s;
    }
    
    
    public static function PointArrayFromString(s : String) : Array<Dynamic>
    {
        var pointArray : Array<Dynamic> = new Array<Dynamic>();
        
        var a : Array<Dynamic> = s.split(",");
        
        if (a.length < 2 || (a.length % 2) == 1)
        {
            print("PointArrayFromString. Error, numpoints=" + a.length + " , string= " + s);
            return pointArray;
        }
        
        var i : Int;
        var num : Int = as3hx.Compat.parseInt(a.length / 2);
        for (i in 0...num)
        {
            var p : Point = new Point(0, 0);
            p.x = as3hx.Compat.parseFloat(a[(i * 2) + 0]);
            p.y = as3hx.Compat.parseFloat(a[(i * 2) + 1]);
            pointArray.push(p);
        }
        
        return pointArray;
    }
    
    public static function HexArrayFromString(s : String) : Array<Dynamic>
    {
        var hexArray : Array<Dynamic> = new Array<Dynamic>();
        if (s.length == 0)
        {
            return hexArray;
        }
        
        
        var i : Int;
        var num : Int = s.length;
        for (i in 0...num)
        {
            var char : Int = as3hx.Compat.parseInt(s.charAt(i));
            hexArray.push(char);
        }
        
        return hexArray;
    }
    
    public static function rgbToHex(color : Int) : String
    {
        var colorInHex : String = Std.string(color);
        var c : String = "00000" + colorInHex;
        var e : Int = c.length;
        c = c.substring(e - 6, e);
        return c.toUpperCase();
    }
    
    
    public static function HexStringToInt(s : String) : Int
    {
        var h : String = "0123456789abcdef";
        s = s.toLowerCase();
        
        var multiplier : Int = 1;
        var val : Int = 0;
        
        var i : Int = as3hx.Compat.parseInt(s.length - 1);
        while (i >= 0)
        {
            var char : String = s.charAt(i);
            var a : Int = h.indexOf(char);
            val += as3hx.Compat.parseInt(a * multiplier);
            multiplier *= 16;
            i--;
        }
        return val;
    }
    
    public static function HexStringToColorTransform(str : String) : ColorTransform
    {
        if (str == null)
        {
            return null;
        }
        if (str == "")
        {
            return null;
        }
        
        var r : Int = cast((str.substr(0, 2)), HexStringToInt);
        var g : Int = cast((str.substr(2, 2)), HexStringToInt);
        var b : Int = cast((str.substr(4, 2)), HexStringToInt);
        
        r = as3hx.Compat.parseInt(-255 + r);
        g = as3hx.Compat.parseInt(-255 + g);
        b = as3hx.Compat.parseInt(-255 + b);
        
        var ct : ColorTransform = new ColorTransform(1, 1, 1, 1, r, g, b, 0);
        return ct;
    }
    
    public static function CounterToSecondsString(count : Int) : String
    {
        var s : String = "";
        
        var seconds : Int = as3hx.Compat.parseInt(count / as3hx.Compat.parseInt(Defs.fps));
        var remainder : Int = as3hx.Compat.parseInt(count % as3hx.Compat.parseInt(Defs.fps));
        
        s += Std.string(seconds) + ":";
        var r : Float = 100 / Defs.fps * remainder;
        s += Std.string(Math.floor(r));
        
        return s;
    }
    
    public static function CounterToMinutesSecondsString(count : Int) : String
    {
        var s : String = "";
        
        count /= Defs.fps;
        
        var seconds : Int = as3hx.Compat.parseInt(count / 60);
        var remainder : Int = as3hx.Compat.parseInt(count % 60);
        
        s += Std.string(seconds) + ":";
        var r : Float = remainder;
        s += Std.string(Math.floor(r));
        
        return s;
    }
    
    public static var minutesString : String = "";
    public static var secondsString : String = "";
    public static var miliString : String = "";
    public static function CounterToMinutesSecondsMilisecondsString(count : Int) : String
    {
        var s : String = "";
        
        var ms : Int = as3hx.Compat.parseInt(count % Defs.fps);
        ms = as3hx.Compat.parseInt(100 * ms / Defs.fps);
        
        count /= Defs.fps;
        
        var seconds : Int = as3hx.Compat.parseInt(count / 60);
        var remainder : Int = as3hx.Compat.parseInt(count % 60);
        
        if (remainder < 10)
        {
            secondsString = "0".concat(Std.string(remainder));
        }
        else
        {
            secondsString = Std.string(remainder);
        }
        
        minutesString = Std.string(seconds);
        
        if (ms < 10)
        {
            miliString = "0".concat(Std.string(ms));
        }
        else
        {
            miliString = Std.string(ms);
        }
        
        
        s += (minutesString);
        s += (":");
        s += (secondsString);
        s += (":");
        s += (miliString);
        
        
        return s;
    }
    
    public static function AddIntAndLoop(f0 : Int, f1 : Int, n : Int, adder : Int) : Float
    {
        n += adder;
        var d : Int = as3hx.Compat.parseInt((f1 - f0) + 1);
        if (n > f1)
        {
            n -= d;
        }
        if (n < f0)
        {
            n += d;
        }
        return n;
    }
    public static function LimitNumber(f0 : Float, f1 : Float, n : Float) : Float
    {
        if (n < f0)
        {
            n = f0;
        }
        if (n > f1)
        {
            n = f1;
        }
        return n;
    }
    
    public static function LoopNumber(f0 : Float, f1 : Float, n : Float) : Float
    {
        var diff : Int = as3hx.Compat.parseInt((f1 - f0) + 1);
        if (n < f0)
        {
            n += diff;
        }
        if (n > f1)
        {
            n -= diff;
        }
        return n;
    }
    
    
    public static function ScaleToAndLimit(f0 : Float, f1 : Float, o0 : Float, o1 : Float, val : Float) : Float
    {
        var od : Float = o1 - o0;
        var fd : Float = f1 - f0;
        
        var d : Float = 1.0 / od * (val - o0);
        d = (fd * d) + f0;
        
        if (d < f0)
        {
            d = f0;
        }
        if (d > f1)
        {
            d = f1;
        }
        
        return d;
    }
    
    public static function ScaleToPreLimit(f0 : Float, f1 : Float, o0 : Float, o1 : Float, val : Float) : Float
    {
        if (val < o0)
        {
            val = o0;
        }
        if (val > o1)
        {
            val = o1;
        }
        
        var od : Float = o1 - o0;
        var fd : Float = f1 - f0;
        
        var d : Float = 1.0 / od * (val - o0);
        d = (fd * d) + f0;
        return d;
    }
    
    public static function ScaleTo(f0 : Float, f1 : Float, o0 : Float, o1 : Float, val : Float) : Float
    {
        var od : Float = o1 - o0;
        var fd : Float = f1 - f0;
        
        var d : Float = 1.0 / od * (val - o0);
        d = (fd * d) + f0;
        
        return d;
    }
    public static function ScaleBetween(f0 : Float, f1 : Float, scale : Float) : Float
    {
        var d : Float = (f1 - f0) * scale;
        d = f0 + d;
        return d;
    }
    
    public static function LineLength(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dx : Float = x1 - x0;
        var dy : Float = y1 - y0;
        return Math.sqrt(dx * dx + dy * dy);
    }
    
    public static function NumberToString2DP(n : Float) : String
    {
        var aa : String = Std.string(cast((n), DP2));
        var index : Int = aa.lastIndexOf(".");
        if (index == -1)
        {
            aa.concat(".00");
        }
        else
        {
            var len : Int = aa.length;
            if (index == len - 1)
            {
                aa.concat("0");
            }
        }
        return aa;
    }
    
    public static function DP2(val : Float) : Float
    {
        var n : Float = Math.ceil(val * 100.0) / 100.0;
        return n;
    }
    public static function DP1(val : Float) : Float
    {
        var n : Float = Math.ceil(val * 10.0) / 10.0;
        return n;
    }
    
    
    private static function RandSetSeed(_seed : Int)
    {
        SeededRandom.SetSeed(_seed);
    }
    private static function RandBetweenFloat_Seeded(r0 : Float, r1 : Float) : Float
    {
        var r : Float = SeededRandom.GetNumber() * (r1 - r0);
        r += r0;
        return r;
    }
    private static function RandBetweenInt_Seeded(r0 : Int, r1 : Int) : Int
    {
        var r : Int = as3hx.Compat.parseInt(SeededRandom.GetNumber() * ((r1 - r0) + 1));
        r += r0;
        return r;
    }
    
    
    public static function RandBetweenFloat(r0 : Float, r1 : Float) : Float
    {
        var r : Float = Math.random() * (r1 - r0);
        r += r0;
        return r;
    }
    public static function RandBetweenInt(r0 : Int, r1 : Int) : Int
    {
        var r : Int = as3hx.Compat.parseInt(Math.random() * ((r1 - r0) + 1));
        r += r0;
        return r;
    }
    public static function RandBool() : Bool
    {
        return (RandBetweenInt(0, 99) < 50);
    }
    
    public static function DotProduct(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dot : Float = (x0 * x1) + (y0 * y1);
        return dot;
    }
    
    
    public static function CrossProductAng(r0 : Float, r1 : Float) : Float
    {
        var x0 : Float = Math.cos(r0);
        var y0 : Float = Math.sin(r0);
        var x1 : Float = Math.cos(r1);
        var y1 : Float = Math.sin(r1);
        return CrossProduct(x0, y0, x1, y1);
    }
    
    public static function CrossProduct(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var cross : Float = (x0 * y1) - (x1 * y0);
        return cross;
    }
    
    
    public static function SideOfLine(lx0 : Float, ly0 : Float, lx1 : Float, ly1 : Float, x : Float, y : Float) : Bool
    {
        var cross : Float = CrossProduct(lx1 - lx0, ly1 - ly0, x - lx0, y - ly0);
        if (cross < 0.0)
        {
            return false;
        }
        return true;
    }
    
    
    
    public static function DotProductAng(r0 : Float, r1 : Float) : Float
    {
        var x0 : Float = Math.cos(r0);
        var y0 : Float = Math.sin(r0);
        var x1 : Float = Math.cos(r1);
        var y1 : Float = Math.sin(r1);
        var dot : Float = (x0 * x1) + (y0 * y1);
        return dot;
    }
    
    public static function RandCirclePosition(radius : Float) : Point
    {
        var r : Float = Math.random() * (Math.PI * 2);
        var dx : Float = Math.cos(r) * Utils.RandBetweenFloat(0, radius);
        var dy : Float = Math.sin(r) * Utils.RandBetweenFloat(0, radius);
        var p : Point = new Point(dx, dy);
        return p;
    }
    
    
    public static function RandCircle() : Float
    {
        return Math.random() * (Math.PI * 2);
    }
    
    public static function RadToDeg(rad : Float) : Float
    {
        return 360.0 / (Math.PI * 2) * rad;
    }
    
    public static function DegToRad(deg : Float) : Float
    {
        return (Math.PI * 2) / 360.0 * deg;
    }
    
    
    public static function RenderDotLine(bd : BitmapData, x0 : Float, y0 : Float, x1 : Float, y1 : Float, numP : Int, col : Int) : Void
    {
        var i : Int;
        var maxP : Int = numP;
        var dx : Float = (x1 - x0) / maxP;
        var dy : Float = (y1 - y0) / maxP;
        bd.setPixel32(as3hx.Compat.parseInt(x0), as3hx.Compat.parseInt(y0), col);
        var ox : Float = x0;
        var oy : Float = y0;
        for (i in 0...maxP)
        {
            x0 += dx;
            y0 += dy;
            bd.setPixel32(as3hx.Compat.parseInt(x0), as3hx.Compat.parseInt(y0), col);
        }
    }
    
    public static function RenderRectangle(bd : BitmapData, r : Rectangle, col : Int) : Void
    {
        RenderDotLine(bd, r.left, r.top, r.right, r.top, 100, col);
        RenderDotLine(bd, r.left, r.bottom, r.right, r.bottom, 100, col);
        RenderDotLine(bd, r.left, r.top, r.left, r.bottom, 100, col);
        RenderDotLine(bd, r.right, r.top, r.right, r.bottom, 100, col);
    }
    
    public static function RenderCircle(bd : BitmapData, x : Float, y : Float, rad : Float, col : Int) : Void
    {
        var numP : Int = 50;
        var dx : Float = Math.PI * 2 / numP;
        var i : Int;
        var ang : Float = 0;
        for (i in 0...numP)
        {
            var xp : Float = x + (Math.cos(ang) * rad);
            var yp : Float = y + (Math.sin(ang) * rad);
            ang += dx;
            bd.setPixel32(as3hx.Compat.parseInt(xp), as3hx.Compat.parseInt(yp), col);
        }
    }
    
    public static function DistBetweenPoints(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dx : Float = x1 - x0;
        var dy : Float = y1 - y0;
        return Math.sqrt((dx * dx) + (dy * dy));
    }
    
    public static function GetLength(dx : Float, dy : Float) : Float
    {
        return ((dx * dx) + (dy * dy));
    }
    public static function Dist2BetweenPoints(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dx : Float = x1 - x0;
        var dy : Float = y1 - y0;
        return ((dx * dx) + (dy * dy));
    }
    
    
    public static function NormalizeRot(rot : Float) : Float
    {
        while (rot < 0)
        {
            rot += Math.PI * 2;
        }
        while (rot > Math.PI * 2)
        {
            rot -= Math.PI * 2;
        }
        return rot;
    }
    
    
    
    
    public static var paramNames : Array<Dynamic>;
    public static var paramValues : Array<Dynamic>;
    public static function PrintParams() : Void
    {
        for (i in 0...paramNames.length)
        {
            var s : String = paramNames[i] + " " + paramValues[i];
            print(s);
        }
    }
    public static function GetParams(params : String) : Void
    {
        paramNames = new Array<Dynamic>();
        paramValues = new Array<Dynamic>();
        
        if (params == null)
        {
            return;
        }
        if (params == "")
        {
            return;
        }
        
        if (params.substring(params.length - 1, params.length) == ",")
        {
            params = params.substring(0, params.length - 1);
        }
        
        
        var ss : Array<Dynamic> = params.split(",");
        for (s in ss)
        {
            var sss : Array<Dynamic> = s.split("=");
            paramNames.push(sss[0]);
            paramValues.push(sss[1]);
        }
    }
    
    public static function GetParamExists(name : String) : Bool
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            return true;
        }
        return false;
    }
    public static function GetParam(name : String, _default : String = "") : String
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            return paramValues[i];
        }
        return _default;
    }
    public static function GetParamString(name : String, _default : String = "") : String
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            return paramValues[i];
        }
        return _default;
    }
    public static function GetParamNumber(name : String, _default : Float = 0) : Float
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            return as3hx.Compat.parseFloat(paramValues[i]);
        }
        return _default;
    }
    public static function GetParamInt(name : String, _default : Float = 0) : Int
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            return as3hx.Compat.parseInt(paramValues[i]);
        }
        return as3hx.Compat.parseInt(_default);
    }
    public static function GetParamBool(name : String, _default : Bool = false) : Bool
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            var s : String = paramValues[i];
            if (s == "true")
            {
                return true;
            }
            return false;
        }
        return _default;
    }
    
    public static function ChangeParam(name : String, value : String)
    {
        var i : Int = Lambda.indexOf(paramNames, name);
        if (i != -1)
        {
            paramValues[i] = value;
        }
    }
    
    
    
    public static function MakeParamString()
    {
        var s : String = "";
        for (i in 0...paramNames.length)
        {
            s += paramNames[i];
            s += "=";
            s += paramValues[i];
            if (i != paramNames.length - 1)
            {
                s += ",";
            }
        }
        return s;
    }
    
    public static function qsort(arr : Array<Float>, l : Int, r : Int) : Void
    {
        var i : Int;
        var j : Int;
        var k : Int;
        var vi : Int;
        var v : Float;
        
        if ((r - l) > 4)
        {
            i = as3hx.Compat.parseInt(r + l) >> 1;
            if (arr[l] > arr[i])
            {
                vi = arr[l];
                arr[l] = arr[i];
                arr[i] = vi;
            }
            
            if (arr[l] > arr[r])
            {
                vi = arr[l];
                arr[l] = arr[r];
                arr[r] = vi;
            }
            
            if (arr[l] > arr[r])
            {
                vi = arr[i];
                arr[i] = arr[r];
                arr[r] = vi;
            }
            
            j = as3hx.Compat.parseInt(r - 1);
            
            vi = arr[i];
            arr[i] = arr[j];
            arr[j] = vi;
            
            i = l;
            v = arr[j];
            
            while (true)
            {
                while (arr[++i] < v)
                {
                }
                while (arr[--j] > v)
                {
                }
                
                if (j < i)
                {
                    break;
                }
                
                vi = arr[i];
                arr[i] = arr[j];
                arr[j] = vi;
            }
            
            vi = arr[i];
            arr[i] = arr[(k = as3hx.Compat.parseInt(r - 1))];
            arr[k] = vi;
            
            qsort(arr, l, j);
            qsort(arr, i + 1, r);
        }
    }
    
    public static function GetCardinalString(number : Int) : String
    {
        return as3hx.Compat.parseInt(number + 1) + cast((number), GetPlacePostfixString);
    }
    public static function GetPlacePostfixString(place : Int) : String
    {
        var a : Array<Dynamic> = new Array<Dynamic>(
        "st", "nd", "rd", "th");
        
        if (place < 0)
        {
            place = 0;
        }
        if (place >= a.length)
        {
            place = as3hx.Compat.parseInt(a.length - 1);
        }
        return a[place];
    }
}

