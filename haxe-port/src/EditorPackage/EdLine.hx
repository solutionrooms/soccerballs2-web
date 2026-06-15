package editorPackage;

import editorPackage.ObjParameters;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author ...
	 */
class EdLine extends EditableObjectBase
{
    public var index : Int;
    public var type : Int;
    public var points : Array<Dynamic>;
    public var fill : Int;
    public var fillScaleX : Float;
    public var fillScaleY : Float;
    public var centrex : Float;
    public var centrey : Float;
    public var fixed : Bool;
    public var primitiveType : String;
    
    public static inline var PRIMITIVE_LINE : String = "line";
    public static inline var PRIMITIVE_RECTANGLE : String = "rectangle";
    public static inline var PRIMITIVE_CIRCLE : String = "circle";
    
    public function new()
    {
        super();
        classType = "line";
        type = 0;
        points = [];
        fill = 0;
        fillScaleX = 1;
        fillScaleY = 1;
        fixed = true;
        
        primitiveType = PRIMITIVE_LINE;
        
        for (i in 0...PolyDefs.instanceParams.length)
        {
            objParameters.Add(PolyDefs.instanceParams[i], PolyDefs.instanceParamsDefaults[i]);
        }
        
        
        centrex = 0;
        centrey = 0;
    }
    
    public var triangleList : Array<Dynamic>;
    public var uvList : Array<Dynamic>;
    
    public function DoTriangulation()
    {
        triangleList = null;
        if (GetNumPoints() < 3)
        {
            return;
        }
        
        var isSpline : Bool = IsSpline();
        
        var pointsToTriangulate : Array<Dynamic> = points;
        
        if (isSpline)
        {
            if (GetNumPoints() < 4)
            {
                return;
            }
            pointsToTriangulate = GetCatmullRomPointsList(points, 0, 0);
        }
        
        
        triangleList = [];
        uvList = [];
        
        var triangulate : Triangulate = new Triangulate();
        var triangulatedVerts : Array<Dynamic> = triangulate.process(pointsToTriangulate);
        
        if (triangulatedVerts == null)
        {
            Utils.traceerror("object failed triangulating: " + pointsToTriangulate.length);
            triangulatedVerts = [];
            for (p in pointsToTriangulate)
            {
                triangulatedVerts.push(p.clone());
            }
        }
        else
        {
        }
        var numTris : Int = as3hx.Compat.parseInt(triangulatedVerts.length / 3);
        for (t in 0...numTris)
        {
            var p0 : Point = triangulatedVerts[(t * 3) + 0];
            var p1 : Point = triangulatedVerts[(t * 3) + 1];
            var p2 : Point = triangulatedVerts[(t * 3) + 2];
            
            triangleList.push(p0.clone());
            triangleList.push(p1.clone());
            triangleList.push(p2.clone());
            
            var scale : Float = 0.001;
            
            uvList.push(new Point((p0.x * scale), (p0.y * scale)));
            uvList.push(new Point((p1.x * scale), (p1.y * scale)));
            uvList.push(new Point((p2.x * scale), (p2.y * scale)));
        }
    }
    
    
    public function GetParameterListForExport() : String
    {
        var exportStr : String = "";
        
        for (i in 0...PolyDefs.instanceParams.length)
        {
            var s : String = PolyDefs.instanceParams[i];
            exportStr += s + "=";
            var s1 : String = objParameters.GetValueString(s);
            exportStr += s1;
            if (i != PolyDefs.instanceParams.length - 1)
            {
                exportStr += ",";
            }
        }
        return exportStr;
    }
    
    
    public function CalculateCentre() : Point
    {
        var x : Float = 0;
        var y : Float = 0;
        for (p in points)
        {
            x += p.x;
            y += p.y;
        }
        x /= points.length;
        y /= points.length;
        return new Point(x, y);
    }
    
    public function AddPoint(x : Float, y : Float)
    {
        points.push(new Point(x, y));
    }
    
    public function SetPointArray(a : Array<Dynamic>)
    {
        points = a;
    }
    
    public function Clone() : EdLine
    {
        var l : EdLine = new EdLine();
        l.classType = classType;
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
    
    
    public var boundingRectangle : Rectangle;
    public function CalcBoundingRectangle()
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
            var x0 : Int = Std.int(p0.x);
            var y0 : Int = Std.int(p0.y);
            var x1 : Int = Std.int(p1.x);
            var y1 : Int = Std.int(p1.y);
            
            if (y1 < y0)
            {
                x0 = Std.int(p1.x);
                y0 = Std.int(p1.y);
                x1 = Std.int(p0.x);
                y1 = Std.int(p0.y);
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
    
    
    
    
    public var catmullRomLength : Float;
    public var segmentLengths : Array<Dynamic>;
    public var segmentRatios : Array<Dynamic>;
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
        
        segmentLengths = [];
        segmentRatios = [];
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
        var l : Array<Dynamic> = [];
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
        
        var seg : Float = as3hx.Compat.parseFloat(numSegs) * t;
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
        var s0 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i;
        var s1 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i1;
        var t1 : Float = 1.0 / (s1 - s0) * (t - s0);
        var p : Point = PointOnCurve(t1, p0, p1, p2, p3);
        
        
        
        return p;
    }
    
    public function GetPointOnCatmullRom_Points(_points : Array<Dynamic>, t : Float, loop : Bool) : Point
    {
        var np : Int = _points.length;
        if (np < 4)
        {
            return new Point(0, 0);
        }
        var numSegs : Int = np;
        
        var p0 : Point;
        var p1 : Point;
        var p2 : Point;
        var p3 : Point;
        
        var seg : Float = as3hx.Compat.parseFloat(numSegs) * t;
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
        
        
        p0 = _points[pt0];
        p1 = _points[pt1];
        p2 = _points[pt2];
        p3 = _points[pt3];
        
        var i1 : Int = as3hx.Compat.parseInt(i + 1);
        var s0 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i;
        var s1 : Float = 1.0 / as3hx.Compat.parseFloat(numSegs) * i1;
        var t1 : Float = 1.0 / (s1 - s0) * (t - s0);
        var p : Point = PointOnCurve(t1, p0, p1, p2, p3);
        
        
        
        return p;
    }
    
    public function GetCatmullRomPointsList(origPoints : Array<Dynamic>, xoff : Float, yoff : Float) : Array<Dynamic>
    {
        var np : Int = origPoints.length;
        if (np < 4)
        {
            return null;
        }
        
        var a : Array<Dynamic> = [];
        var t1 : Float;
        
        var numSubdivs : Int = as3hx.Compat.parseInt(np * 4);
        var adder : Float = 1 / numSubdivs;
        
        t1 = 0;
        while (t1 < 1.0)
        {
            var pp : Point = GetPointOnCatmullRom_Points(origPoints, t1, true);
            a.push(pp);
            t1 += adder;
        }
        return a;
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
    
    
    
    
    
    
    public function GetInterpolatedPoint_SegmentRatio(pos : Float, loop : Bool, isSpline : Bool = false) : Point
    {
        if (isSpline)
        {
            return GetPointOnCatmullRom(pos, loop);
        }
        
        CalculateLength(loop);
        
        
        
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
    public function GetInterpolatedPoint_EqualSpacing(pos : Float, loop : Bool, isSpline : Bool = false) : Point
    {
        if (isSpline)
        {
            return GetPointOnCatmullRom(pos, loop);
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
    
    public function RenderHighlightSelectedPoint(selectedPointIndex : Int, col : Int, rad : Int) : Void
    {
        PhysEditor.linesScreen.graphics.clear();
        
        var layer : Int = GetCurrentLayer();
        if (EditorLayers.IsVisible(layer) == true)
        {
            var thesePoints : Array<Dynamic> = points;
            for (p in thesePoints)
            {
                p = PhysEditor.GetMapPos(p.x, p.y);
            }
            
            
            if (primitiveType == EdLine.PRIMITIVE_LINE)
            {
                for (i in 0...thesePoints.length)
                {
                    if (i == selectedPointIndex)
                    {
                        var r : Rectangle = new Rectangle(0, 0, 1, 1);
                        
                        var pt : Point = PhysEditor.GetMapPos(thesePoints[i].x, thesePoints[i].y);
                        
                        r.x = pt.x - rad;
                        r.y = pt.y - rad;
                        r.width = (rad * 2) + 1;
                        r.height = (rad * 2) + 1;
                        
                        PhysEditor.RenderRectangle(r, col);
                    }
                }
            }
        }
        PhysEditor.screenBD.draw(PhysEditor.linesScreen);
    }
    
    
    override public function GetEditorHoverName() : String
    {
        return "LINE: " + id;
    }
    
    override public function RenderHighlighted(highlightType : Int) : Void
    {
        PhysEditor.linesScreen.graphics.clear();
        
        var points : Array<Dynamic> = PhysEditor.GetMapPosPoints(points);
        
        if (highlightType == HIGHLIGHT_HOVER)
        {
            PhysEditor.FillPoly(points, 0xff0000, 0.5);
        }
        else if (highlightType == HIGHLIGHT_SELECTED)
        {
            PhysEditor.FillPoly(points, 0xffffff, 0.5);
        }
        PhysEditor.screenBD.draw(PhysEditor.linesScreen);
    }
    
    public function RenderInner() : Void
    {
        PhysEditor.linesScreen.graphics.clear();
        
        var _useCursor : Bool = false;
        PhysEditor.GetMousePositions();
        
        var selectedIndex : Int = PhysEditor.editModeObj_Lines.currentLineIndex;
        var selectedPointIndex : Int = PhysEditor.editModeObj_Lines.currentPointIndex;
        
        var lineIndex : Int = this.index;
        
        var p0 : Point = new Point();
        var p1 : Point = new Point();
        var r : Rectangle = new Rectangle();
        
        var layer : Int = GetCurrentLayer();
        var polyMaterial : PolyMaterial = GetCurrentPolyMaterial();
        
        var col : Int = 0xffffff;
        var doNormals : Bool = false;
        var doBitmapFill : Bool = false;
        var thickness : Int = 1;
        var joinPoly : Bool = false;
        var doColorFill : Bool = false;
        var doDirectionArrows : Bool = false;
        
        var isSpline : Bool = IsSpline();
        
        
        if (polyMaterial.edType == "path")
        {
            col = 0x2020ff;
            thickness = 2;
            doNormals = false;
            doBitmapFill = false;
            joinPoly = true;
            doColorFill = false;
            doDirectionArrows = true;
        }
        else if (polyMaterial.edType == "outline")
        {
            col = 0xffffff;
            thickness = 2;
            doNormals = true;
            doBitmapFill = false;
            joinPoly = true;
            doColorFill = false;
            doDirectionArrows = false;
        }
        else if (polyMaterial.edType == "poly")
        {
            col = 0xffffff;
            thickness = 1;
            doNormals = true;
            doBitmapFill = true;
            joinPoly = true;
            doColorFill = false;
            doDirectionArrows = false;
        }
        else if (polyMaterial.edType == "surface")
        {
            col = 0xffff80;
            thickness = 1;
            doNormals = true;
            doBitmapFill = true;
            joinPoly = false;
            doColorFill = false;
            doDirectionArrows = false;
        }
        else
        {
            Utils.print("error, unknown polymaterial type " + polyMaterial.initType);
        }
        
        
        
        
        
        if (EditorLayers.IsVisible(layer) == true)
        {
            var thesePoints : Array<Dynamic> = points;
            if (lineIndex == selectedIndex && _useCursor && primitiveType == EdLine.PRIMITIVE_LINE)
            {
                thesePoints = [];
                for (p0 in points)
                {
                    thesePoints.push(p0.clone());
                }
                thesePoints.push(new Point(PhysEditor.mxs, PhysEditor.mys));
            }
            var points1 : Array<Dynamic> = [];
            for (p in thesePoints)
            {
                var zp : Point = PhysEditor.GetMapPos(p.x, p.y);
                points1.push(zp);
            }
            thesePoints = points1;
            
            
            var np : Int = GetNumPoints();
            
            if (isSpline == false || thesePoints.length < 4)
            {
                if (thesePoints.length >= 2)
                {
                    var i : Int;
                    for (i in 0...thesePoints.length - 1)
                    {
                        p0 = thesePoints[i];
                        p1 = thesePoints[i + 1];
                        PhysEditor.RenderLine(p0.x, p0.y, p1.x, p1.y, col, thickness, 1, doNormals, doDirectionArrows);
                    }
                    if (joinPoly)
                    {
                        p0 = thesePoints[thesePoints.length - 1];
                        p1 = thesePoints[0];
                        PhysEditor.RenderLine(p0.x, p0.y, p1.x, p1.y, col, thickness, 1, doNormals, doDirectionArrows);
                    }
                }
                if (doBitmapFill)
                {
                    var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
                    PhysEditor.FillPolyBitmap(dobj.GetBitmapData(polyMaterial.fillFrame), thesePoints);
                }
                
                
                if (doColorFill)
                {
                    PhysEditor.FillPoly(thesePoints, col, 0.1);
                }
            }
            
            if (isSpline && thesePoints.length >= 4)
            {
                var splinePoints : Array<Dynamic> = GetCatmullRomPointsList(thesePoints, 0, 0);
                
                var i : Int;
                for (i in 0...splinePoints.length - 1)
                {
                    p0 = splinePoints[i];
                    p1 = splinePoints[i + 1];
                    thickness = 1;
                    doNormals = false;
                    doDirectionArrows = false;
                    PhysEditor.RenderLine(p0.x, p0.y, p1.x, p1.y, col, thickness, 1, doNormals, doDirectionArrows);
                }
                
                
                
                
                
                
                if (doBitmapFill)
                {
                    var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
                    PhysEditor.FillPolyBitmap(dobj.GetBitmapData(polyMaterial.fillFrame), splinePoints);
                }
                
                if (doColorFill)
                {
                    PhysEditor.FillPoly(splinePoints, col, 0.1);
                }
            }
            
            if (primitiveType == EdLine.PRIMITIVE_LINE)
            {
                for (i in 0...thesePoints.length)
                {
                    col = 0xffff0000;
                    var off1 : Int = 2;
                    var off2 : Int = 4;
                    r.x = thesePoints[i].x - off1;
                    r.y = thesePoints[i].y - off1;
                    r.width = off2;
                    r.height = off2;
                    
                    PhysEditor.RenderRectangle(r, col);
                }
            }
            
            if (primitiveType == EdLine.PRIMITIVE_RECTANGLE)
            {
                i = 0;
                while (i <= 2)
                {
                    col = 0xffff0000;
                    var off1 : Int = 2;
                    var off2 : Int = 4;
                    r.x = thesePoints[i].x - off1;
                    r.y = thesePoints[i].y - off1;
                    r.width = off2;
                    r.height = off2;
                    
                    PhysEditor.RenderRectangle(r, col);
                    i += 2;
                }
            }
        }
        PhysEditor.screenBD.draw(PhysEditor.linesScreen);
    }
    
    override public function GetCentreHandle() : Point
    {
        return CalculateCentre();
    }
    
    
    override public function MoveBy(_x : Float, _y : Float) : Void
    {
        for (p in points)
        {
            p.x += _x;
            p.y += _y;
        }
    }
    
    override public function HitTestRectangle(r : Rectangle) : Bool
    {
        var layer : Int = GetCurrentLayer();
        
        if (EditorLayers.IsVisible(layer) == true)
        {
            for (p in points)
            {
                if (r.containsPoint(new Point(p.x, p.y)))
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    override public function Duplicate() : EditableObjectBase
    {
        var dup : EditableObjectBase = try cast(Clone(), EditableObjectBase) catch(e:Dynamic) null;
        CopyBaseToDuplicate(dup);
        return dup;
    }
}

