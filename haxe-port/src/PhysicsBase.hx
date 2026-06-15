import flash.errors.Error;
import editorPackage.EdJoint;
import editorPackage.EdLine;
import editorPackage.EdObj;
import editorPackage.GameLayers;
import editorPackage.ObjParameters;
import editorPackage.PolyMaterial;
import editorPackage.PolyMaterials;
import flash.geom.Matrix;
import flash.geom.Point;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.constraint.AngleJoint;
import nape.constraint.Constraint;
import nape.constraint.DistanceJoint;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionFilter;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.geom.*;
import nape.phys.*;
import nape.space.*;
import nape.util.*;

/**
	 * ...
	 * @author LongAnimals
	 */
class PhysicsBase
{
    public static var useNape : Bool = true;
    
    
    public static var nape_space0 : Space;
    public static var nape_space1 : Space;
    public static var nape_space2 : Space;
    public static var nape_debug : Dynamic;
    public static var nape_cbtype_default : CbType;
    public static var nape_timeStep : Float = 1 / 60;
    public static var nape_velIterations : Float = 10;
    public static var nape_posIterations : Float = 10;
    public static var nape_numSteps : Int = 1;
    public static var nape_Gravity : Float = 300;
    public static var nape_oneOverTimeStep : Float = 1 / nape_timeStep;
    
    public static var current_space : Space;
    
    public static function SetCurrentSpace(index : Int)
    {
        if (index == 0)
        {
            current_space = nape_space0;
        }
        if (index == 1)
        {
            current_space = nape_space1;
        }
    }
    public static function GetNapeSpace() : Space
    {
        return current_space;
    }
    
    
    public static var interactionListener : InteractionListener;
    public static var interactionListener1 : InteractionListener;
    public static var interactionListener2 : InteractionListener;
    public static var interactionListener3 : InteractionListener;
    
    public static function AddListenersA() : Void
    {
    }
    public static function RemoveListenersA() : Void
    {
    }
    
    
    public static function AddListeners() : Void
    {
    }
    public static function RemoveListeners() : Void
    {
    }
    
    
    public static function SetGravity(g : Float) : Void
    {
        var v : Vec2 = new Vec2(0, g);
        nape_space0.gravity = v;
        nape_space1.gravity = v;
        nape_space2.gravity = v;
        nape_Gravity = g;
    }
    public static function InitNape() : Void
    {
        
        nape_space0 = new Space(new Vec2(0, nape_Gravity), null);
        nape_space1 = new Space(new Vec2(0, nape_Gravity), null);
        nape_space2 = new Space(new Vec2(0, nape_Gravity), null);
        
        current_space = nape_space0;
        
        
        
        nape_cbtype_default = new CbType();
        
        interactionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, nape_cbtype_default, nape_cbtype_default, NapeContacts.BeginCollide);
        interactionListener1 = new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION, nape_cbtype_default, nape_cbtype_default, NapeContacts.OngoingCollide);
        interactionListener2 = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, nape_cbtype_default, nape_cbtype_default, NapeContacts.BeginSensor);
        interactionListener3 = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, nape_cbtype_default, nape_cbtype_default, NapeContacts.OngoingSensor);
        
        
        nape_space0.listeners.add(interactionListener);
        nape_space0.listeners.add(interactionListener1);
        nape_space0.listeners.add(interactionListener2);
        nape_space0.listeners.add(interactionListener3);
        
        
        InitObjectParameters();
    }
    
    public static function TimeStep()
    {
        GetNapeSpace().step(nape_timeStep, 10, 10);
    }
    
    public static function InitObjectParameters()
    {
        ObjectParameters.AddParamBool("fixed", true);
        
        ObjectParameters.AddParamBool("collide_joined", false);
        
        ObjectParameters.AddParamBool("dist_soft", false);
        ObjectParameters.AddParamNumber("dist_soft_frequency", 0.5, true, false, 0, 0, 0.1);
        ObjectParameters.AddParamNumber("dist_limit", 0, false, false, 0, 0, 50);
        
        ObjectParameters.AddParamBool("weld_soft", false);
        ObjectParameters.AddParamNumber("weld_soft_frequency", 0.5, true, false, 0, 0, 0.1);
        
        ObjectParameters.AddParamBool("rev_soft", false);
        ObjectParameters.AddParamNumber("rev_soft_frequency", 0.5, true, false, 0, 0, 0.1);
        ObjectParameters.AddParamBool("rev_enablelimit", false);
        ObjectParameters.AddParamAngle("rev_lowerangle", 0);
        ObjectParameters.AddParamAngle("rev_upperangle", 0);
        ObjectParameters.AddParamBool("rev_enablemotor", false);
        ObjectParameters.AddParamNumber("rev_motorrate", 10, false, false, 0, 0, 1);
        ObjectParameters.AddParamNumber("rev_motorratio", 1, false, false, 0, 0, 1);
        ObjectParameters.AddParamNumber("rev_motormax", 10000, false, false, 0, 0, 1);
        
        ObjectParameters.AddParam("joint_initfunction", "list", "InitGameObjJoint_Null", "InitGameObjJoint_Null,InitGameObjJoint_Trapeze,InitGameObjJoint_Trapeze1,InitGameObjJoint_LoweringDistance,InitGameObjJoint_RaisingDistance,InitGameObjJoint_SwitchedDistance,InitJoint_RotateSwitch,InitJoint_RotateSwitch_StopGo,InitJoint_Render");
    }
    
    public static function Init() : Void
    {
        InitNape();
    }
    
    public function new()
    {
    }
    
    
    
    public static function InitLines(addGameObjectsPerPoly : Bool = true)
    {
        var b : Body;
        
        var p : Point;
        var p0 : Point;
        var p1 : Point;
        var p2 : Point;
        var p3 : Point;
        var i : Int;
        
        var ud : PhysObjBodyUserData = new PhysObjBodyUserData();
        ud.bodyName = "wall";
        
        
        var height : Float = 50;
        var l : Level = Levels.GetCurrent();
        
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.type == 0)
            {
                var points : Array<Dynamic> = line.points;
                var linetype : Int = line.type;
                
                if (line.IsSpline())
                {
                    points = line.GetCatmullRomPointsList(points, 0, 0);
                }
                
                var polyMaterial : PolyMaterial = PolyMaterials.GetByName(line.objParameters.GetValueString("line_material"));
                var physMaterial : PhysObjMaterial = Game.GetPhysMaterialByName(polyMaterial.materialName);
                var interactionFilter : InteractionFilter = new InteractionFilter(polyMaterial.collisionCategory, polyMaterial.collisionMask, polyMaterial.sensorCategory, polyMaterial.sensorMask);
                
                var sensorEnabled : Bool = false;
                if (polyMaterial.sensorCategory != 0)
                {
                    sensorEnabled = true;
                }
                
                if (addGameObjectsPerPoly == false && polyMaterial.fixed == false)
                {
                    var aaa : Int = 0;
                }
                else if (polyMaterial.initType == "path")
                {
                }
                else if (polyMaterial.initType == "nophysics")
                {
                    var centrePoint : Point = line.CalculateCentre();
                    var go : GameObj = GameObjects.AddObj(0, 0, 0);
                    go.InitPhysicsLineObject(line);
                }
                else if (polyMaterial.initType == "poly")
                {
                    if (points.length >= 3)
                    {
                        var cx : Float = 0;
                        var cy : Float = 0;
                        var nape_points : Array<Dynamic> = [];
                        for (pt in points)
                        {
                            nape_points.push(new Vec2(pt.x, pt.y));
                            cx += pt.x;
                            cy += pt.y;
                        }
                        cx /= points.length;
                        cy /= points.length;
                        
                        for (v in nape_points)
                        {
                            v.x -= cx;
                            v.y -= cy;
                        }
                        
                        
                        var gp : GeomPoly = new GeomPoly(nape_points);
                        var gpl : GeomPolyList = gp.triangularDecomposition();
                        b = new Body(BodyType.STATIC, new Vec2(cx, cy));
                        
                        for (gpindex in 0...gpl.length)
                        {
                            var gp : GeomPoly = gpl.at(gpindex);
                            var poly : Polygon = new Polygon(gp, physMaterial.MakeNapeMaterial(), interactionFilter);
                            
                            poly.userData.data = {};
                            poly.userData.data.name = physMaterial.name;
                            
                            poly.sensorEnabled = sensorEnabled;
                            
                            b.shapes.add(poly);
                        }
                        
                        if (polyMaterial.fixed)
                        {
                        }
                        else
                        {
                            b.type = BodyType.DYNAMIC;
                        }
                        
                        line.centrex = cx;
                        line.centrey = cy;
                        
                        var thisud : PhysObjBodyUserData = ud.Clone();
                        
                        if (addGameObjectsPerPoly)
                        {
                            var go : GameObj = GameObjects.AddObj(cx, cy, 0);
                            go.InitPhysicsLineObject_Nape(line, b);
                            thisud.gameObjectIndex = go.listIndex;
                            b.userData.data = thisud;
                        }
                        else
                        {
                            b.userData.data = physMaterial.Clone();
                        }
                        
                        
                        b.cbTypes.add(PhysicsBase.nape_cbtype_default);
                        GetNapeSpace().bodies.add(b);
                    }
                }
            }
        }
    }
    
    
    
    public static function AddPhysObjAt(objName : String, _x : Float, _y : Float, _rotDeg : Float, scale : Float, instanceName : String = "", initParams : String = "", _id : String = "", independantGO : Bool = false) : GameObj
    {
        var go : GameObj;
        
        if (independantGO == false)
        {
            go = GameObjects.AddObj(_x, _y, 0);
        }
        else
        {
            go = new GameObj();
            go.isIndependant = true;
        }
        
        
        
        var physobj : PhysObj = Game.objectDefs.FindByName(objName);
        if (physobj == null)
        {
            Utils.traceerror("error in AddPhysObjAt() - can't find object " + objName);
            return null;
        }
        
        var rot : Float = Utils.DegToRad(_rotDeg);
        
        go.nape_bodies = [];
        go.nape_joints = [];
        go.initParams = initParams;
        go.id = _id;
        
        go.physobj = physobj;
        
        go.InitKeepAwakeFunction();
        
        go.initFunctionVarString = physobj.initFunctionParameters;
        
        Utils.GetParams(initParams);
        var layerZpos : Float = GameLayers.GetZPosByName(Utils.GetParamString("game_layer"));
        go.zpos = layerZpos;
        
        var isFixed : Bool = Utils.GetParamBool("fixed");
        
        go.dir = Utils.DegToRad(_rotDeg);
        go.scale = scale;
        
        
        go.colFlag_isPhysObj = true;
        go.isPhysObj = true;
        go.physObjOffsetX = 0;
        go.physObjOffsetY = 0;
        
        
        
        var jointxoff : Float;
        var jointyoff : Float;
        
        var i : Int;
        
        var b : Body;
        
        var m : Matrix = new Matrix();
        m.rotate(rot);
        m.scale(scale, scale);
        
        
        if (physobj.bodies.length > 1)
        {
            Utils.traceerror("EEEEEEEEERRRRRRRROOOOOOOOOORRRRR physobj.bodies.length= " + physobj.bodies.length);
        }
        
        for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(physobj),bodies) type: null */ in physobj.bodies)
        {
            var bodyxoff : Float = body.pos.x;
            var bodyyoff : Float = body.pos.y;
            
            
            var p : Point = new Point(bodyxoff, bodyyoff);
            p = m.transformPoint(p);
            bodyxoff = p.x;
            bodyyoff = p.y;
            
            b = new Body();
            b.position.setxy(_x + bodyxoff, _y + bodyyoff);
            b.rotation = rot;
            
            
            
            var bud : PhysObjBodyUserData = new PhysObjBodyUserData();
            bud.type = objName;
            bud.bodyName = body.name;
            bud.gameObjectIndex = go.listIndex;
            if (go.isIndependant == true)
            {
                bud.gameObjectIndex = -1;
                bud.independantGO = go;
            }
            
            b.userData.data = bud;
            if (body.graphics.length != 0)
            {
                var graphic : PhysObjGraphic = body.graphics[0];
                
                go.dobj = GraphicObjects.GetDisplayObjByName(graphic.graphicName);
                go.frame = graphic.frame;
            }
            
            
            
            for (shape/* AS3HX WARNING could not determine type for var: shape exp: EField(EIdent(body),shapes) type: null */ in (body.shapes : Array<Dynamic>))
            {
                var physMaterial : PhysObjMaterial = Game.GetPhysMaterialByName(shape.materialName);
                
                if (shape.type == PhysObjShape.Type_Poly)
                {
                    var triangulatePoly : Bool = true;
                    if (triangulatePoly == false)
                    {
                        var interactionFilter : InteractionFilter = new InteractionFilter(shape.collisionCategory, shape.collisionMask, shape.sensorCategory, shape.sensorMask);
                        
                        var sensorEnabled : Bool = false;
                        if (shape.sensorCategory != 0)
                        {
                            sensorEnabled = true;
                        }
                        
                        var points : Array<Dynamic> = shape.poly_points;
                        
                        var localVerts : Array<Dynamic> = [];
                        for (pt in points)
                        {
                            localVerts.push(Vec2.fromPoint(pt));
                        }
                        
                        var gp : GeomPoly = new GeomPoly(localVerts);
                        if (gp.isConvex() == true)
                        {
                            var aaaa : Int = 0;
                        }
                        
                        var poly : Polygon = new Polygon(localVerts, physMaterial.MakeNapeMaterial(), interactionFilter);
                        
                        poly.userData.data = {};
                        poly.userData.data.name = physMaterial.name;
                        
                        poly.sensorEnabled = sensorEnabled;
                        b.shapes.add(poly);
                    }
                    else
                    {
                        var points : Array<Dynamic> = shape.poly_points;
                        if (points.length >= 3)
                        {
                            var triangulate : Triangulate = new Triangulate();
                            var triangulatedVerts : Array<Dynamic> = triangulate.process(points);
                            
                            if (triangulatedVerts == null)
                            {
                                Utils.traceerror("object failed triangulating: " + points.length);
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
                                
                                
                                var interactionFilter : InteractionFilter = new InteractionFilter(shape.collisionCategory, shape.collisionMask, shape.sensorCategory, shape.sensorMask);
                                
                                var sensorEnabled : Bool = false;
                                if (shape.sensorCategory != 0)
                                {
                                    sensorEnabled = true;
                                }
                                
                                var poly : Polygon = new Polygon([Vec2.fromPoint(p0), Vec2.fromPoint(p1), Vec2.fromPoint(p2)], physMaterial.MakeNapeMaterial(), interactionFilter);
                                poly.userData.data = {};
                                poly.userData.data.name = physMaterial.name;
                                
                                poly.sensorEnabled = sensorEnabled;
                                b.shapes.add(poly);
                            }
                        }
                    }
                }
                else if (shape.type == PhysObjShape.Type_Circle)
                {
                    var circle_pos : Vec2 = new Vec2(shape.circle_pos.x * scale, shape.circle_pos.y * scale);
                    var nape_circle : Circle = new Circle(shape.circle_radius, circle_pos);
                    
                    
                    nape_circle.material = physMaterial.MakeNapeMaterial();
                    var interactionFilter : InteractionFilter = new InteractionFilter(shape.collisionCategory, shape.collisionMask, shape.sensorCategory, shape.sensorMask);
                    
                    var sensorEnabled : Bool = false;
                    if (shape.sensorCategory != 0)
                    {
                        sensorEnabled = true;
                    }
                    
                    nape_circle.filter = interactionFilter;
                    
                    nape_circle.sensorEnabled = sensorEnabled;
                    b.shapes.add(nape_circle);
                }
            }
            
            if (isFixed)
            {
                b.type = BodyType.STATIC;
            }
            else
            {
                b.type = BodyType.DYNAMIC;
            }
            b.angularVel = 0;
            b.velocity.setxy(0, 0);
            
            b.cbTypes.add(PhysicsBase.nape_cbtype_default);
            GetNapeSpace().bodies.add(b);
            go.nape_bodies.push(b);
        }
        
        try
        {
            GameObjects.UpdateSingleGOsFromPhysics(go);
            if (physobj.initFunctionName != "")
            {
                Reflect.callMethod(go, Reflect.field(go, physobj.initFunctionName), []);
            }
        }
        catch (err : Error)
        {
            Utils.traceerror("init function doesn't exist: " + physobj.initFunctionName);
        }
        
        
        return go;
    }
    
    public static function InitJoints()
    {
        var l : Level = Levels.GetCurrent();
        var jointList : Array<Dynamic> = Levels.GetCurrentLevelJoints();
        for (joint in jointList)
        {
            AddJoint_Nape(joint);
        }
    }
    
    public static function AddJoint_Nape(joint : EdJoint) : Array<Constraint>
    {
        var jb0 : Body = null; var jb1 : Body = null;
        var go0 : GameObj = null; var go0a : GameObj = null; var go1 : GameObj = null; var go1a : GameObj = null;
        var p : Point;
        var p1 : Point;
        var joinedBodiesCollide : Bool = joint.objParameters.GetValueBoolean("collide_joined");
        var joinedBodiesIgnoreCollision : Bool = (joinedBodiesCollide == false);
        
        var cons : Array<Constraint> = [];
        
        if (joint.type == EdJoint.Type_LogicLink)
        {
            go0 = GameObjects.GetGameObjById(joint.obj0Name);
            go1 = GameObjects.GetGameObjById(joint.obj1Name);
            go0.logicLink0 = null;
            go0.logicLink1 = go1;
            go1.logicLink0 = go0;
            go1.logicLink1 = null;
        }
        else if (joint.type != EdJoint.Type_Switch)
        {
            jb0 = PhysicsBase.GetNapeSpace().world;
            jb1 = PhysicsBase.GetNapeSpace().world;
            if (joint.obj0Name == "")
            {
            }
            else
            {
                go0 = GameObjects.GetGameObjById(joint.obj0Name);
                go0a = GameObjects.GetGameObjByLineName(joint.obj0Name);
                if (go0 != null)
                {
                    if (go0.nape_bodies == null)
                    {
                        Utils.traceerror("ERROR: jb0 joint.obj0Name " + joint.obj0Name);
                    }
                    jb0 = go0.nape_bodies[0];
                }
                else if (go0a != null)
                {
                    if (go0a.nape_bodies == null)
                    {
                        Utils.traceerror("ERROR: jb0a joint.obj0Name " + joint.obj0Name);
                    }
                    jb0 = go0a.nape_bodies[0];
                }
                else
                {
                    Utils.traceerror("jb0 gameobject not found " + joint.obj0Name);
                }
            }
            if (joint.obj1Name == "")
            {
            }
            else
            {
                go1 = GameObjects.GetGameObjById(joint.obj1Name);
                go1a = GameObjects.GetGameObjByLineName(joint.obj1Name);
                if (go1 != null)
                {
                    jb1 = go1.nape_bodies[0];
                }
                else if (go1a != null)
                {
                    jb1 = go1a.nape_bodies[0];
                }
                else
                {
                    Utils.traceerror("jb1 gameobject not found " + joint.obj1Name);
                }
            }
        }
        
        
        if (joint.type == EdJoint.Type_Rev)
        {
            p = new Point(joint.rev_pos.x, joint.rev_pos.y);
            
            var v0 : Vec2 = Vec2.fromPoint(p);
            
            
            
            var pivotjoint : PivotJoint = new PivotJoint(jb0, jb1, jb0.worldPointToLocal(v0), jb1.worldPointToLocal(v0));
            pivotjoint.ignore = joinedBodiesIgnoreCollision;
            
            PhysicsBase.GetNapeSpace().constraints.add(pivotjoint);
            cons.push(pivotjoint);
            
            
            
            var soft : Bool = joint.objParameters.GetValueBoolean("rev_soft");
            if (soft)
            {
                var frequency : Float = joint.objParameters.GetValueNumber("rev_soft_frequency");
                pivotjoint.stiff = false;
                pivotjoint.frequency = frequency;
            }
            
            var enableMotor : Bool = joint.objParameters.GetValueBoolean("rev_enablemotor");
            if (enableMotor)
            {
                var motorRate : Float = joint.objParameters.GetValueNumber("rev_motorrate");
                var motorRatio : Float = joint.objParameters.GetValueNumber("rev_motorratio");
                var motorMax : Float = joint.objParameters.GetValueNumber("rev_motormax");
                var motorJoint : MotorJoint = new MotorJoint(jb0, jb1, motorRate, motorRatio);
                motorJoint.ignore = joinedBodiesIgnoreCollision;
                
                motorJoint.maxForce = motorMax;
                
                GetNapeSpace().constraints.add(motorJoint);
                cons.push(motorJoint);
            }
            
            var enableLimit : Bool = joint.objParameters.GetValueBoolean("rev_enablelimit");
            if (enableLimit)
            {
                var minAngle : Float = Utils.DegToRad(joint.objParameters.GetValueNumber("rev_lowerangle"));
                var maxAngle : Float = Utils.DegToRad(joint.objParameters.GetValueNumber("rev_upperangle"));
                
                var angleJoint : AngleJoint = new AngleJoint(jb0, jb1, minAngle, maxAngle);
                angleJoint.ignore = joinedBodiesIgnoreCollision;
                GetNapeSpace().constraints.add(angleJoint);
                cons.push(angleJoint);
            }
        }
        if (joint.type == EdJoint.Type_Weld)
        {
            var phase : Float = jb1.rotation - jb0.rotation;
            
            
            
            
            
            
            var v0 : Vec2 = new Vec2(jb1.position.x - jb0.position.y, jb1.position.y - jb0.position.y);
            
            var m : Matrix = new Matrix();
            var p : Point = new Point();
            
            m.identity();
            m.rotate(jb0.rotation);
            p.x = v0.x;
            p.y = v0.y;
            p = m.transformPoint(p);
            
            
            
            
            if (jb0.type != BodyType.DYNAMIC && jb1.type != BodyType.DYNAMIC)
            {
                Utils.traceerror("ERRROOORR Weld joints cannot have both bodies non-dynamic");
                Utils.traceerror("Weld joint not being created");
            }
            else
            {
                var weldJoint : WeldJoint = new WeldJoint(jb0, jb1, jb0.worldPointToLocal(v0), jb1.worldPointToLocal(v0), phase);
                weldJoint.ignore = joinedBodiesIgnoreCollision;
                var soft : Bool = joint.objParameters.GetValueBoolean("weld_soft");
                if (soft)
                {
                    var frequency : Float = joint.objParameters.GetValueNumber("weld_soft_frequency");
                    weldJoint.stiff = false;
                    weldJoint.frequency = frequency;
                }
                
                GetNapeSpace().constraints.add(weldJoint);
                cons.push(weldJoint);
            }
        }
        
        if (joint.type == EdJoint.Type_Distance)
        {
            var v0 : Vec2 = new Vec2(joint.dist_pos0.x, joint.dist_pos0.y);
            var v1 : Vec2 = new Vec2(joint.dist_pos1.x, joint.dist_pos1.y);
            
            var m : Matrix = new Matrix();
            var p : Point = new Point();
            var p1 : Point = new Point();
            
            m.identity();
            m.rotate(jb0.rotation);
            p.x = v0.x;
            p.y = v0.y;
            p = m.transformPoint(p);
            
            m.identity();
            m.rotate(jb1.rotation);
            p1.x = v1.x;
            p1.y = v1.y;
            p1 = m.transformPoint(p1);
            
            var dist : Float = Utils.DistBetweenPoints(joint.dist_pos0.x, joint.dist_pos0.y, joint.dist_pos1.x, joint.dist_pos1.y);
            
            var dist_limit : Float = joint.objParameters.GetValueNumber("dist_limit");
            
            var distJoint = new DistanceJoint(jb0, jb1, jb0.worldPointToLocal(v0), jb1.worldPointToLocal(v1), dist - dist_limit, dist + dist_limit);
            distJoint.ignore = joinedBodiesIgnoreCollision;
            
            var soft : Bool = joint.objParameters.GetValueBoolean("dist_soft");
            if (soft)
            {
                var frequency : Float = joint.objParameters.GetValueNumber("dist_soft_frequency");
                distJoint.stiff = false;
                distJoint.frequency = frequency;
            }
            
            GetNapeSpace().constraints.add(distJoint);
            cons.push(distJoint);
        }
        
        
        
        AddConstraintsToGameObj(go0, cons);
        AddConstraintsToGameObj(go0a, cons);
        AddConstraintsToGameObj(go1, cons);
        AddConstraintsToGameObj(go1a, cons);
        
        
        var jointGO : GameObj = null;
        var jointGOControlIndex : Int = -1;
        var gameObjInitName : String = joint.objParameters.GetValueString("joint_initfunction");
        if (gameObjInitName != null)
        {
            if (gameObjInitName != "" && gameObjInitName != "InitGameObjJoint_Null")
            {
                jointGO = GameObjects.AddObj(0, 0, 0);
                jointGO.id = joint.id;
                Reflect.field(jointGO, gameObjInitName)(cons);
                jointGOControlIndex = jointGO.controlIndex;
            }
        }
        
        
        return cons;
    }
    
    public static function AddConstraintsToGameObj(go : GameObj, cons : Array<Constraint>)
    {
        if (go == null)
        {
            return;
        }
        if (go.nape_joints == null)
        {
            go.nape_joints = [];
        }
        for (con in cons)
        {
            go.nape_joints.push(con);
        }
    }
}


