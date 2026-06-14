import editorPackage.ObjParameters;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author ...
	 */
class PhysLine
{
    public var index : Int;
    public var id : String;
    public var type : Int;
    public var points : Array<Dynamic>;
    public var fill : Int;
    public var fillScaleX : Float;
    public var fillScaleY : Float;
    public var centrex : Float;
    public var centrey : Float;
    public var fixed : Bool;
    public var primitiveType : String;
    public var objParameters : ObjParameters;
    
    public static inline var PRIMITIVE_LINE : String = "line";
    public static inline var PRIMITIVE_RECTANGLE : String = "rectangle";
    public static inline var PRIMITIVE_CIRCLE : String = "circle";
    
    public function new()
    {
        id = "";
        type = 0;
        points = new Array<Dynamic>();
        fill = 0;
        fillScaleX = 1;
        fillScaleY = 1;
        fixed = true;
        objParameters = new ObjParameters();
        
        primitiveType = PRIMITIVE_LINE;
        
        
        centrex = 0;
        centrey = 0;
    }
    
    public function AddPoint(x : Float, y : Float)
    {
        points.push(new Point(x, y));
    }
    
    public function SetPointArray(a : Array<Dynamic>)
    {
        points = a;
    }
    
    public function Clone() : PhysLine
    {
        var l : PhysLine = new PhysLine();
        l.id = id;
        l.type = type;
        l.fill = fill;
        l.fillScaleX = fillScaleX;
        l.fillScaleY = fillScaleY;
        l.centrex = centrex;
        l.centrey = centrey;
        l.fixed = fixed;
        for (p in points)
        {
            l.points.push(p.clone());
        }
        l.objParameters = objParameters.Clone();
        l.primitiveType = primitiveType;
        return l;
    }
    
    public function GetPoint(index : Int) : Point
    {
        return points[index];
    }
    
    private var boundingRectangle : Rectangle;
    private function CalcBoundingRectangle()
    {
        var p : Point;
        p = points[0];
        boundingRectangle = new Rectangle(p.x, p.y, 1, 1);
        
        for (p in points)
        {
            inflateRectByPoint(boundingRectangle, p);
        }
    }
    public static function inflateRectByPoint(r : Rectangle, p : Point) : Void
    {
        var d : Float;
        d = p.x - r.x;
        if (d < 0)
        {
            r.x += d;
            r.width -= d;
        }
        else if (d > r.width)
        {
            r.width = d;
        }
        d = p.y - r.y;
        if (d < 0)
        {
            r.y += d;
            r.height -= d;
        }
        else if (d > r.height)
        {
            r.height = d;
        }
    }
    
    public function PointInPoly(x : Float, y : Float) : Bool
    {
        var numIntersections : Int = 0;
        
        if (points.length == 2)
        {
            return PointOnLine(x, y, 2);
        }
        
        CalcBoundingRectangle();
        if (boundingRectangle.contains(x, y) == false)
        {
            return false;
        }
        
        var count : Int = points.length;
        var i : Int;
        for (i in 0...count)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            if (j >= count)
            {
                j = 0;
            }
            var p0 : Point = points[i];
            var p1 : Point = points[j];
            var x0 : Int = p0.x;
            var y0 : Int = p0.y;
            var x1 : Int = p1.x;
            var y1 : Int = p1.y;
            
            if (y1 < y0)
            {
                x0 = p1.x;
                y0 = p1.y;
                x1 = p0.x;
                y1 = p0.y;
            }
            
            if (y >= y0 && y <= y1)
            {
                var dy : Float = y1 - y0;
                var dx : Float = x1 - x0;
                
                var y2 : Float = (y - y0) / dy;
                var x2 : Float = x0 + (dx * y2);
                
                
                if (x < x2)
                {
                    numIntersections++;
                }
            }
        }
        if ((numIntersections & 1) != 0)
        {
            return true;
        }
        return false;
    }
    
    public function PointOnLine(x : Float, y : Float, dist : Float = 1) : Bool
    {
        var i : Int;
        var a0 : Array<Dynamic> = points;
        var numPoints : Int = points.length;
        for (i in 0...numPoints)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            if (j >= numPoints)
            {
                j = 0;
            }
            var p0 : Point = a0[i];
            var p1 : Point = a0[j];
            
            var t : Float = Collision.ClosestPointOnLine(p0.x, p0.y, p1.x, p1.y, x, y);
            if (t >= 0.0 && t <= 1)
            {
                if (Utils.DistBetweenPoints(x, y, Collision.closestX, Collision.closestY) < dist)
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    
    public function PointInConvexPoly(x : Float, y : Float) : Bool
    {
        var count : Int = points.length;
        var i : Int;
        for (i in 0...count)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            if (j >= count)
            {
                j = 0;
            }
            var p0 : Point = points[i];
            var p1 : Point = points[j];
            
            var l0 : Point = new Point(p1.x - p0.x, p1.y - p0.y);
            var l1 : Point = new Point(p1.x - x, p1.y - y);
            
            var dot : Float = Utils.DotProduct(l0.x, l0.y, l1.x, l1.y);
            if (dot < 0)
            {
                return false;
            }
        }
        return true;
    }
    
    
    
    private var catmullRomLength : Float;
    private var segmentLengths : Array<Dynamic>;
    private var segmentRatios : Array<Dynamic>;
    public function CalculateLength(loop : Bool = false) : Float
    {
        segmentLengths = null;
        segmentRatios = null;
        var l : Float = 0;
        var np : Int = GetNumPoints();
        var numPoints : Int = np;
        if (np <= 1)
        {
            return 0;
        }
        
        if (loop == false)
        {
            np--;
        }
        
        segmentLengths = new Array<Dynamic>();
        segmentRatios = new Array<Dynamic>();
        for (i in 0...np)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            if (j >= numPoints)
            {
                j = 0;
            }
            
            var l1 : Float = Utils.DistBetweenPoints(points[i].x, points[i].y, points[j].x, points[j].y);
            l += l1;
            segmentLengths.push(l1);
        }
        
        for (sl in segmentLengths)
        {
            var r : Float = 1 / l * sl;
            segmentRatios.push(r);
        }
        
        /* output
			var rr:Number = 0;
			for (var i:int = 0; i < segmentLengths.length; i++)
			{
				sl = segmentLengths[i];
				r = segmentRatios[i];
				rr += r;
				Utils.trace("len: " + sl + "   ratio: " + r);
			}
			Utils.trace("total: " + rr);
			*/
        
        return l;
    }
    public function CalculateCatmullRomLength()
    {
        var l : Array<Dynamic> = new Array<Dynamic>();
        var i : Int;
        
        var np : Int = GetNumPoints();
        if (np < 4)
        {
            catmullRomLength = 0;
        }
        else
        {
            var t1 : Float;
            t1 = 0;
            while (t1 < 1.0)
            {
                var pp : Point = GetPointOnCatmullRom(t1, true);
                l.push(pp);
                t1 += 0.025;
            }
        }
        
        catmullRomLength = 0.0;
        for (i in 0...l.length - 2)
        {
            var p0 : Point = l[i];
            var p1 : Point = l[i + 1];
            catmullRomLength += Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
        }
        
        l = null;
    }
    
    public function PointOnCurve(t : Float, p0 : Point, p1 : Point, p2 : Point, p3 : Point) : Point
    {
        var out : Point = new Point();
        var t2 : Float = t * t;
        var t3 : Float = t2 * t;
        out.x = 0.5 * ((2.0 * p1.x) +
                (-p0.x + p2.x) * t +
                (2.0 * p0.x - 5.0 * p1.x + 4 * p2.x - p3.x) * t2 +
                (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3);
        out.y = 0.5 * ((2.0 * p1.y) +
                (-p0.y + p2.y) * t +
                (2.0 * p0.y - 5.0 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3);
        return out;
    }
    
    public function GetPointOnCatmullRom(t : Float, loop : Bool) : Point
    {
        var np : Int = GetNumPoints();
        if (np < 4)
        {
            return new Point(0, 0);
        }
        var numSegs : Int = np;
        
        var p0 : Point;
        var p1 : Point;
        var p2 : Point;
        var p3 : Point;
        var seg : Float = numSegs * t;
        if (seg >= numSegs)
        {
            seg = numSegs - 1;
        }
        var i : Int = as3hx.Compat.parseInt(seg);
        
        var pt0 : Int;
        var pt1 : Int;
        var pt2 : Int;
        var pt3 : Int;
        
        
        if (loop)
        {
            pt0 = Utils.AddIntAndLoop(0, np - 1, i, -1);
            pt1 = i;
            pt2 = Utils.AddIntAndLoop(0, np - 1, i, 1);
            pt3 = Utils.AddIntAndLoop(0, np - 1, i, 2);
        }
        else
        {
            pt0 = as3hx.Compat.parseInt(i - 1);
            pt1 = i;
            pt2 = as3hx.Compat.parseInt(i + 1);
            pt3 = as3hx.Compat.parseInt(i + 2);
            if (pt0 < 0)
            {
                pt0 = 0;
            }
            if (pt2 > np - 1)
            {
                pt2 = as3hx.Compat.parseInt(np - 1);
            }
            if (pt3 > np - 1)
            {
                pt3 = as3hx.Compat.parseInt(np - 1);
            }
        }
        
        
        p0 = points[pt0];
        p1 = points[pt1];
        p2 = points[pt2];
        p3 = points[pt3];
        
        var i1 : Int = as3hx.Compat.parseInt(i + 1);
        var s0 : Float = 1.0 / numSegs * i;
        var s1 : Float = 1.0 / numSegs * i1;
        var t1 : Float = 1.0 / (s1 - s0) * (t - s0);
        var p : Point = PointOnCurve(t1, p0, p1, p2, p3);
        
        
        return p;
    }
    
    public function DrawCatmullRom(bd : BitmapData, col : Int, xoff : Float, yoff : Float)
    {
        var np : Int = GetNumPoints();
        if (np < 4)
        {
            return;
        }
        
        var t1 : Float;
        t1 = 0;
        while (t1 < 1.0)
        {
            var pp : Point = GetPointOnCatmullRom(t1, true);
            bd.setPixel32(pp.x + xoff, pp.y + yoff, col);
            t1 += 0.001;
        }
    }
    
    public function GetNumPoints() : Int
    {
        return points.length;
    }
    
    
    
    public function GetInterpolatedPoint1(pos : Float, loop : Bool) : Point
    {
        cast((loop), CalculateLength);
        
        var numPoints : Int = points.length;
        if (loop)
        {
            numPoints++;
        }
        var numSegs : Int = as3hx.Compat.parseInt(numPoints - 1);
        
        var rr : Float = 0;
        for (i in 0...numSegs)
        {
            var j : Int = as3hx.Compat.parseInt(i + 1);
            if (j >= points.length)
            {
                j = 0;
            }
            
            var r : Float = segmentRatios[i];
            var rr1 : Float = rr + r;
            if (pos >= rr && pos <= rr1)
            {
                var q : Float = Utils.ScaleTo(0, 1, rr, rr1, pos);
                var x : Float = Utils.ScaleTo(points[i].x, points[j].x, 0, 1, q);
                var y : Float = Utils.ScaleTo(points[i].y, points[j].y, 0, 1, q);
                var p : Point = new Point(x, y);
                return p;
            }
            rr += r;
        }
        return new Point(0, 0);
    }
    public function GetInterpolatedPoint(pos : Float, loop : Bool, isSpline : Bool = false) : Point
    {
        if (isSpline)
        
        //type == 2){
            
            {
                return GetPointOnCatmullRom(pos, loop);
            }
        }
        
        
        if (loop == true)
        {
            var numPoints : Int = points.length;
            
            var nodelen : Float = 1.0 / numPoints;
            
            
            var pi0 : Int = Math.floor(numPoints * pos);
            var pi1 : Int = as3hx.Compat.parseInt((pi0 + 1) % numPoints);
            
            var pos0 : Float = pi0 * nodelen;
            var pos1 : Float = (pi0 + 1) * nodelen;
            
            var x : Float = Utils.ScaleTo(points[pi0].x, points[pi1].x, pos0, pos1, pos);
            var y : Float = Utils.ScaleTo(points[pi0].y, points[pi1].y, pos0, pos1, pos);
            
            var p : Point = new Point(x, y);
            return p;
        }
        var numPoints : Int = points.length;
        
        var nodelen : Float = 1.0 / (numPoints - 1);
        
        
        var pi0 : Int = Math.floor((numPoints - 1) * pos);
        var pi1 : Int = as3hx.Compat.parseInt((pi0 + 1) % numPoints);
        
        var pos0 : Float = pi0 * nodelen;
        var pos1 : Float = (pi0 + 1) * nodelen;
        
        var x : Float = Utils.ScaleTo(points[pi0].x, points[pi1].x, pos0, pos1, pos);
        var y : Float = Utils.ScaleTo(points[pi0].y, points[pi1].y, pos0, pos1, pos);
        
        var p : Point = new Point(x, y);
        return p;
    }
}

