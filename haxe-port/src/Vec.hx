import flash.geom.Point;

/**
	* ...
	* @author Default
	*/
class Vec
{
    public var rot : Float;
    public var speed : Float;
    public function new()
    {
        rot = 0.0;
        speed = 0.0;
    }
    public function SetFromDxDy(dx : Float, dy : Float)
    {
        speed = Math.sqrt((dx * dx) + (dy * dy));
        rot = Math.atan2(dy, dx);
    }
    public function Set(_r : Float, _s : Float)
    {
        rot = _r;
        speed = _s;
    }
    public function SetAng(_r : Float)
    {
        rot = _r;
    }
    
    public function NearRot(r : Float, d : Float) : Bool
    {
        var a : Float = rot - r;
        
        var aa : Float = Math.abs(a);
        
        if (a > Math.PI)
        {
            if (r < rot)
            {
                r += Math.PI * 2;
            }
            else
            {
                r -= Math.PI * 2;
            }
            a = rot - r;
        }
        
        if (Math.abs(a) <= d)
        {
            return true;
        }
        return false;
    }
    
    
    public function Add(v : Vec)
    {
        var x0 : Float = Math.cos(rot) * speed;
        var y0 : Float = Math.sin(rot) * speed;
        var x1 : Float = Math.cos(v.rot) * v.speed;
        var y1 : Float = Math.sin(v.rot) * v.speed;
        
        var dx : Float = x0 + x1;
        var dy : Float = y0 + y1;
        
        rot = Math.atan2(dy, dx);
        speed = Math.sqrt((dx * dx) + (dy * dy));
    }
    
    public function GetUnitTangent() : Point
    {
        var r : Float = rot + (Math.PI * 0.5);
        var p : Point = new Point(Math.cos(r), Math.sin(r));
        return p;
    }
    
    public function X() : Float
    {
        return Math.cos(rot) * speed;
    }
    public function Y() : Float
    {
        return Math.sin(rot) * speed;
    }
    
    public function UnitX() : Float
    {
        return Math.cos(rot);
    }
    public function UnitY() : Float
    {
        return Math.sin(rot);
    }
    
    
    public function AddRot(d : Float) : Void
    {
        rot += d;
        NormalizeRot();
    }
    
    public function dotRot(r : Float) : Float
    {
        var x0 : Float = Math.cos(rot);
        var y0 : Float = Math.sin(rot);
        var x1 : Float = Math.cos(r);
        var y1 : Float = Math.sin(r);
        var dot : Float = (x0 * x1) + (y0 * y1);
        return dot;
    }
    
    private function NormalizeRot() : Void
    {
        while (rot < 0)
        {
            rot += Math.PI * 2;
        }
        while (rot > Math.PI * 2)
        {
            rot -= Math.PI * 2;
        }
    }
    
    
    private function RotateToRequiredRot(rv : Float, xpos : Float, ypos : Float, toPosX : Float, toPosY : Float) : Bool
    {
        var requiredRot : Float = Math.atan2(toPosY - ypos, toPosX - xpos);
        
        var r1a : Float = requiredRot + (Math.PI / 2.0);
        var d1 : Float = Utils.DotProduct(Math.cos(rot), Math.sin(rot), Math.cos(r1a), Math.sin(r1a));
        if (NearRot(requiredRot, rv))
        {
            rot = requiredRot;
            return true;
        }
        
        if (d1 < 0)
        {
            cast((rv), AddRot);
        }
        else
        {
            cast((-rv), AddRot);
        }
        return false;
    }
}

