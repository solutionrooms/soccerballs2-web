/**
This code is a quick port of code written in C++ which was submitted to
flipcode.com by John W. Ratcliff
See original code and more information here:
http:
ported to actionscript by Zevan Rosser
www.actionsnippet.com
*/

class Triangulate
{
    public var EPSILON(default, never) : Float = 0.0000000001;
    public function new()
    {
    }
    public function process(contour : Array<Dynamic>) : Array<Dynamic>
    {
        var result : Array<Dynamic> = [];
        var n : Int = contour.length;
        if (n < 3)
        {
            return null;
        }
        var verts : Array<Dynamic> = [];
        /* we want a counter-clockwise polygon in verts */
        var v : Int = 0;        if (0.0 < area(contour))
        {
            for (v in 0...n)
            {
                verts[v] = v;
            }
        }
        else
        {
            for (v in 0...n)
            {
                verts[v] = (n - 1) - v;
            }
        }
        var nv : Int = n;
        /*  remove nv-2 vertsertices, creating 1 triangle every time */
        var count : Int = as3hx.Compat.parseInt(2 * nv);  /* error detection */  
        var m : Int = 0;        m = 0;
v = as3hx.Compat.parseInt(nv - 1);
        while (nv > 2)
        
        /* if we loop, it is probably a non-simple polygon */{
            
            if (0 >= (count--))
            {
                return null;
            }
            /* three consecutive vertices in current polygon, <u,v,w> */
            var u : Int = v;if (nv <= u)
            {
                u = 0;
            }  /* previous */  
            v = as3hx.Compat.parseInt(u + 1);if (nv <= v)
            {
                v = 0;
            }  /* new v	*/  
            var w : Int = as3hx.Compat.parseInt(v + 1);if (nv <= w)
            {
                w = 0;
            }  /* next	 */  
            if (snip(contour, u, v, w, nv, verts))
            {
                var a : Int = 0;                var b : Int = 0;                var c : Int = 0;                var s : Int = 0;                var t : Int = 0;                /* true names of the vertices */
                a = verts[u];b = verts[v];c = verts[w];
                /* output Triangle */
                result.push(contour[a]);
                result.push(contour[b]);
                result.push(contour[c]);
                m++;
                /* remove v from remaining polygon */
                s = v;
t = as3hx.Compat.parseInt(v + 1);
                while (t < nv)
                {
                    verts[s] = verts[t];
                    s++;
                    t++;
                }nv--;
                /* resest error detection counter */
                count = as3hx.Compat.parseInt(2 * nv);
            }
        }
        return result;
    }
    
    public function area(contour : Array<Dynamic>) : Float
    {
        var n : Int = contour.length;
        var a : Float = 0.0;
        var p : Int = as3hx.Compat.parseInt(n - 1);
        var q : Int = 0;
        while (q < n)
        {
            a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
            p = q++;
        }
        return a * 0.5;
    }
    
    public function insideTriangle(ax : Float, ay : Float, bx : Float, by : Float, cx : Float, cy : Float, px : Float, py : Float) : Bool
    {
        var aX : Float = Math.NaN;        var aY : Float = Math.NaN;        var bX : Float = Math.NaN;        var bY : Float = Math.NaN;        var cX : Float = Math.NaN;        var cY : Float = Math.NaN;        var apx : Float = Math.NaN;        var apy : Float = Math.NaN;        var bpx : Float = Math.NaN;        var bpy : Float = Math.NaN;        var cpx : Float = Math.NaN;        var cpy : Float = Math.NaN;        var cCROSSap : Float = Math.NaN;        var bCROSScp : Float = Math.NaN;        var aCROSSbp : Float = Math.NaN;        aX = cx - bx;aY = cy - by;
        bX = ax - cx;bY = ay - cy;
        cX = bx - ax;cY = by - ay;
        apx = px - ax;apy = py - ay;
        bpx = px - bx;bpy = py - by;
        cpx = px - cx;cpy = py - cy;
        aCROSSbp = aX * bpy - aY * bpx;
        cCROSSap = cX * apy - cY * apx;
        bCROSScp = bX * cpy - bY * cpx;
        return ((aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0));
    }
    public function snip(contour : Array<Dynamic>, u : Int, v : Int, w : Int, n : Int, verts : Array<Dynamic>) : Bool
    {
        var p : Int = 0;        var ax : Float = Math.NaN;        var ay : Float = Math.NaN;        var bx : Float = Math.NaN;        var by : Float = Math.NaN;        var cx : Float = Math.NaN;        var cy : Float = Math.NaN;        var px : Float = Math.NaN;        var py : Float = Math.NaN;        ax = Reflect.field(contour, Std.string(verts[u])).x;
        ay = Reflect.field(contour, Std.string(verts[u])).y;
        bx = Reflect.field(contour, Std.string(verts[v])).x;
        by = Reflect.field(contour, Std.string(verts[v])).y;
        cx = Reflect.field(contour, Std.string(verts[w])).x;
        cy = Reflect.field(contour, Std.string(verts[w])).y;
        if (EPSILON > (((bx - ax) * (cy - ay)) - ((by - ay) * (cx - ax))))
        {
            return false;
        }
        for (p in 0...n)
        {
            if ((p == u) || (p == v) || (p == w))
            {
                continue;
            }
            px = Reflect.field(contour, Std.string(verts[p])).x;
            py = Reflect.field(contour, Std.string(verts[p])).y;
            if (insideTriangle(ax, ay, bx, by, cx, cy, px, py))
            {
                return false;
            }
        }
        return true;
    }
}

