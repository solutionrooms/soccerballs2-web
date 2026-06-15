
import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.geom.Point;
import flash.system.System;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;

class GameObjects
{
    public static var objs : Array<GameObj>;
    public static var activeIndices : Array<Int>;
    public static var inactiveIndices : Array<Int>;
    public static var zorder : Array<Dynamic>;
    public static var numActive : Int;
    public static var numInactive : Int;
    public static var numobjs : Int;
    
    public static function InitOnce(_numObjs : Int)
    {
        numobjs = _numObjs;
        objs = [];
        activeIndices = [];
        inactiveIndices = [];
        zorder = [];
        
        var i : Dynamic;
        for (i in 0...numobjs)
        {
            objs[i] = new GameObj();
            objs[i].listIndex = i;
            activeIndices[i] = -1;
            inactiveIndices[i] = i;
            objs[i].activeListIndex = -1;
            objs[i].inactiveListIndex = i;
        }
        
        numActive = 0;
        numInactive = numobjs;
    }
    
    public function GameObjGroup()
    {
    }
    
    public static function ClearAll()
    {
        var i : Int;
        for (i in 0...numobjs)
        {
            objs[i].active = false;
            objs[i].listIndex = i;
            activeIndices[i] = -1;
            inactiveIndices[i] = i;
        }
        numActive = 0;
        numInactive = numobjs;
    }
    
    public static function GetGOByIndex(_index : Int) : GameObj
    {
        return objs[_index];
    }
    
    
    public static var lastGenIndex : Int;
    public static function AddObj(_xpos : Float, _ypos : Float, _zpos : Float) : GameObj
    /*
			var nextAvailableIndex:int = inactiveIndices[numInactive-1];
			var go:GameObj = objs[nextAvailableIndex];
			numInactive--;

			Utils.trace("initing index " + nextAvailableIndex + ".   numInactive: " + numInactive);



					go.active = true;
					go.zpos = _zpos;
					go.xpos = _xpos;
					go.ypos = _ypos;
					go.startx = _xpos;
					go.starty = _ypos;
					go.startz = _zpos;
					go.Init(0);
					lastGenIndex = nextAvailableIndex;
					return go;
					*/
    {
        
        
        var i : Int;
        for (i in 0...numobjs)
        {
            if (objs[i].active == false)
            {
                var go : GameObj = objs[i];
                go.active = true;
                go.zpos = _zpos;
                go.xpos = _xpos;
                go.ypos = _ypos;
                go.startx = _xpos;
                go.starty = _ypos;
                go.startz = _zpos;
                go.Init(0);
                lastGenIndex = i;
                
                return objs[i];
            }
        }
        trace("ERROR! NO FREE OBJECTS");
        lastGenIndex = -1;
        return null;
    }
    
    
    public static function ForEachActive(cb : Function) : Void
    {
        var go : GameObj;
        var list : Array<Dynamic> = [];
        for (go in objs)
        {
            if (go.active)
            {
                cb(go);
            }
        }
    }
    
    
    public var v : Array<GameObj> = [];
    
    public static function zcompare(x : Point, y : Point) : Float
    {
        if (x.y > y.y)
        {
            return -1;
        }
        if (x.y < y.y)
        {
            return 1;
        }
        return 0;
    }
    
    public static function RenderZposBelow(bd : BitmapData, zpos)
    {
        var go : GameObj;
        var i : Int;
        
        EngineDebug.StartTimer("sort");
        
        i = 0;
        zorder = [];
        for (go in objs)
        {
            if (go.active && go.visible)
            {
                zorder.push(go);
                i++;
            }
        }
        zorder.sortOn("zpos", Array.NUMERIC | Array.DESCENDING);
        
        EngineDebug.EndTimer("sort");
        
        
        for (a in 0...i)
        {
            go = Reflect.field(zorder, Std.string(a));
            if (go.zpos < zpos)
            {
                go.Render(bd);
            }
        }
    }
    public static function RenderZposAboveEqual(bd : BitmapData, zpos)
    {
        var go : GameObj;
        var i : Int;
        
        EngineDebug.StartTimer("sort");
        
        i = 0;
        zorder = [];
        for (go in objs)
        {
            if (go.active && go.visible)
            {
                zorder.push(go);
                i++;
            }
        }
        zorder.sortOn("zpos", Array.NUMERIC | Array.DESCENDING);
        
        EngineDebug.EndTimer("sort");
        
        
        for (a in 0...i)
        {
            go = Reflect.field(zorder, Std.string(a));
            if (go.zpos >= zpos)
            {
                go.Render(bd);
            }
        }
    }
    
    
    public static function Render(bd : BitmapData) : Void
    {
        var go : GameObj;
        var i : Int;
        
        EngineDebug.StartTimer("sort");
        
        
        
        i = 0;
        zorder.splice(0, zorder.length);
        for (go in objs)
        {
            if (go.active && go.visible)
            {
                zorder.push(go);
                i++;
            }
        }
        zorder.sortOn("zpos", Array.NUMERIC | Array.DESCENDING);
        
        EngineDebug.EndTimer("sort");
        
        
        
        
        
        
        for (a in 0...i)
        {
            go = Reflect.field(zorder, Std.string(a));
            
            go.Render(bd);
        }
    }
    
    
    public static function CountByName(_name : String) : Int
    {
        var count : Int = 0;
        var i : Int;
        for (i in 0...objs.length)
        {
            if (objs[i].active == true && objs[i].name == _name)
            {
                count++;
            }
        }
        return count;
    }
    public static function CountActive() : Int
    {
        var count : Int = 0;
        var i : Int;
        for (i in 0...objs.length)
        {
            if (objs[i].active == true)
            {
                count++;
            }
        }
        return count;
    }
    
    
    
    public static function UpdateMultiplePhysicsUpdateObjects() : Void
    {
        for (go in objs)
        {
            if (go.active == true && go.useMultiplePhysicsUpdates)
            {
                go.Update();
            }
        }
    }
    public static function Update() : Void
    {
        for (go in objs)
        {
            if (go.active == true)
            {
                go.Update();
            }
        }
    }
    public static function UpdateWalkthroughObjects() : Void
    {
        for (go in objs)
        {
            if (go.active == true)
            {
                if (go.updateInWalkthrough)
                {
                    go.Update();
                }
            }
        }
    }
    public static function KillObjects() : Void
    {
        var deleteList : Array<Dynamic> = [];
        for (go in objs)
        {
            if (go.active == true && go.killed)
            {
                go.active = false;
                deleteList.push(go);
            }
        }
        
        for (go in deleteList)
        {
            if (go.removeFunction != null)
            {
                go.removeFunction();
            }
        }
    }
    
    public static var addList : Array<Dynamic>;
    public static function DoAddList() : Void
    {
        for (o1 in addList)
        {
            o1.fn(o1.o);
        }
    }
    public static function ClearAddList() : Void
    {
        addList = [];
    }
    
    public static function AddToAddList(_fn : Function, ob : Dynamic) : Void
    {
        var o1 : Dynamic = {};
        o1.fn = _fn;
        o1.o = ob;
        addList.push(o1);
    }
    
    
    
    public static function GetGameObjListByNameList(names : String) : Array<Dynamic>
    {
        var list : Array<Dynamic> = [];
        
        var nameList : Array<Dynamic> = names.split(",");
        for (name in nameList)
        {
            var l1 : Array<Dynamic> = GetGameObjListByName(name);
            for (go in l1)
            {
                list.push(go);
            }
            l1 = null;
        }
        return list;
    }
    
    
    public static function GetGameObjListByName(name : String) : Array<Dynamic>
    {
        var list : Array<Dynamic> = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && go.name == name)
            {
                list.push(go);
            }
        }
        return list;
    }
    public static function GetGameObjVectorByName(name : String) : Array<GameObj>
    {
        var list : Array<GameObj> = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && go.name == name)
            {
                list.push(go);
            }
        }
        return list;
    }
    
    public static function GetGameObjByName(name : String) : GameObj
    {
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && go.name == name)
            {
                return go;
            }
        }
        return null;
    }
    
    
    public static function GetGameObjById(id : String) : GameObj
    {
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && go.id == id)
            {
                return go;
            }
        }
        return null;
    }
    
    public static function GetGameObjByLineName(name : String) : GameObj
    {
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.linkedPhysLine != null)
            {
                if (go.linkedPhysLine.id == name)
                {
                    return go;
                }
            }
        }
        return null;
    }
    
    
    public static function GetGameObjListByFlag(name : String) : Array<Dynamic>
    {
        var list : Array<Dynamic> = [];
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active == true && Reflect.field(go, name) == true)
            {
                list.push(go);
            }
        }
        return list;
    }
    
    public static function GetNearestGameObjByName(name : String, x : Float, y : Float) : GameObj
    {
        var nearestGO : GameObj;
        var nearestD : Int = 999999;
        var go : GameObj;
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go.name == name)
            {
                var d : Float = Utils.DistBetweenPoints(x, y, go.xpos, go.ypos);
                if (d < nearestD)
                {
                    nearestD = as3hx.Compat.parseInt(d);
                    nearestGO = go;
                }
            }
        }
        return nearestGO;
    }
    
    
    public static function UpdateSingleGOsFromPhysics(go : GameObj) : Void
    {
        go.xpos = go.nape_bodies[0].position.x;
        go.ypos = go.nape_bodies[0].position.y;
    }
    
    public static function UpdateGOsFromPhysics_Nape() : Void
    {
        var go : GameObj;
        
        var bodyList : BodyList = PhysicsBase.GetNapeSpace().bodies;
        
        for (i in 0...bodyList.length)
        {
            var b : Body = bodyList.at(i);
            var bud : PhysObjBodyUserData = try cast(b.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
            if (bud != null)
            {
                var index : Int = bud.gameObjectIndex;
                
                if (index != -1)
                {
                    go = GameObjects.objs[index];
                    if (go.updateFromPhysicsFunction != null)
                    {
                        go.updateFromPhysicsFunction(b);
                    }
                    else
                    {
                        go.oldxpos = go.xpos;
                        go.oldypos = go.ypos;
                        
                        go.xpos = b.position.x;
                        go.ypos = b.position.y;
                        go.dir = b.rotation;
                    }
                }
            }
        }
    }
    
    public static function PreUpdateGOsBeforePhysics() : Void
    {
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            go.oldxpos = go.xpos;
            go.oldypos = go.ypos;
            go.oldrot = go.dir;
        }
    }

    public function new()
    {
    }
}



