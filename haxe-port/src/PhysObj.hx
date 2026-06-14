import editorPackage.EdJoint;
import editorPackage.GameLayers;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.Shape;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author ...
	 */
class PhysObj
{
    public var bodies : Array<Dynamic>;
    public var joints : Array<Dynamic>;
    public var graphics : Array<Dynamic>;
    public var instanceParams : Array<Dynamic>;
    public var instanceParamsDefaults : Array<Dynamic>;
    
    
    public var name : String;
    public var displayInLibrary : Bool;
    public var editorRenderFunctionName : String;
    public var initFunctionName : String;
    public var initFunctionParameters : String;
    public var libraryClass : String;
    public var hasPhysics : Bool;
    public var snapToFloor : Bool;
    public var wakeFunctionName : String;
    
    
    private var sfx_break : String;
    private var sfx_hit : String;
    
    
    
    
    public function new()
    {
    }
    
    public function GetInstanceParamDefault(name : String) : String
    {
        for (i in 0...instanceParams.length)
        {
            if (instanceParams[i] == name)
            {
                return instanceParamsDefaults[i];
            }
        }
        return "";
    }
    
    public function GetInstanceParamsAsString() : String
    {
        var s : String = "";
        for (i in 0...instanceParams.length)
        {
            s += instanceParams[i];
            s += "=";
            s += instanceParamsDefaults[i];
            if (i != instanceParams.length - 1)
            {
                s += ",";
            }
        }
        return s;
    }
    
    private function GetGraphic(gx : FastXML) : PhysObjGraphic
    {
        var graphic : PhysObjGraphic = new PhysObjGraphic();
        graphic.goInitFuntion = gx.att.gameobjfunction;
        graphic.goInitFuntionVarString = gx.att.gameobjvars;
        graphic.graphicName = gx.att.clip;
        graphic.frame = XmlHelper.GetAttrInt(gx.att.frame) - 1;
        graphic.offset = cast((gx.att.pos), PointFromString);
        graphic.zoffset = 0;  // XmlHelper.GetAttrNumber(gx.@zoffset, 0);  
        graphic.hasShadow = XmlHelper.GetAttrBoolean(gx.att.shadow, true);
        
        graphic.rot = as3hx.Compat.parseFloat(gx.att.rot);
        graphic.Calculate();
        return graphic;
    }
    
    private function GetSfx(sx : FastXML)
    {
        sfx_break = "";
        sfx_hit = "";
        if (sx == null)
        {
            return;
        }
        
        sfx_break = XmlHelper.GetAttrString(sx.att.broken, "");
        sfx_hit = XmlHelper.GetAttrString(sx.att.hit, "");
    }
    
    
    private function GetGameSpecific(sx : FastXML)
    {
    }
    
    public function FromXml(x : FastXML) : Void
    {
        var i : Int;
        var j : Int;
        var k : Int;
        
        bodies = new Array<Dynamic>();
        joints = new Array<Dynamic>();
        graphics = new Array<Dynamic>();
        instanceParams = new Array<Dynamic>();
        instanceParamsDefaults = new Array<Dynamic>();
        
        var graphic : PhysObjGraphic;
        
        name = x.att.name;
        displayInLibrary = XmlHelper.GetAttrBoolean(x.att.inlibrary, false);
        initFunctionName = XmlHelper.GetAttrString(x.att.initfunction, null);
        editorRenderFunctionName = XmlHelper.GetAttrString(x.att.editorrender, null);
        initFunctionParameters = XmlHelper.GetAttrString(x.att.initparams, "");
        libraryClass = XmlHelper.GetAttrString(x.att.libclass, "");
        hasPhysics = XmlHelper.GetAttrBoolean(x.att.hasphysics, true);
        snapToFloor = XmlHelper.GetAttrBoolean(x.att.snaptofloor, false);
        wakeFunctionName = XmlHelper.GetAttrString(x.att.wakefunction, "");
        
        cast((x.nodes.sfx.get(0)), GetSfx);
        cast((x.nodes.zombooka.get(0)), GetGameSpecific);
        
        
        
        for (i in 0...x.nodes.parameter.length())
        {
            var px : FastXML = x.nodes.parameter.get(i);
            instanceParams.push(XmlHelper.GetAttrString(px.att.name, ""));
            instanceParamsDefaults.push(XmlHelper.GetAttrString(px.att.default, ""));
        }
        
        
        for (i in 0...x.nodes.graphic.length())
        {
            var gx : FastXML = x.nodes.graphic.get(j);
            graphics.push(cast((gx), GetGraphic));
        }
        
        
        for (i in 0...x.nodes.body.length())
        {
            var typename : String;
            var bx : FastXML = x.nodes.body.get(i);
            var body : PhysObjBody = new PhysObjBody();
            body.name = bx.att.name;
            body.fixed = cast((bx.att.fixed), BooleanFromString);
            
            body.sensor = cast((bx.att.sensor), BooleanFromString);
            body.pos = cast((bx.att.pos), PointFromString);
            
            body.linearDamping = 0;  // XmlHelper.GetAttrNumber(bx.@lineardamping, body.linearDamping);  
            body.angularDamping = 0;  // XmlHelper.GetAttrNumber(bx.@angulardamping, body.angularDamping);  
            
            for (j in 0...bx.nodes.graphic.length())
            {
                var gx : FastXML = bx.nodes.graphic.get(j);
                body.graphics.push(cast((gx), GetGraphic));
            }
            
            
            for (j in 0...bx.nodes.shape.length())
            {
                var sx : FastXML = bx.nodes.shape.get(j);
                var shape : PhysObjShape = new PhysObjShape();
                shape.name = sx.att.name;
                typename = sx.att.type;
                var colpt : Point = PointFromString(sx.att.col, "0,0");
                var sensorpt : Point = PointFromString(sx.att.sensor, "0,0");
                shape.collisionCategory = XmlHelper.GetAttrInt(colpt.x);
                shape.collisionMask = XmlHelper.GetAttrInt(colpt.y);
                shape.sensorCategory = XmlHelper.GetAttrInt(sensorpt.x);
                shape.sensorMask = XmlHelper.GetAttrInt(sensorpt.y);
                
                shape.materialName = XmlHelper.GetAttrString(sx.att.material, "");
                shape.density = XmlHelper.GetAttrNumber(sx.att.density);
                shape.friction = XmlHelper.GetAttrNumber(sx.att.friction);
                shape.restitution = XmlHelper.GetAttrNumber(sx.att.restitution);
                
                var gs : Float = 1;  // GameVars.globalScale;  
                
                if (typename == "circle")
                {
                    shape.type = PhysObjShape.Type_Circle;
                    shape.circle_pos = cast((sx.att.pos), PointFromString);
                    shape.circle_radius = XmlHelper.GetAttrNumber(sx.att.radius);
                    
                    if (true)
                    {
                        shape.circle_pos.x *= gs;
                        shape.circle_pos.y *= gs;
                        shape.circle_radius *= gs;
                    }
                }
                else if (typename == "poly")
                {
                    shape.type = PhysObjShape.Type_Poly;
                    shape.poly_points = cast((sx.att.vertices), PointArrayFromString);
                    
                    if (true)
                    {
                        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(shape),poly_points) type: null */ in shape.poly_points)
                        {
                            p.x *= gs;
                            p.y *= gs;
                        }
                    }
                    
                    shape.poly_rot = Utils.DegToRad(XmlHelper.GetAttrNumber(sx.att.rot));
                }
                shape.Caclulate();
                body.shapes.push(shape);
            }
            bodies.push(body);
        }
        
        instanceParams.push("editor_layer");
        instanceParamsDefaults.push("1");
        var addit : Bool = true;
        var i : Int = 0;
        for (s in instanceParams)
        {
            if (s == "game_layer")
            {
                addit = false;
            }
            i++;
        }
        
        if (addit)
        {
            instanceParams.push("game_layer");
            instanceParamsDefaults.push("Centre");
        }
        
        if (bodies[0] != null)
        {
            instanceParams.push("fixed");
            if (bodies[0].fixed)
            {
                instanceParamsDefaults.push("true");
            }
            else
            {
                instanceParamsDefaults.push("false");
            }
        }
        
        
        for (i in 0...x.nodes.joint.length())
        {
            var jx : FastXML = x.nodes.joint.get(i);
            var joint : EdJoint = new EdJoint();
            joint.name = jx.att.name;
            joint.obj0Name = jx.att.body0;
            joint.obj1Name = jx.att.body1;
            
            typename = jx.att.type;
            
            if (typename == "rev")
            {
                joint.type = EdJoint.Type_Rev;
                joint.rev_pos = cast((jx.att.pos), PointFromString);
                joint.rev_enableLimit = cast((jx.att.enablelimit), BooleanFromString);
                joint.rev_lowerAngle = Utils.DegToRad(XmlHelper.GetAttrNumber(jx.att.lowerangle));
                joint.rev_upperAngle = Utils.DegToRad(XmlHelper.GetAttrNumber(jx.att.upperangle));
                joint.rev_enableMotor = cast((jx.att.enablemotor), BooleanFromString);
                joint.rev_motorSpeed = as3hx.Compat.parseFloat(jx.att.motorspeed);
                joint.rev_maxMotorTorque = as3hx.Compat.parseFloat(jx.att.maxmotortorque);
            }
            else if (typename == "distance")
            {
                joint.type = EdJoint.Type_Distance;
                joint.dist_pos0 = cast((jx.att.pos), PointFromString);
                joint.dist_pos1 = cast((jx.att.pos1), PointFromString);
            }
            else if (typename == "mouse")
            {
                joint.type = EdJoint.Type_Mouse;
            }
            else if (typename == "prismatic")
            {
                joint.type = EdJoint.Type_Prismatic;
                joint.prism_pos = cast((jx.att.pos), PointFromString);
                joint.prism_enableLimit = cast((jx.att.enablelimit), BooleanFromString);
                joint.prism_lowerTranslation = as3hx.Compat.parseFloat(jx.att.lowertranslation);
                joint.prism_upperTranslation = as3hx.Compat.parseFloat(jx.att.uppertranslation);
                joint.prism_enableMotor = cast((jx.att.enablemotor), BooleanFromString);
                joint.prism_axisangle = as3hx.Compat.parseFloat(jx.att.axisangle) - 90;
                joint.prism_motorSpeed = as3hx.Compat.parseFloat(jx.att.motorspeed);
                joint.prism_maxMotorForce = as3hx.Compat.parseFloat(jx.att.maxmotorforce);
            }
            joints.push(joint);
        }
    }
    
    private function PointFromString(s : String, defaultValue : String = "0,0") : Point
    {
        if (s == null || s == "")
        {
            var a : Array<Dynamic> = defaultValue.split(",");
            return new Point(a[0], a[1]);
        }
        
        var a : Array<Dynamic> = s.split(",");
        
        var p : Point = new Point(0, 0);
        if (a.length != 2)
        {
            trace("PointfromString. Error, numpoints=" + a.length + "  " + s);
            return p;
        }
        
        p.x = as3hx.Compat.parseFloat(a[0]);
        p.y = as3hx.Compat.parseFloat(a[1]);
        return p;
    }
    
    private function PointArrayFromString(s : String) : Array<Dynamic>
    {
        var pointArray : Array<Dynamic> = new Array<Dynamic>();
        
        var a : Array<Dynamic> = s.split(",");
        
        if (a.length < 2 || (a.length % 2) == 1)
        {
            trace("PointArrayFromString. Error, numpoints=" + a.length + " , string= " + s);
            return pointArray;
        }
        
        var i : Int;
        var num : Int = as3hx.Compat.parseInt(a.length / 2);
        for (i in 0...num)
        {
            var p : Point = new Point(0, 0);
            p.x = as3hx.Compat.parseFloat(a[(i * 2) + 0]);
            p.y = as3hx.Compat.parseFloat(a[(i * 2) + 1]);
            pointArray.push(p);
        }
        
        return pointArray;
    }
    
    private function BooleanFromString(s : String) : Bool
    {
        var retval : Bool = false;
        
        s = s.toUpperCase();
        
        if (s == "1")
        {
            retval = true;
        }
        if (s == "TRUE")
        {
            retval = true;
        }
        return retval;
    }
    
    
    public function JointIndexFromName(name : String) : Int
    {
        for (i in 0...joints.length)
        {
            var j : EdJoint = joints[i];
            if (j.name == name)
            {
                return i;
            }
        }
        trace("ERROR PhysObj JointIndexFromName " + name);
        return 0;
    }
    public function BodyIndexFromName(name : String) : Int
    {
        for (i in 0...bodies.length)
        {
            var b : PhysObjBody = bodies[i];
            if (b.name == name)
            {
                return i;
            }
        }
        trace("ERROR PhysObj BodyIndexFromName " + name);
        return 0;
    }
    
    public function BodyFromName(name : String) : PhysObjBody
    {
        for (i in 0...bodies.length)
        {
            var b : PhysObjBody = bodies[i];
            if (b.name == name)
            {
                return b;
            }
        }
        trace("ERROR PhysObj BodyFromName " + name);
        return null;
    }
    
    private static var renderPoint : Point = new Point();
    private static var renderMatrix : Matrix = new Matrix();
    private static var p0 : Point = new Point();
    private static var p1 : Point = new Point();
    
    public static function RenderAt(physObj : PhysObj, x : Float, y : Float, _rotDeg : Float, _scale : Float, bd : BitmapData, g : Graphics = null, _collision : Bool = false, destRect : Rectangle = null, maxDestRect : Rectangle = null, colorTransform : ColorTransform = null)
    {
        var renderCollision : Bool = _collision;
        var scale : Float = _scale;
        var xp : Float;
        var yp : Float;
        
        var a : Matrix;
        xp = x;
        yp = y;
        
        var body : PhysObjBody;
        var graphic : PhysObjGraphic;
        var graphics : Array<Dynamic> = new Array<Dynamic>();
        
        for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(physObj),bodies) type: null */ in physObj.bodies)
        {
            for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(body),graphics) type: null */ in body.graphics)
            {
                var o : Dynamic = {};
                o.graphic = graphic;
                o.x = body.pos.x;
                o.y = body.pos.y;
                graphics.push(o);
            }
        }
        for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(physObj),graphics) type: null */ in physObj.graphics)
        {
            var o : Dynamic = {};
            o.graphic = graphic;
            o.x = 0;
            o.y = 0;
            graphics.push(o);
        }
        
        
        
        for (o in graphics)
        {
            graphic = o.graphic;
            var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(graphic.graphicName);
            if (dobj != null)
            {
                var gr_x : Float = o.x;
                var gr_y : Float = o.y;
                
                if (dobj.GetBitmapData(graphic.frame) != null)
                {
                    if (destRect != null)
                    {
                        var w : Float = dobj.GetWidth(graphic.frame);
                        var h : Float = dobj.GetHeight(graphic.frame);
                        var scaleW : Float = destRect.width / w;
                        var scaleH : Float = destRect.height / h;
                        var scl : Float = scaleW;
                        if (scaleH < scaleW)
                        {
                            scl = scaleH;
                        }
                        xp -= (destRect.width / 2);
                        yp -= (destRect.height / 2);
                        
                        xp += gr_x;
                        yp += gr_y;
                        
                        var bitmapData : BitmapData = dobj.GetBitmapData(graphic.frame);
                        
                        renderMatrix.identity();
                        renderMatrix.scale(scl, scl);
                        renderMatrix.translate(xp, yp);
                        
                        if (bitmapData != null)
                        {
                            bd.draw(bitmapData, renderMatrix, colorTransform, null, null, true);
                        }
                    }
                    else if (maxDestRect != null)
                    {
                        var w : Float = dobj.GetWidth(graphic.frame);
                        var h : Float = dobj.GetHeight(graphic.frame);
                        
                        var scaleW : Float = maxDestRect.width / w;
                        var scaleH : Float = maxDestRect.height / h;
                        var scl : Float = scaleW;
                        if (scaleH < scaleW)
                        {
                            scl = scaleH;
                        }
                        
                        if (scl > 1)
                        {
                            scl = 1;
                        }
                        
                        xp -= ((w * scl) / 2);
                        yp -= ((h * scl) / 2);
                        
                        xp += gr_x;
                        yp += gr_y;
                        
                        var bitmapData : BitmapData = dobj.GetBitmapData(graphic.frame);
                        
                        renderMatrix.identity();
                        renderMatrix.scale(scl, scl);
                        renderMatrix.translate(xp, yp);
                        
                        if (bitmapData != null)
                        {
                            bd.draw(bitmapData, renderMatrix, colorTransform, null, null, true);
                        }
                    }
                    else
                    {
                        var rot : Float = Utils.DegToRad(_rotDeg + graphic.rot);
                        
                        renderPoint.x = graphic.offset.x;
                        renderPoint.y = graphic.offset.y;
                        
                        if (scale != 1 || rot != 0 || colorTransform != null)
                        {
                            renderPoint.x += gr_x;
                            renderPoint.y += gr_y;
                            
                            renderMatrix.identity();
                            renderMatrix.rotate(Utils.DegToRad(_rotDeg));
                            renderPoint = renderMatrix.transformPoint(renderPoint);
                            
                            xp = (x) + renderPoint.x;
                            yp = (y) + renderPoint.y;
                            
                            GraphicObjects.GetDisplayObjByName(graphic.graphicName).RenderAtRotScaled(graphic.frame, bd, xp, yp, scale, rot, colorTransform);
                        }
                        else
                        {
                            renderPoint.x += gr_x;
                            renderPoint.y += gr_y;
                            xp = (x) + renderPoint.x;
                            yp = (y) + renderPoint.y;
                            GraphicObjects.GetDisplayObjByName(graphic.graphicName).RenderAt(graphic.frame, bd, xp, yp);
                        }
                    }
                }
            }
        }
        if (dobj != null)
        {
            for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(physObj),bodies) type: null */ in physObj.bodies)
            {
                if (renderCollision)
                {
                    if (g != null)
                    {
                        renderMatrix.identity();
                        var rot : Float = Utils.DegToRad(_rotDeg);
                        if (rot != 0)
                        {
                            renderMatrix.rotate(rot);
                        }
                        if (scale != 1)
                        {
                            renderMatrix.scale(scale, scale);
                        }
                        
                        var scl : Float = 1;
                        var xoff : Float = 0;
                        var yoff : Float = 0;
                        if (maxDestRect != null)
                        {
                            var w : Float = dobj.GetWidth(graphic.frame);
                            var h : Float = dobj.GetHeight(graphic.frame);
                            
                            var scaleW : Float = maxDestRect.width / w;
                            var scaleH : Float = maxDestRect.height / h;
                            var scl : Float = scaleW;
                            if (scaleH < scaleW)
                            {
                                scl = scaleH;
                            }
                            
                            if (scl > 1)
                            {
                                scl = 1;
                            }
                        }
                        
                        
                        var i : Int;
                        var j : Int;
                        for (shape/* AS3HX WARNING could not determine type for var: shape exp: EField(EIdent(body),shapes) type: null */ in body.shapes)
                        {
                            if (shape.type == PhysObjShape.Type_Circle)
                            {
                                var r : Float = shape.circle_radius * scl;
                                RenderCircle(g, x + shape.circle_pos.x + body.pos.x, y + shape.circle_pos.y + body.pos.y, r, 0xffffffff, 2);
                            }
                            if (shape.type == PhysObjShape.Type_Poly)
                            {
                                var verts : Array<Dynamic> = shape.poly_points;
                                var numVerts : Int = shape.poly_points.length;
                                
                                for (i in 0...numVerts)
                                {
                                    var j : Int = as3hx.Compat.parseInt(i + 1);
                                    if (j >= numVerts)
                                    {
                                        j = 0;
                                    }
                                    
                                    p0.x = verts[i].x;
                                    p0.y = verts[i].y;
                                    p1.x = verts[j].x;
                                    p1.y = verts[j].y;
                                    
                                    
                                    p0 = renderMatrix.transformPoint(p0);
                                    p1 = renderMatrix.transformPoint(p1);
                                    
                                    p0.x *= scl;
                                    p0.y *= scl;
                                    p1.x *= scl;
                                    p1.y *= scl;
                                    
                                    p0.x += x;
                                    p1.x += x;
                                    p0.y += y;
                                    p1.y += y;
                                    
                                    p0.x += xoff;
                                    p0.y += yoff;
                                    p1.x += xoff;
                                    p1.y += yoff;
                                    
                                    
                                    RenderLine(g, p0.x, p0.y, p1.x, p1.y, 0xffffffff, 2, 0.5);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private static function RenderCircle(g : Graphics, x : Float, y : Float, radius : Float, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        g.lineStyle(thickness, col, alpha);
        g.drawCircle(x, y, radius);
    }
    private static function RenderLine(g : Graphics, x0 : Float, y0 : Float, x1 : Float, y1 : Float, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        g.lineStyle(thickness, col, alpha);
        g.moveTo(x0, y0);
        g.lineTo(x1, y1);
    }
    private static function RenderRectangle(g : Graphics, r : Rectangle, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        RenderLine(g, r.left, r.top, r.right, r.top, col, thickness, alpha);
        RenderLine(g, r.left, r.bottom, r.right, r.bottom, col, thickness, alpha);
        RenderLine(g, r.left, r.top, r.left, r.bottom, col, thickness, alpha);
        RenderLine(g, r.right, r.top, r.right, r.bottom, col, thickness, alpha);
    }
    
    
    public static function RenderOutline(physObj : PhysObj, x : Float, y : Float, _rotDeg : Float, g : Graphics)
    {
        var graphic : PhysObjGraphic;
        var graphics : Array<Dynamic> = new Array<Dynamic>();
        var body : PhysObjBody;
        for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(physObj),bodies) type: null */ in physObj.bodies)
        {
            for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(body),graphics) type: null */ in body.graphics)
            {
                graphics.push(graphic);
            }
        }
        for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(physObj),graphics) type: null */ in physObj.graphics)
        {
            graphics.push(graphic);
        }
        
        
        
        for (graphic in graphics)
        {
            var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(graphic.graphicName);
            var w : Float = dobj.GetWidth(graphic.frame);
            var h : Float = dobj.GetHeight(graphic.frame);
            var r : Rectangle = new Rectangle(x + graphic.offset.x, y + graphic.offset.y, w, h);
            RenderRectangle(g, r, 0xff6080, 2);
        }
    }
}

