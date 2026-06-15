import editorPackage.EdJoint;
import editorPackage.EdLine;
import editorPackage.EdObj;
import fl.controls.List;
import flash.geom.Point;

/**
	 * ...
	 * @author LongAnimals
	 */
class Levels
{
    public static var currentIndex : Int;
    public static var list : Array<Level>;
    
    public function new()
    {
    }
    
    public static function SetCurrentByName(name : String)
    {
        for (i in 0...list.length)
        {
            if (list[i].name == name)
            {
                currentIndex = i;
            }
        }
    }
    
    public static function GetCurrent() : Level
    {
        if (currentIndex < 0)
        {
            return null;
        }
        if (currentIndex >= list.length)
        {
            return null;
        }
        LoadLevel(currentIndex, false);
        return list[currentIndex];
    }
    
    public static function CountPerfectLevels() : Int
    {
        var count : Int = 0;
        for (l in list)
        {
            if (l.complete && l.rating != 0)
            {
                count++;
            }
        }
        return count;
    }
    
    public static function LoadAll()
    {
        list = [];
        var x : FastXML = ExternalData.levelsXml;
        var num = x.nodes.level.length();
        for (i in 0...num)
        {
            PreLoadLevel(i);
            LoadLevel(i);
        }
    }
    
    
    public static function PreLoadLevel(l : Int)
    {
        var x : FastXML = ExternalData.levelsXml;
        x = x.nodes.level.get(l);
        var level : Level;
        level = new Level();
        
        level.fullyLoaded = false;
        
        level.available = false;
        level.complete = false;
        
        level.id = XmlHelper.GetAttrString(x.att.id, "1");
        level.name = XmlHelper.GetAttrString(x.att.name, "undefined");
        level.displayName = XmlHelper.GetAttrString(x.att.displayname, "undefined");
        level.category = XmlHelper.GetAttrInt(x.att.category, 0);
        level.bgFrame = XmlHelper.GetAttrInt(x.att.bg, 1);
        level.creator = XmlHelper.GetAttrString(x.att.creator, "");
        
        LoadGameSpecificLevelData(level, x);
        
        var i : Int;
        for (i in 0...x.nodes.helpscreen.length())
        {
            var xx : FastXML = x.nodes.helpscreen.get(i);
            level.helpscreenFrames.push(XmlHelper.GetAttrInt(xx.att.frame, 0));
        }
        
        
        
        list.push(level);
    }
    
    
    public static function LoadGameSpecificLevelData(level : Level, x : FastXML)
    {
        level.goldKicks = XmlHelper.GetAttrInt((untyped x.node.soccerballs.innerData.att).gold, 1);
        level.failKicks = XmlHelper.GetAttrInt(x.node.soccerballs.att.fail, 3);
        
        level.totalCoins = 0;
        level.hasTrophy = false;
        level.trophyIndex = 0;
        
        var i : Int;
        var j : Int;
        for (j in 0...x.nodes.objgroup.length())
        {
            var objgrx : FastXML = x.nodes.objgroup.get(j);
            for (i in 0...objgrx.nodes.obj.length())
            {
                var lo : FastXML = objgrx.nodes.obj.get(i);
                var type : String = lo.att.type;
                if (type == "pickup_normal")
                {
                    level.totalCoins++;
                }
                if (type.indexOf("pickup_trophy_") != -1)
                {
                    var s : String = type.substr(14);
                    level.trophyIndex = as3hx.Compat.parseInt(s);
                    
                    level.hasTrophy = true;
                }
            }
        }
    }
    
    public static function GetGameSpecificLevelDataXML(_level : Int) : String
    {
        var s : String;
        var l : Level = GetLevel(_level);
        s = "\t<soccerballs";
        s += " gold=\"" + l.goldKicks + "\"";
        s += " fail=\"" + l.failKicks + "\"";
        s += " />";
        return s;
    }
    
    
    public static function LoadLevel(l : Int, simple : Bool = true)
    {
        var level : Level = list[l];
        
        
        if (level.fullyLoaded)
        {
            return;
        }
        
        var x : FastXML = ExternalData.levelsXml;
        x = x.nodes.level.get(l);
        
        var level : Level;
        
        
        level.Calculate();
        
        level.fullyLoaded = true;
        
        
        var i : Int;
        var j : Int;
        
        level.lines = [];
        
        for (i in 0...x.nodes.line.length())
        {
            var linex : FastXML = x.nodes.line.get(i);
            var line : EdLine = new EdLine();
            line.id = XmlHelper.GetAttrString(linex.att.id, "");
            line.type = XmlHelper.GetAttrInt(linex.att.type, 0);
            for (j in 0...linex.nodes.points.length())
            {
                var pointsx : FastXML = linex.nodes.points.get(j);
                var pointsstr : String = XmlHelper.GetAttrString(pointsx.att.a, "");
                var pts : Array<Dynamic> = Utils.PointArrayFromString(pointsstr);
                for (p1 in pts)
                {
                    line.points.push(p1);
                }
            }
            var params : String = XmlHelper.GetAttrString(linex.att.params, "");
            line.objParameters.ValuesFromString(params);
            
            level.lines.push(line);
        }
        
        
        for (j in 0...x.nodes.objgroup.length())
        {
            var objgrx : FastXML = x.nodes.objgroup.get(j);
            for (i in 0...objgrx.nodes.obj.length())
            {
                var lo : FastXML = objgrx.nodes.obj.get(i);
                
                
                var id : String = XmlHelper.GetAttrString(lo.att.id, "");
                var type : String = lo.att.type;
                var px : Float = as3hx.Compat.parseFloat(lo.att.x);
                var py : Float = as3hx.Compat.parseFloat(lo.att.y);
                var rot : Float = as3hx.Compat.parseFloat(lo.att.rot);
                var scale : Float = XmlHelper.GetAttrNumber(lo.att.scale, 1);
                var params : String = XmlHelper.GetAttrString(lo.att.params, "");
                
                if (params == "")
                {
                    var aa : Int = 0;
                }
                
                var po : PhysObj = Game.objectDefs.FindByName(type);
                var params1 : String = po.GetInstanceParamsAsString();
                
                params = params1 + "," + params;
                
                var inst : EdObj = CreateLevelObjInstanceAt(type, px, py, rot, scale, "", params);
                inst.id = id;
                level.instances.push(inst);
            }
        }
        
        for (i in 0...x.nodes.obj.length())
        {
            var lo : FastXML = x.nodes.obj.get(i);
            
            var id : String = XmlHelper.GetAttrString(lo.att.id, "");
            var type : String = lo.att.type;
            var px : Float = as3hx.Compat.parseFloat(lo.att.x);
            var py : Float = as3hx.Compat.parseFloat(lo.att.y);
            var rot : Float = as3hx.Compat.parseFloat(lo.att.rot);
            var scale : Float = XmlHelper.GetAttrNumber(lo.att.scale, 1);
            var params : String = XmlHelper.GetAttrString(lo.att.params, "");
            
            var inst : EdObj = CreateLevelObjInstanceAt(type, px, py, rot, scale, "", params);
            inst.id = id;
            level.instances.push(inst);
        }
        
        
        level.joints = [];
        for (i in 0...x.node.joints.nodes.joint.length())
        {
            var jx : FastXML = x.node.joints.nodes.joint.get(i);
            var joint : EdJoint = new EdJoint();
            
            joint.id = XmlHelper.GetAttrString(jx.att.id, "");
            var typeStr : String = XmlHelper.GetAttrString(jx.att.type, "");
            if (typeStr == "rev")
            {
                joint.SetType(EdJoint.Type_Rev);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
                joint.rev_pos.x = XmlHelper.GetAttrNumber(jx.att.x, 0);
                joint.rev_pos.y = XmlHelper.GetAttrNumber(jx.att.y, 0);
            }
            if (typeStr == "dist")
            {
                joint.SetType(EdJoint.Type_Distance);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
                joint.dist_pos0.x = XmlHelper.GetAttrNumber(jx.att.x0, 0);
                joint.dist_pos0.y = XmlHelper.GetAttrNumber(jx.att.y0, 0);
                joint.dist_pos1.x = XmlHelper.GetAttrNumber(jx.att.x1, 0);
                joint.dist_pos1.y = XmlHelper.GetAttrNumber(jx.att.y1, 0);
            }
            if (typeStr == "prism")
            {
                joint.SetType(EdJoint.Type_Prismatic);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
                joint.prism_pos.x = XmlHelper.GetAttrNumber(jx.att.x0, 0);
                joint.prism_pos.y = XmlHelper.GetAttrNumber(jx.att.y0, 0);
                joint.prism_pos1.x = XmlHelper.GetAttrNumber(jx.att.x1, 0);
                joint.prism_pos1.y = XmlHelper.GetAttrNumber(jx.att.y1, 0);
            }
            if (typeStr == "switch")
            {
                joint.SetType(EdJoint.Type_Switch);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
            }
            if (typeStr == "logic")
            {
                joint.SetType(EdJoint.Type_LogicLink);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
            }
            if (typeStr == "weld")
            {
                joint.SetType(EdJoint.Type_Weld);
                joint.obj0Name = XmlHelper.GetAttrString(jx.att.objid0, "");
                joint.obj1Name = XmlHelper.GetAttrString(jx.att.objid1, "");
            }
            var params : String = XmlHelper.GetAttrString(jx.att.params, "");
            joint.objParameters.ValuesFromString(params);
            level.joints.push(joint);
        }
        
        
        if (x.nodes.map.length() != 0)
        {
            level.map = [];
            var xm : FastXML = x.nodes.map.get(0);
            level.mapMinX = XmlHelper.GetAttrInt(xm.att.minx, 0);
            level.mapMaxX = XmlHelper.GetAttrInt(xm.att.maxx, 0);
            level.mapMinY = XmlHelper.GetAttrInt(xm.att.miny, 0);
            level.mapMaxY = XmlHelper.GetAttrInt(xm.att.maxy, 0);
            level.mapCellW = XmlHelper.GetAttrInt(xm.att.cellw, 32);
            level.mapCellH = XmlHelper.GetAttrInt(xm.att.cellh, 32);
            
            for (j in 0...xm.nodes.mapdata.length())
            {
                var xmd : FastXML = xm.nodes.mapdata.get(j);
                var xmdstr : String = XmlHelper.GetAttrString(xmd.att.a, "");
                var pts : Array<Dynamic> = Utils.HexArrayFromString(xmdstr);
                for (char in pts)
                {
                    level.map.push(char);
                }
            }
        }
    }
    
    
    public static function GetCurrentLevelInstances() : Array<Dynamic>
    {
        if (currentIndex < 0)
        {
            return null;
        }
        if (currentIndex >= list.length)
        {
            return null;
        }
        LoadLevel(currentIndex, false);
        return list[currentIndex].instances;
    }
    
    public static function GetCurrentLevelJoints() : Array<Dynamic>
    {
        if (currentIndex < 0)
        {
            return null;
        }
        if (currentIndex >= list.length)
        {
            return null;
        }
        LoadLevel(currentIndex, false);
        return list[currentIndex].joints;
    }
    
    
    public static function GetLevel(_lev : Int) : Level
    {
        if (_lev < 0)
        {
            return null;
        }
        if (_lev >= list.length)
        {
            return null;
        }
        LoadLevel(_lev, false);
        return list[_lev];
    }
    
    
    public static function GetLevelById(_id : String) : Level
    {
        var index : Int = 0;
        for (l in list)
        {
            if (l.id == _id)
            {
                LoadLevel(index, false);
                return l;
            }
            index++;
        }
        return null;
    }
    
    public static function GetLevelIndexById(_id : String) : Int
    {
        var index : Int = 0;
        for (l in list)
        {
            if (l.id == _id)
            {
                return index;
            }
            index++;
        }
        return 0;
    }
    
    public static function GetLevelIndexByName(_name : String) : Int
    {
        var index : Int = 0;
        for (l in list)
        {
            if (l.name == _name)
            {
                return index;
            }
            index++;
        }
        return 0;
    }
    
    public static function GetHighestAvailableLevelIndex() : Int
    {
        var index : Int = 0;
        var i : Int = 0;
        for (l in list)
        {
            if (l.available)
            {
                index = i;
            }
            i++;
        }
        return index;
    }
    
    
    public static function GetLevelLight(_lev : Int) : Level
    {
        if (_lev < 0)
        {
            return null;
        }
        if (_lev >= list.length)
        {
            return null;
        }
        return list[_lev];
    }
    
    public static function CreateLevelObjInstanceAt(objName : String, _x : Float, _y : Float, _rotDeg : Float, _scale : Float, instanceName : String = "", params : String = "") : EdObj
    {
        var instance : EdObj = new EdObj();
        instance.typeName = objName;
        instance.x = _x;
        instance.y = _y;
        instance.rot = _rotDeg;
        instance.scale = _scale;
        instance.instanceName = instanceName;
        if (params != null)
        {
            instance.objParameters.CreateAllFromString(params);
        }
        return instance;
    }
    
    public static function IncrementLevel()
    {
        currentIndex++;
        if (currentIndex >= list.length)
        {
            currentIndex = 0;
        }
    }
    
    public static function DecrementLevel()
    {
        currentIndex--;
        if (currentIndex < 0)
        {
            currentIndex = as3hx.Compat.parseInt(list.length - 1);
        }
    }
    
    
    public static function ClearAll()
    {
        for (l in list)
        {
            l.locked = true;
            l.complete = false;
            l.available = false;
            l.bestScore = 0;
            l.percentage = 0;
            l.bestPercentage = 0;
            l.rating = 0;
            l.newlyAvailable = false;
            l.gotBonus = false;
            l.bestPlace = 99999;
            l.bestTime = 99999;
            l.endLightColor = 0;
            l.bestShots = 99999;
            
            if (Game.unlockEverything)
            {
                l.locked = false;
                l.available = true;
            }
        }
    }
    
    public static function ToSharedObject() : Dynamic
    {
        var o : Dynamic = {};
        var a : Array<Dynamic> = [];
        var b : Array<Dynamic> = [];
        var c : Array<Dynamic> = [];
        var d : Array<Dynamic> = [];
        var e : Array<Dynamic> = [];
        var f : Array<Dynamic> = [];
        var g : Array<Dynamic> = [];
        var h : Array<Dynamic> = [];
        var i : Array<Dynamic> = [];
        var j : Array<Dynamic> = [];
        for (l in list)
        {
            a.push(l.bestScore);
            b.push(l.available);
            c.push(l.complete);
            d.push(l.locked);
            e.push(l.bestPlace);
            f.push(l.bestTime);
            g.push(l.newlyAvailable);
            h.push(l.gotBonus);
            i.push(l.rating);
            j.push(l.bestShots);
        }
        o.a = a;
        o.b = b;
        o.c = c;
        o.d = d;
        o.e = e;
        o.f = f;
        o.g = g;
        o.h = h;
        o.i = i;
        o.j = j;
        return o;
    }
    
    public static function FromSharedObject(o : Dynamic)
    {
        if (o == null)
        {
            return;
        }
        
        var a : Array<Dynamic> = o.a;
        var b : Array<Dynamic> = o.b;
        var c : Array<Dynamic> = o.c;
        var d : Array<Dynamic> = o.d;
        var e : Array<Dynamic> = o.e;
        var f : Array<Dynamic> = o.f;
        var g : Array<Dynamic> = o.g;
        var h : Array<Dynamic> = o.h;
        var i : Array<Dynamic> = o.i;
        var j : Array<Dynamic> = o.j;
        var index : Int = 0;
        for (l in list)
        {
            l.bestScore = a[index];
            l.available = b[index];
            l.complete = c[index];
            l.locked = d[index];
            l.bestPlace = e[index];
            l.bestTime = f[index];
            l.newlyAvailable = g[index];
            l.gotBonus = h[index];
            l.rating = i[index];
            l.bestShots = j[index];
            index++;
        }
    }
}


