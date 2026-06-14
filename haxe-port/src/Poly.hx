import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	* ...
	* @author Default
	*/
class Poly
{
    public static inline var polytype_PATH = 0;
    public static inline var polytype_WALL = 1;
    public static inline var polytype_TRIGGER = 2;
    public static inline var polytype_ZONE = 3;
    public static inline var polytype_OVERLAY = 4;
    public static inline var polytype_FLOOR = 5;
    public static inline var polytype_CEILING = 6;
    
    private var boundingRectangle : Rectangle;
    private var active : Bool;
    private var type : Int;
    private var name : String;
    private var lineList : Array<Dynamic>;
    private var pointList : Array<Dynamic>;
    private var hitCallback : Dynamic;
    private var param0 : String;
    private var param1 : String;
    private var iparam0 : Int;
    private var typeName : String;
    private var subTypeName : String;
    private var closed : Bool;
    
    
    public static function FindAllByType(type : Int, polyList : Array<Dynamic>) : Array<Dynamic>
    {
        var list : Array<Dynamic> = new Array<Dynamic>();
        for (poly in polyList)
        {
            if (poly.type == type)
            {
                list.push(poly);
            }
        }
        return list;
    }
    
    
    public static function FindByName(name : String, polyList : Array<Dynamic>) : Poly
    {
        for (poly in polyList)
        {
            if (poly.name == name)
            {
                return poly;
            }
        }
        return null;
    }
    public static function FindIndexByName(name : String, polyList : Array<Dynamic>) : Int
    {
        var index : Int = 0;
        for (poly in polyList)
        {
            if (poly.name == name)
            {
                return index;
            }
            index++;
        }
        return -1;
    }
    
    public function new(_name : String, _type : Int, x : Float, y : Float)
    {
        lineList = new Array<Dynamic>();
        active = true;
        type = _type;
        name = _name;
        boundingRectangle = null;
        hitCallback = null;
        closed = false;
        pointList = new Array<Dynamic>();
        pointList.push(new Point(x, y));
    }
    
    
    public function AddLine(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Void
    {
        var l : Line = new Line(x0, y0, x1, y1);
        lineList.push(l);
        
        pointList.push(new Point(x1, y1));
        
        if (boundingRectangle == null)
        {
            boundingRectangle = l.boundingRect;
        }
        else
        {
            var r : Rectangle = boundingRectangle.clone();
            boundingRectangle = r.union(l.boundingRect);
        }
    }
    
    public function Finish(close : Bool)
    {
        if (close)
        {
            var l0 : Line = lineList[0];
            var l1 : Line = lineList[lineList.length - 1];
            var l : Line = new Line(l1.x1, l1.y1, l0.x0, l0.y0);
            lineList.push(l);
            var r : Rectangle = boundingRectangle.clone();
            boundingRectangle = r.union(l.boundingRect);
        }
        closed = close;
    }
    
    public function OffsetFromStartPoint()
    {
        var offx = -pointList[0].x;
        var offy = -pointList[0].y;
        
        var i : Int;
        for (i in 0...pointList.length)
        {
            pointList[i].x += offx;
            pointList[i].y += offy;
        }
        
        for (i in 0...lineList.length)
        {
            var l : Line = lineList[i];
            l.x0 += offx;
            l.x1 += offx;
            l.y0 += offy;
            l.y1 += offy;
        }
    }
    
    
    public static function MakeSplineFromPointList(pts : Array<Dynamic>) : Poly
    {
        var p : Point;
        var p1 : Point;
        p = pts[0];
        
        var poly : Poly = new Poly("", 0, p.x, p.y);
        var len : Int = pts.length;
        var i : Int;
        
        for (i in 0...len - 1)
        {
            p = pts[i];
            p1 = pts[i + 1];
            poly.AddLine(p.x, p.y, p1.x, p1.y);
        }
        poly.Finish(false);
        poly.CalculateCatmullRomLength();
        return poly;
    }
    
    private var catmullRomLength : Float;
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
                var pp : Point = GetPointOnCatmullRom(t1);
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
    
    
    private function PointOnCurve(t : Float, p0 : Point, p1 : Point, p2 : Point, p3 : Point) : Point
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
    
    public function GetPointOnCatmullRom(t : Float) : Point
    {
        var np : Int = GetNumPoints();
        if (np < 4)
        {
            return new Point(0, 0);
        }
        var numSegs : Int = as3hx.Compat.parseInt(np - 1);
        
        var p0 : Point;
        var p1 : Point;
        var p2 : Point;
        var p3 : Point;
        
        var seg : Float = as3hx.Compat.parseFloat(numSegs) * t;
        var i : Int = as3hx.Compat.parseInt(seg);
        
        
        var pt0 : Int = as3hx.Compat.parseInt(i - 1);
        var pt1 : Int = i;
        var pt2 : Int = as3hx.Compat.parseInt(i + 1);
        var pt3 : Int = as3hx.Compat.parseInt(i + 2);
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
        
        p0 = pointList[pt0];
        p1 = pointList[pt1];
        p2 = pointList[pt2];
        p3 = pointList[pt3];
        
        var i1 : Int = as3hx.Compat.parseInt(i + 1);
        var s0 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i;
        var s1 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i1;
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
            var pp : Point = GetPointOnCatmullRom(t1);
            bd.setPixel32(pp.x + xoff, pp.y + yoff, col);
            t1 += 0.001;
        }
    }
    
    
    public function GetNumPoints() : Int
    {
        return pointList.length;
    }
    public function GetNumLines() : Int
    {
        return lineList.length;
    }
    public function GetLine(index : Int) : Line
    {
        return lineList[index];
    }
    public function GetCatmullRomLength() : Float
    {
        return catmullRomLength;
    }
    
    public function GetPoint(index : Int) : Point
    {
        return new Point(pointList[index].x, pointList[index].y);
    }
    public function GetPointNormal(index : Int) : Point
    {
        return new Point(lineList[index].nx, lineList[index].ny);
    }
}


