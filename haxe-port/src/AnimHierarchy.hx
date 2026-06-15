import haxe.Constraints.Function;
import flash.display.BitmapData;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;

/**
	 * ...
	 * @author
	 */
class AnimHierarchy
{
    public var dobj : DisplayObj;
    public var frames : Array<AnimHierarchyFrame> = null;
    
    public function new()
    {
    }
    
    public static var m : Matrix = new Matrix();
    public static var p : Point = new Point(0, 0);
    public static var p1 : Point = new Point(0, 0);
    
    
    public function CreateSeparates(x : Float, y : Float, frame : Float, scale : Float, rot : Float, xflip : Bool = false) : Array<Dynamic>
    {
        var goList : Array<Dynamic> = [];
        if (frames == null)
        {
            return goList;
        }
        var f : AnimHierarchyFrame = frames[as3hx.Compat.parseInt(frame)];
        
        for (pcount in 0...f.parts.length)
        {
            var part : AnimHierarchyFramePart = f.parts[pcount];
            if (part.visible)
            {
                var part_dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(part.dobjName);
                
                p.x = (part.x * scale);
                p.y = (part.y * scale);
                
                
                
                
                
                
                var xpos : Float = x + p.x;
                var ypos : Float = y + p.y;
                
                var r : Float = rot + Utils.DegToRad(part.r);
                
                var go : GameObj = GameObjects.AddObj(xpos, ypos, 0);
                go.dobj = part_dobj;
                go.frame = part.frame;
                go.scale = scale;
                go.dir = r;
                goList.push(go);
            }
        }
        return goList;
    }
    
    public function RenderAt(bd : BitmapData, x : Float, y : Float, frame : Float, scale : Float, rot : Float, xflip : Bool = false, _vector : Bool = false)
    {
        if (GameVars.renderDebugMode == 2)
        {
            return;
        }
        
        if (frames == null)
        {
            return;
        }
        var f : AnimHierarchyFrame = frames[as3hx.Compat.parseInt(frame)];
        var _smooth : Bool = true;
        
        
        
        
        var needToTransform : Bool = false;
        if (rot != 0)
        {
            needToTransform = true;
        }
        
        
        
        var clip : Bool = false;
        if (dobj != null)
        {
            var w : Float = dobj.GetWidth(Std.int(frame)) * scale;
            var h : Float = dobj.GetHeight(Std.int(frame)) * scale;
            
            if (x > Defs.displayarea_w + w)
            {
                clip = true;
            }
            if (x < -w)
            {
                clip = true;
            }
            if (y > Defs.displayarea_h + h)
            {
                clip = true;
            }
            if (y < -h)
            {
                clip = true;
            }
        }
        else
        {
            if (x > Defs.displayarea_w + 100)
            {
                clip = true;
            }
            if (x < -100)
            {
                clip = true;
            }
            if (y > Defs.displayarea_h + 100)
            {
                clip = true;
            }
            if (y < -100)
            {
                clip = true;
            }
        }
        
        if (clip)
        {
            GameVars.numHierarchiesClipped++;
            return;
        }
        else
        {
            GameVars.numHierarchiesRendered++;
        }
        
        m.identity();
        m.rotate(rot);
        
        var offset : Float = 0;
        if (frame != as3hx.Compat.parseInt(frame))
        {
            offset = frame - Math.floor(frame);
        }
        
        
        offset = 0;
        
        var nextf : Int = as3hx.Compat.parseInt(frame + 1);
        if (nextf >= frames.length)
        {
            nextf = as3hx.Compat.parseInt(frame);
        }
        var f1 : AnimHierarchyFrame = frames[as3hx.Compat.parseInt(nextf)];
        
        for (pcount in 0...f.parts.length)
        {
            var part : AnimHierarchyFramePart = f.parts[pcount];
            var part1 : AnimHierarchyFramePart = f1.parts[pcount];
            if (part.visible)
            {
                var interpAmt : Float = offset;
                if (part.interpolate == false)
                {
                    interpAmt = 0;
                }
                
                var part_dobj : DisplayObj = GraphicObjects.GetDisplayObjByName(part.dobjName);
                
                p.x = (part.x * scale);
                p.y = (part.y * scale);
                
                p1.x = (part1.x * scale);
                p1.y = (part1.y * scale);
                
                p.x = Utils.ScaleTo(p.x, p1.x, 0, 1, interpAmt);
                p.y = Utils.ScaleTo(p.y, p1.y, 0, 1, interpAmt);
                
                if (needToTransform)
                {
                    p = m.transformPoint(p);
                }
                
                var xpos : Float = x + p.x;
                var ypos : Float = y + p.y;
                
                
                var r : Float = rot + Utils.DegToRad(part.r);
                var r1 : Float = rot + Utils.DegToRad(part1.r);
                r = Utils.ScaleTo(r, r1, 0, 1, interpAmt);
                
                if (xflip)
                {
                    xpos = (x) - p.x;
                }
                
                if (_vector)
                {
                    part_dobj.RenderAtRotScaled_Vector(part.frame, bd, xpos, ypos, scale * part.scale, r, part.colorTransform, true, xflip);
                }
                else if (xflip == false)
                {
                    part_dobj.RenderAtRotScaled(part.frame, bd, xpos, ypos, scale * part.scale, r, part.colorTransform, _smooth);
                }
                else
                {
                    part_dobj.RenderAtRotScaled_Xflip(part.frame, bd, xpos, ypos, scale * part.scale, r, part.colorTransform, _smooth);
                }
            }
        }
    }
    
    
    public function ForAllPartsMatchingGame(partName : String, fn : Function)
    {
        for (f in frames)
        {
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(f),parts) type: null */ in f.parts)
            {
                if (p.partName == partName)
                {
                    fn(p);
                }
            }
        }
    }
    
    
    public function Frame_ForAllPartsMatchingGame(partName : String, frame : Int, fn : Function)
    {
        var f : AnimHierarchyFrame = frames[frame];
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(f),parts) type: null */ in f.parts)
        {
            if (p.partName == partName)
            {
                fn(p);
            }
        }
    }
    
    public function Frame_SetPartRot(partName : String, frame : Int, _rot : Float) : Float
    {
        var f : AnimHierarchyFrame = frames[frame];
        var oldR : Float = 0;
        
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(f),parts) type: null */ in f.parts)
        {
            if (p.partName == partName)
            {
                oldR = p.r;
                p.r = _rot;
                return oldR;
            }
        }
        return oldR;
    }
    
    public function SetPartColourTransform(partName : String, _ct : ColorTransform)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.colorTransform = _ct;
                });
    }
    public function SetPartFrame(partName : String, frame : Int)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.frame = frame;
                });
    }
    public function SetPartDobjName(partName : String, dobjName : String)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.dobjName = dobjName;
                });
    }
    public function SetPartScale(partName : String, scale : Float)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.scale = scale;
                });
    }
    public function SetPartVisible(partName : String, visible : Bool)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.visible = visible;
                });
    }
    public function SetPartInterpolate(partName : String, interpolate : Bool)
    {
        ForAllPartsMatchingGame(partName, function(p : AnimHierarchyFramePart)
                {
                    p.interpolate = interpolate;
                });
    }
    
    
    
    
    public function Clone() : AnimHierarchy
    {
        var h : AnimHierarchy = new AnimHierarchy();
        h.dobj = dobj;
        h.frames = [];
        for (f in frames)
        {
            h.frames.push(f.Clone());
        }
        return h;
    }
    
    public function Init(_dobj : DisplayObj, origMC : MovieClip, parts : Array<Dynamic>, clips : Array<Dynamic>)
    {
        dobj = _dobj;
        frames = [];
        
        var mc : MovieClip = origMC;
        var totalFrames : Int = mc.totalFrames;
        mc.gotoAndStop(1);
        for (i in 1...totalFrames + 1)
        {
            var f : AnimHierarchyFrame = new AnimHierarchyFrame();
            
            var partIndex : Int = 0;
            for (partName in parts)
            {
                var arr : Array<Dynamic> = partName.split(".");
                
                var partMC : MovieClip = mc;
                var x : Float = 0;
                var y : Float = 0;
                var r : Float = 0;
                var sc : Float = 1;
                for (p in arr)
                {
                    if (partMC == null)
                    {
                    }
                    else
                    {
                        partMC = try cast(partMC.getChildByName(p), MovieClip) catch(e:Dynamic) null;
                        
                        if (partMC == null)
                        {
                            Utils.traceerror("Hierachy: missing part " + p);
                        }
                        else
                        {
                            partMC.gotoAndStop(1);
                            var pt : Point = new Point(partMC.x, partMC.y);
                            var m : Matrix = new Matrix();
                            m.identity();
                            m.rotate(Utils.DegToRad(r));
                            m.scale(sc, sc);
                            pt = m.transformPoint(pt);
                            
                            x += ((pt.x) * sc);
                            y += ((pt.y) * sc);
                            r += partMC.rotation;
                            sc *= partMC.scaleX;
                        }
                    }
                }
                
                var part : AnimHierarchyFramePart = new AnimHierarchyFramePart();
                part.x = x;
                part.y = y;
                part.r = r;
                part.scale = sc;
                part.dobjName = clips[partIndex];
                part.partName = parts[partIndex];
                
                
                
                
                partIndex++;
                f.parts.push(part);
            }
            
            mc.nextFrame();
            
            frames.push(f);
        }
    }
}



/*
1 upperArmRight:  3.85   -54.75     20.295761108398438
1 upperArmRight.tint:  0.8409286516890933   -53.63658032062146     20.295761108398438
1 upperArmRight.lines:  -0.8320342380648564   -56.852585927773696     20.295761108398438
1 lowerArmRight:  0.95   -47.4     32.07765197753906
1 upperLegRight:  1.05   -32.05     -4.541015625
1 upperLegRight.tint:  -1.3812897474915735   -28.600583212372193     -4.541015625
1 upperLegRight.lines:  -4.645772034463224   -30.595685924545418     -4.541015625
1 footRight:  2.4   -18.85     0
1 footRight.tint:  1.3499999999999999   -11.250000000000002     0
1 footRight.lines:  -0.8500000000000001   -17.900000000000002     0
1 head:  2.7   -58.5     -0.2920074462890625
1 upperLegLeft:  -1.35   -32     10.06378173828125
1 upperLegLeft.tint:  -4.567318393451336   -29.279474247951566     10.06378173828125
1 upperLegLeft.lines:  -7.21898091111872   -32.028822298445775     10.06378173828125
1 body:  0.15   -44.55     1.2866973876953125
1 body.tint:  -2.22500092925407   -52.2469910209205     1.2866973876953125
1 body.tint_stripes:  -0.717444816785865   -50.41462494456664     1.2866973876953125
1 body.tint_hoops:  -2.259183563557709   -48.500873300068875     1.2866973876953125
1 body.lines:  -6.871137298253385   -61.14403863113833     1.2866973876953125
1 footLeft:  -3.35   -18.75     23.302749633789063
1 footLeft.tint:  -7.305783617057461   -12.210195186016534     23.302749633789063
1 footLeft.lines:  -6.697965052653329   -19.161594589061377     23.302749633789063
1 upperArmLeft:  0.7   -55.3     -10.301773071289063
1 upperArmLeft.tint:  -1.3296896903086515   -52.80219415963267     -10.301773071289063
1 upperArmLeft.lines:  -4.4162954541925705   -54.72486194592682     -10.301773071289063
1 lowerArmLeft:  1.85   -44.05     -21.0396728515625

1 upperArmRight:  3.85   -54.75     20.295761108398438
1 upperArmRight.tint:  0.8409286516890933   -53.63658032062146     20.295761108398438
1 upperArmRight.lines:  -0.8320342380648564   -56.852585927773696     20.295761108398438
1 lowerArmRight:  0.95   -47.4     32.07765197753906
1 upperLegRight:  1.05   -32.05     -4.541015625
1 upperLegRight.tint:  -1.3812897474915735   -28.600583212372193     -4.541015625
1 upperLegRight.lines:  -4.645772034463224   -30.595685924545418     -4.541015625
1 footRight:  2.4   -18.85     0
1 footRight.tint:  1.3499999999999999   -11.250000000000002     0
1 footRight.lines:  -0.8500000000000001   -17.900000000000002     0
1 head:  2.7   -58.5     -0.2920074462890625
1 upperLegLeft:  -1.35   -32     10.06378173828125
1 upperLegLeft.tint:  -4.567318393451336   -29.279474247951566     10.06378173828125
1 upperLegLeft.lines:  -7.21898091111872   -32.028822298445775     10.06378173828125
1 body:  0.15   -44.55     1.2866973876953125
1 body.tint:  -2.22500092925407   -52.2469910209205     1.2866973876953125
1 body.tint_stripes:  -0.717444816785865   -50.41462494456664     1.2866973876953125
1 body.tint_hoops:  -2.259183563557709   -48.500873300068875     1.2866973876953125
1 body.lines:  -6.871137298253385   -61.14403863113833     1.2866973876953125
1 footLeft:  -3.35   -18.75     23.302749633789063
1 footLeft.tint:  -7.305783617057461   -12.210195186016534     23.302749633789063
1 footLeft.lines:  -6.697965052653329   -19.161594589061377     23.302749633789063
1 upperArmLeft:  0.7   -55.3     -10.301773071289063
1 upperArmLeft.tint:  -1.3296896903086515   -52.80219415963267     -10.301773071289063
1 upperArmLeft.lines:  -4.4162954541925705   -54.72486194592682     -10.301773071289063
1 lowerArmLeft:  1.85   -44.05     -21.0396728515625
*/
