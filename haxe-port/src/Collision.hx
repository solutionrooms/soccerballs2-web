import flash.geom.Point;
import flash.geom.Rectangle;
import GameObj;
import Line;

/**
	* ...
	* @author Default
	*/
class Collision
{
    
    
    
    
    public static function PointInConvexPoly(x : Float, y : Float, poly : Array<Dynamic>) : Bool
    {
        var count : Int = poly.length;
        var i : Int = 0;        for (i in 0...count)
        {
            var line : Line = poly[i];
            
            var dot : Float = DotProduct(line.x0 - x, line.y0 - y, line.nx, line.ny);
            if (dot < 0)
            {
                return false;
            }
        }
        return true;
    }
    
    
    
    
    
    
    
    
    
    
    
    public static function GameObjectInPolyBoundingBox(go : GameObj, poly : Poly) : Bool
    {
        var rad : Float = go.radius + 50;
        var x : Float = go.xpos;
        var y : Float = go.ypos;
        
        if (poly.boundingRectangle == null)
        {
            return false;
        }
        
        stats_numBBTests++;
        
        if (x < (poly.boundingRectangle.left - rad))
        {
            return false;
        }
        if (x > (poly.boundingRectangle.right + rad))
        {
            return false;
        }
        if (y < (poly.boundingRectangle.top - rad))
        {
            return false;
        }
        if (y > (poly.boundingRectangle.bottom + rad))
        {
            return false;
        }
        return true;
    }
    
    public static function DistBetween(go0 : GameObj, go1 : GameObj) : Float
    {
        var dx : Float = go1.xpos - go0.xpos;
        var dy : Float = go1.ypos - go0.ypos;
        return Math.sqrt((dx * dx) + (dy * dy));
    }
    public static function Dist2Between(go0 : GameObj, go1 : GameObj) : Float
    {
        var dx : Float = go1.xpos - go0.xpos;
        var dy : Float = go1.ypos - go0.ypos;
        return (dx * dx) + (dy * dy);
    }
    
    public static function DistBetweenPoints(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dx : Float = x1 - x0;
        var dy : Float = y1 - y0;
        return Math.sqrt((dx * dx) + (dy * dy));
    }
    public static function Dist2BetweenPoints(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dx : Float = x1 - x0;
        var dy : Float = y1 - y0;
        return (dx * dx) + (dy * dy);
    }
    
    
    
    
    
    public static var closestX : Float = 0;
    public static var closestY : Float = 0;
    public static var closestInfiniteX : Float = 0;
    public static var closestInfiniteY : Float = 0;
    public static function ClosestPointOnLine(lx0 : Float, ly0 : Float, lx1 : Float, ly1 : Float, x : Float, y : Float) : Float
    {
        var apX : Float = x - lx0;
        var apY : Float = y - ly0;
        var abX : Float = lx1 - lx0;
        var abY : Float = ly1 - ly0;
        var ab2 : Float = (abX * abX) + (abY * abY);
        var ap_ab : Float = (apX * abX) + (apY * abY);
        var t : Float = ap_ab / ab2;
        
        closestInfiniteX = lx0 + (abX * t);
        closestInfiniteY = ly0 + (abY * t);
        
        var origt : Float = t;
        
        if (t < 0.0)
        {
            t = 0.0;
        }
        if (t > 1.0)
        {
            t = 1.0;
        }
        closestX = lx0 + (abX * t);
        closestY = ly0 + (abY * t);
        
        return origt;
    }
    
    
    
    
    
    public static var IntersectionX : Float = 0;
    public static var IntersectionY : Float = 0;
    public static function LineLineIntersection(l0 : Line, l1 : Line) : Bool
    {
        var x0 : Float = l0.x0;
        var y0 : Float = l0.y0;
        var x1 : Float = l0.x1;
        var y1 : Float = l0.y1;
        var x2 : Float = l1.x0;
        var y2 : Float = l1.y0;
        var x3 : Float = l1.x1;
        var y3 : Float = l1.y1;
        
        var d0 : Float = (x1 - x0);
        var d1 : Float = (x3 - x2);
        
        
        var m1 : Float = (y1 - y0) / d0;
        var m2 : Float = (y3 - y2) / d1;
        
        
        
        
        
        
        var c1 : Float = (y0 - m1 * x0);
        var c2 : Float = (y2 - m2 * x2);
        
        var xi : Float = (c1 - c2) / (m2 - m1);
        var yi : Float = m1 * (c2 - c1) / (m1 - m2) + c1;
        
        if (l0.boundingRect.contains(xi, yi))
        {
            if (l1.boundingRect.contains(xi, yi))
            {
                IntersectionX = xi;
                IntersectionY = yi;
                return true;
            }
        }
        return false;
    }
    
    
    
    
    public static function DistToLine(lx0 : Float, ly0 : Float, lx1 : Float, ly1 : Float, x : Float, y : Float) : Float
    {
        ClosestPointOnLine(lx0, ly0, lx1, ly1, x, y);
        
        var dx : Float = closestX - x;
        var dy : Float = closestY - y;
        var dist : Float = Math.sqrt((dx * dx) + (dy * dy));
        return dist;
    }
    public static function Dist2ToLine(lx0 : Float, ly0 : Float, lx1 : Float, ly1 : Float, x : Float, y : Float) : Float
    {
        ClosestPointOnLine(lx0, ly0, lx1, ly1, x, y);
        
        var dx : Float = closestX - x;
        var dy : Float = closestY - y;
        return (dx * dx) + (dy * dy);
    }
    
    
    
    public static function SideOfLine(lx0 : Float, ly0 : Float, lx1 : Float, ly1 : Float, x : Float, y : Float) : Bool
    {
        var dot : Float = DotProduct(lx1 - lx0, ly1 - ly0, x - lx0, y - ly0);
        if (dot < 0.0)
        {
            return false;
        }
        return true;
    }
    
    
    public static function SideOfLine1(l : Line, x : Float, y : Float) : Bool
    {
        var dot : Float = DotProduct(l.x1 - l.x0, l.y1 - l.y0, x - l.x0, y - l.y0);
        if (dot < 0.0)
        {
            return false;
        }
        return true;
    }
    
    
    
    public static function DotProduct(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var dot : Float = (x0 * x1) + (y0 * y1);
        return dot;
    }
    
    
    
    public static function Intersected(go : GameObj, l : Line, intersectionPointX : Float, intersectionPointY : Float, xoff : Float, yoff : Float, rad : Float) : Void
    {
        var numIterations : Int = 50;
        var dx : Float = (go.oldxpos + xoff) - intersectionPointX;
        var dy : Float = (go.oldypos + yoff) - intersectionPointY;
        
        
        dx /= as3hx.Compat.parseFloat(numIterations);
        dy /= as3hx.Compat.parseFloat(numIterations);
        var x : Float = go.xpos + xoff;
        var y : Float = go.ypos + yoff;
        
        var radius2 : Float = rad * rad;
        
        var i : Int = 0;        for (i in 0...numIterations)
        {
            x += dx;
            y += dy;
            var dist2ToLine : Float = Dist2ToLine(l.x0, l.y0, l.x1, l.y1, x, y);
            if (dist2ToLine > radius2)
            {
                go.xpos = x - xoff;
                go.ypos = y - yoff;
                return;
            }
        }
    }
    
    
    
    public static var PolyCollision_LineHit : Line;
    public static function PolyCollision(go : GameObj, poly : Poly, xoff : Float, yoff : Float, rad : Float) : Bool
    {
        stats_numPolyCollisionTests++;
        
        var collidedLines : Array<Dynamic> = [];
        var collidedDists : Array<Dynamic> = [];
        var l : Line = null;        var sideOfLine : Bool;
        var dist2ToLine : Float = Math.NaN;        
        var x : Float = go.xpos + xoff;
        var y : Float = go.ypos + yoff;
        var radius : Float = rad;
        var radius2 : Float = radius * radius;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(poly),lineList) type: null */ in poly.lineList)
        {
            sideOfLine = SideOfLine(line.x0, line.y0, line.x1, line.y1, x, y);
            if (sideOfLine == true)
            {
                dist2ToLine = Dist2ToLine(line.x0, line.y0, line.x1, line.y1, x, y);
                if (dist2ToLine < radius2)
                {
                    collidedLines.push(line);
                    collidedDists.push(dist2ToLine);
                }
            }
        }
        var i : Int = 0;        var j : Int = 0;        var numCollided = collidedLines.length;
        for (i in 0...numCollided - 1)
        {
            for (j in i...numCollided)
            {
                var d0 : Float = collidedDists[i];
                var d1 : Float = collidedDists[j];
                var l0 : Line = collidedLines[i];
                var l1 : Line = collidedLines[j];
                if (d1 < d0)
                {
                    collidedDists[i] = d1;
                    collidedDists[j] = d0;
                    collidedLines[i] = l1;
                    collidedLines[j] = l0;
                }
            }
        }
        
        for (i in 0...numCollided)
        {
            l = collidedLines[i];
            sideOfLine = SideOfLine(l.x0, l.y0, l.x1, l.y1, x, y);
            if (sideOfLine == true)
            {
                dist2ToLine = Dist2ToLine(l.x0, l.y0, l.x1, l.y1, x, y);
                if (dist2ToLine < radius2)
                {
                    stats_numIntersections++;
                    Intersected(go, l, closestX, closestY, xoff, yoff, rad);
                    PolyCollision_LineHit = l;
                    return true;
                }
            }
            return true;
        }
        
        return false;
    }
    
    
    
    
    public static function PlayerPickupCollision()
    {
        var bugs : Array<Dynamic> = GameObjects.GetGameObjListByName("bug");
        var pickups : Array<Dynamic> = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && go.colFlag_canBePickedUp)
            {
                pickups.push(go);
            }
        }
        for (go in bugs)
        {
            for (go1 in pickups)
            {
                if (go1.killed == false)
                {
                    var dist : Float = 10 + go1.radius;
                    if (Utils.DistBetweenPoints(go.xpos, go.ypos, go1.xpos, go1.ypos) < dist)
                    {
                        if (go1.onHitFunction)
                        {
                            go1.onHitFunction(go);
                        }
                    }
                }
            }
        }
    }
    
    public static function PlayerSwitchCollision()
    {
        var bugs : Array<Dynamic> = GameObjects.GetGameObjListByName("bug");
        var switches : Array<Dynamic> = GameObjects.GetGameObjListByName("switch");
        
        var dist : Float = 30;
        
        
        for (go in bugs)
        {
            for (go1 in switches)
            {
                if (go1.Switch_IsInContactList(go) == false)
                {
                    if (Utils.DistBetweenPoints(go.xpos, go.ypos, go1.xpos, go1.ypos) < dist)
                    {
                        if (go1.doSwitchFunction != null)
                        {
                            if (go1.switchType == "2way")
                            {
                                go1.Switch_AddToContactList(go);
                            }
                            if (go1.doSwitchFunction())
                            {
                                Game.DoGameObjSwitch(go1);
                            }
                        }
                    }
                }
            }
        }
        
        var removeList : Array<Dynamic> = [];
        for (go1 in switches)
        {
            for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(go1),switchContactList) type: null */ in (go1.switchContactList : Array<Dynamic>))
            {
                if (Utils.DistBetweenPoints(go.xpos, go.ypos, go1.xpos, go1.ypos) >= dist)
                {
                    removeList.push(go);
                }
            }
            for (go in removeList)
            {
                go1.Switch_RemoveFromContactList(go);
            }
        }
    }
    public static function ProjectileGoPhysObjCollision()
    {
        for (goVehicle/* AS3HX WARNING could not determine type for var: goVehicle exp: EIdent(ProjectileList) type: null */ in ProjectileList)
        {
            var vx : Float = goVehicle.xpos;
            var vy : Float = goVehicle.ypos;
            for (goObj/* AS3HX WARNING could not determine type for var: goObj exp: EIdent(PhysObjList) type: null */ in PhysObjList)
            {
                var d : Float = goObj.radius + 20;
                var d2 : Float = d * d;
                var dx : Float = vx - goObj.xpos;
                var dy : Float = vy - goObj.ypos;
                dx += goObj.colOffsetX;
                dy += goObj.colOffsetY;
                var h : Float = (dx * dx) + (dy * dy);
                
                if (h < d2)
                {
                    if (goObj.onHitFunction != null)
                    {
                        goObj.onHitFunction(goVehicle);
                    }
                }
            }
        }
    }
    
    public static var ProjectileList : Array<GameObj> = [];
    public static var PhysObjList : Array<GameObj> = [];
    
    public static function MakeLists()
    {
        ProjectileList.splice(0, ProjectileList.length);
        PhysObjList.splice(0, PhysObjList.length);
        
        var go : GameObj = null;        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.colFlag_isBall)
            {
                ProjectileList.push(go);
            }
            if (go.active && go.colFlag_isGoPhysObj && go.killed == false)
            {
                PhysObjList.push(go);
            }
        }
    }
    
    public static function Update()
    {
        stats_numIntersections = 0;
        stats_numBBTests = 0;
        stats_numPolyCollisionTests = 0;
        
        
        EngineDebug.StartTimer("collision");
        
        
        
        
        EngineDebug.EndTimer("collision");
    }
    
    public static var main : Main;
    public static var stats_numIntersections : Int = 0;
    public static var stats_numBBTests : Int = 0;
    public static var stats_numPolyCollisionTests : Int = 0;

    public function new()
    {
    }
}


