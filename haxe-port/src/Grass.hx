import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.Vec2;

/**
	 * ...
	 * @author
	 */
class Grass
{
    public static var list : Array<GrassItem>;
    public static var segmentList : Array<GrassSegment>;
    public static var frames : Array<GrassFrame>;
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        list = [];
        
        frames = [];
        AddFrames("grass_fairway");
        AddFrames("grass_rough");
    }
    
    public static function GetGrassFrame(mcName : String, f : Int) : GrassFrame
    {
        for (gf in frames)
        {
            if (gf.frameIndex == f && gf.mcName == mcName)
            {
                return gf;
            }
        }
        return null;
    }
    
    public static function AddFrames(mcName : String)
    {
    }
    
    public static function InitForLevel()
    {
        list = [];
    }
    
    
    
    public static function GetRandomPoint() : Point
    {
        var r : Int = Utils.RandBetweenInt(0, list.length - 1);
        return new Point(list[r].xpos, list[r].ypos);
    }
    public static function RenderAll(bd : BitmapData)
    {
        EngineDebug.StartTimer("grass");
        var sc : Float = Game.camera.scale;
        var cx : Float = Game.camera.x;
        var cy : Float = Game.camera.y;
        
        
        
        
        var renderIt : Bool = true;
        
        
        var mat : Matrix = new Matrix();
        
        var sc : Float = Game.camera.scale;
        var x0 : Float = 0;
        var x1 : Float = (Defs.displayarea_w) * (1 / sc);
        var y0 : Float = 0;
        var y1 : Float = (Defs.displayarea_h) * (1 / sc);
        
        
        var frameIndex : Int = 0;
        
        
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("grass_rough");
        
        var skipCount : Int = 0;
        var numSegs : Int = 0;
        var numGrass : Int = 0;
        for (seg in segmentList)
        {
            var xp0 : Float = (seg.x0 - cx);
            var xp1 : Float = (seg.x1 - cx);
            var yp0 : Float = (seg.y0 - cy);
            var yp1 : Float = (seg.y1 - cy);
            
            if ((xp1 >= x0 && xp0 <= x1) && (yp1 >= y0 && yp0 <= y1))
            {
                var i : Int = 0;
                i = 0;
                while (i < seg.list.length)
                {
                    var g : GrassItem = seg.list[i];
                    var xp : Float = Math.round(g.xpos - cx);
                    var yp : Float = Math.round(g.ypos - cy);
                    
                    if (g.rot == 0)
                    {
                        dobj.RenderAt(g.frameIndex, bd, xp, yp);
                    }
                    else
                    {
                        dobj.RenderAtRotScaled(g.frameIndex, bd, xp, yp, 1, g.rot);
                    }
                    numGrass++;
                    i += 1;
                }
                numSegs++;
            }
            else
            {
                skipCount++;
            }
        }
        EngineDebug.EndTimer("grass");
    }
    
    
    
    
    public static var minX : Float;
    public static var maxX : Float;
    public static var minY : Float;
    public static var maxY : Float;
    public static function PreRenderLines()
    {
        segmentList = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.preRenderFunction1 != null)
            {
                list = [];
                go.preRenderFunction1();
                
                minX = 9999999;
                maxX = -9999999;
                minY = 9999999;
                maxY = -9999999;
                for (g in list)
                {
                    if (g.xpos < minX)
                    {
                        minX = g.xpos;
                    }
                    if (g.xpos > maxX)
                    {
                        maxX = g.xpos;
                    }
                    if (g.ypos < minY)
                    {
                        minY = g.ypos;
                    }
                    if (g.ypos > maxY)
                    {
                        maxY = g.ypos;
                    }
                }
                
                var segWidth : Int = 100;
                
                var x0 : Int = as3hx.Compat.parseInt(minX);
                while (x0 < maxX)
                {
                    var seg : GrassSegment = new GrassSegment();
                    
                    seg.boundingRect = new Rectangle(x0, minY, x1 - x0, maxY - minY);
                    
                    var x1 : Int = as3hx.Compat.parseInt(x0 + segWidth);
                    seg.x0 = x0;
                    seg.x1 = x1;
                    seg.y0 = minY;
                    seg.y1 = maxY;
                    
                    for (g in list)
                    {
                        if (g.xpos >= x0 && g.xpos <= x1)
                        {
                            seg.list.push(g);
                        }
                    }
                    segmentList.push(seg);
                    x0 += segWidth;
                }
            }
        }
    }
    
    public static function Update()
    {
        var cx : Float = Game.camera.x;
        var cy : Float = Game.camera.y;
        var sc : Float = 1;
        
        var x0 : Float = 0;
        var x1 : Float = (Defs.displayarea_w) * (1 / sc);
        var y0 : Float = 0;
        var y1 : Float = (Defs.displayarea_h) * (1 / sc);
        
        var go : GameObj = GameVars.footballGO;
        if (go == null)
        {
            return;
        }
        
        var doCol : Bool = true;
        if (go.GetBodyLinearVelocity(0).length < 20)
        {
            doCol = false;
        }
        
        var l : Float = go.GetBodyLinearVelocity(0).length;
        
        var go_x : Float = go.xpos;
        var go_y : Float = go.ypos;
        var d2test : Float = 15 * 15;
        
        var updatesegcount : Int = 0;
        var skipsegcount : Int = 0;
        
        for (seg in segmentList)
        {
            var xp0 : Float = (seg.x0 - cx);
            var xp1 : Float = (seg.x1 - cx);
            var yp0 : Float = (seg.y0 - cy);
            var yp1 : Float = (seg.y1 - cy);
            
            
            if (doCol)
            {
                if ((go_x >= seg.x0 - 30 && go_x <= seg.x1 + 30) && (go_y >= seg.y0 - 30 && go_y <= seg.y1 + 30))
                {
                    for (g/* AS3HX WARNING could not determine type for var: g exp: EField(EIdent(seg),list) type: null */ in seg.list)
                    {
                        if (g.timer == 0)
                        {
                            var dx : Float = g.xpos - go_x;
                            var dy : Float = g.ypos - go_y;
                            var d2 : Float = ((dx * dx) + (dy * dy));
                            if (d2 < d2test)
                            {
                                g.timer = Utils.RandBetweenInt(20, 20);
                            }
                        }
                    }
                }
            }
            
            
            if ((xp1 >= x0 && xp0 <= x1) && (yp1 >= y0 && yp0 <= y1))
            {
                for (g/* AS3HX WARNING could not determine type for var: g exp: EField(EIdent(seg),list) type: null */ in seg.list)
                {
                    if (g.timer > 0)
                    {
                        g.timer--;
                        
                        if (Math.random() < 0.5)
                        {
                            g.rot += 0.1;
                            if (g.rot > 1)
                            {
                                g.rot = 1;
                            }
                        }
                        else
                        {
                            g.rot -= 0.1;
                            if (g.rot < -1)
                            {
                                g.rot = -1;
                            }
                        }
                        if (g.timer <= 0)
                        {
                            g.rot = 0;
                        }
                    }
                }
            }
        }
    }
    public static function RemoveHiddenGrass()
    {
        PhysicsBase.SetCurrentSpace(1);
        for (g in list)
        {
            var r : Ray = new Ray(new Vec2(g.xpos, g.ypos - 5), new Vec2(0, -1));
            r.maxDistance = 500;
            var filter : InteractionFilter = new InteractionFilter(1, 1, 0, 0, 0, 0);
            var rr : RayResult = PhysicsBase.GetNapeSpace().rayCast(r, true, filter);
            if (rr != null)
            {
                g.visible = false;
                var p : Vec2 = r.at(rr.distance);
            }
        }
        PhysicsBase.SetCurrentSpace(0);
    }
    
    
    public static function AddLine(p0 : Point, p1 : Point, mcName : String)
    {
        var sc : Float = Game.camera.scale;
        var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(mcName);
        var numF : Int = dobj.GetNumFrames();
        if (p1.x > p0.x)
        {
            var ang : Float = Math.abs(p1.y - p0.y) / Math.abs(p1.x - p0.x);
            if (ang < 0.7)
            {
                var dx : Float = p1.x - p0.x;
                var dy : Float = p1.y - p0.y;
                var total : Float = dx / 6;
                dx /= total;
                dy /= total;
                for (j in 0...total)
                {
                    var f : Int = Utils.RandBetweenInt(0, numF - 1);
                    
                    var xoffset : Float = Utils.RandBetweenInt(-1, 1);
                    
                    var grassFrame : GrassFrame = GetGrassFrame(mcName, f);
                    
                    list.push(new GrassItem(p0.x + xoffset, p0.y + 1, grassFrame, f));
                    p0.x += dx;
                    p0.y += dy;
                }
            }
        }
    }
}


